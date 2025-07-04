const express = require("express");
const axios = require("axios");
const cors = require("cors");
const crypto = require("crypto");
const admin = require("firebase-admin");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(express.json());

// Firebase setup
let db = null;
let firebaseEnabled = false;

function initFirebase() {
  try {
    if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY) {
      admin.initializeApp({
        credential: admin.credential.cert({
          type: "service_account",
          project_id: process.env.FIREBASE_PROJECT_ID,
          private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
          private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, "\n"),
          client_email: process.env.FIREBASE_CLIENT_EMAIL,
          client_id: process.env.FIREBASE_CLIENT_ID,
          auth_uri: "https://accounts.google.com/o/oauth2/auth",
          token_uri: "https://oauth2.googleapis.com/token",
          auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
          client_x509_cert_url: `https://www.googleapis.com/robot/v1/metadata/x509/${process.env.FIREBASE_CLIENT_EMAIL}`,
        }),
      });
      db = admin.firestore();
      firebaseEnabled = true;
      console.log("✅ Firebase initialized");
    }
  } catch (error) {
    console.warn("⚠️ Firebase not configured:", error.message);
  }
}


initFirebase();

// Consistent status mapping function
function mapTransactionStatus(midtransStatus) {
  const statusMapping = {
    // Success states
    'settlement': { status: 'success', isPaid: true, canNavigateHome: true },
    'capture': { status: 'success', isPaid: true, canNavigateHome: true },
    
    // Pending states
    'pending': { status: 'pending', isPaid: false, canNavigateHome: false },
    
    // Failed states
    'cancel': { status: 'cancelled', isPaid: false, canNavigateHome: false },
    'expire': { status: 'expired', isPaid: false, canNavigateHome: false },
    'deny': { status: 'failed', isPaid: false, canNavigateHome: false },
    'failure': { status: 'failed', isPaid: false, canNavigateHome: false },
    
    // Default
    'default': { status: 'unknown', isPaid: false, canNavigateHome: false }
  };

  return statusMapping[midtransStatus] || statusMapping['default'];
}

// Function to check payment status from Midtrans
async function checkMidtransStatus(orderId) {
  try {
    const serverKey = process.env.MIDTRANS_SERVER_KEY;
    const encodedKey = Buffer.from(serverKey + ":").toString("base64");
    
    const response = await axios.get(
      `https://api.sandbox.midtrans.com/v2/${orderId}/status`,
      {
        headers: {
          Authorization: `Basic ${encodedKey}`,
          "Content-Type": "application/json",
        },
      }
    );
    
    return response.data;
  } catch (error) {
    console.error("Error checking Midtrans status:", error.response?.data || error.message);
    throw error;
  }
}

// Email endpoint
app.post("/reset", async (req, res) => {
  const { from, to, subject, html } = req.body;

  if (!from || !to || !subject || !html) {
    return res.status(400).json({ message: "Missing required fields" });
  }

  try {
    await axios.post(
      "https://api.mailersend.com/v1/email",
      {
        from: { email: from },
        to: [{ email: to }],
        subject,
        html,
      },
      {
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${process.env.MAILERSEND_API_KEY}`,
        },
      }
    );

    res.json({ message: "Email sent successfully" });
  } catch (error) {
    console.error("Email error:", error.response?.data || error.message);
    res.status(500).json({ message: "Failed to send email" });
  }
});

// Generate payment token
app.post("/generate-snap-token", async (req, res) => {
  try {
    const { order_id, gross_amount, customer_details, item_details } = req.body;

    if (!order_id || !gross_amount || !customer_details || !item_details) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    const serverKey = process.env.MIDTRANS_SERVER_KEY;
    const encodedKey = Buffer.from(serverKey + ":").toString("base64");

    const transactionData = {
      transaction_details: { order_id, gross_amount },
      customer_details: {
        first_name: customer_details.first_name || "Customer",
        email: customer_details.email || "",
        phone: customer_details.phone || "",
      },
      item_details: item_details.map(item => ({
        id: item.id,
        price: item.price,
        quantity: item.quantity,
        name: item.name,
      })),
      credit_card: { secure: true },
    };

    const response = await axios.post(
      "https://app.sandbox.midtrans.com/snap/v1/transactions",
      transactionData,
      {
        headers: {
          "Content-Type": "application/json",
          Authorization: `Basic ${encodedKey}`,
        },
      }
    );

    // Save to Firebase if available with consistent status
    if (firebaseEnabled) {
      await db.collection("payments").add({
        order_id,
        status: "pending",
        is_paid: false,
        gross_amount,
        customer_details,
        item_details,
        snap_token: response.data.token,
        transaction_status: "pending",
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`💾 Payment record created for ${order_id} with status: pending`);
    }

    res.json({
      success: true,
      snap_token: response.data.token,
      //redirect_url: response.data.redirect_url,
    });
  } catch (error) {
    console.error("Payment token error:", error.response?.data || error.message);
    res.status(500).json({ message: "Failed to generate payment token" });
  }
});

// Midtrans webhook
app.post("/midtrans-webhook", async (req, res) => {
  try {
    const { order_id, status_code, gross_amount, signature_key, transaction_status } = req.body;

    // Verify signature
    const serverKey = process.env.MIDTRANS_SERVER_KEY;
    const expectedSignature = crypto
      .createHash("sha512")
      .update(order_id + status_code + gross_amount + serverKey)
      .digest("hex");

    if (signature_key !== expectedSignature) {
      console.error(`❌ Invalid signature for order ${order_id}`);
      return res.status(400).json({ message: "Invalid signature" });
    }

    // Use consistent status mapping
    const statusInfo = mapTransactionStatus(transaction_status);
    
    console.log(`🔔 Webhook received for ${order_id}: ${transaction_status} -> ${statusInfo.status}`);

    // Update Firebase if available
    if (firebaseEnabled) {
      const paymentsRef = db.collection("payments");
      const snapshot = await paymentsRef.where("order_id", "==", order_id).get();
      
      if (!snapshot.empty) {
        const doc = snapshot.docs[0];
        await doc.ref.update({
          status: statusInfo.status,
          is_paid: statusInfo.isPaid,
          transaction_status,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`💾 Webhook updated ${order_id}: ${statusInfo.status}, isPaid: ${statusInfo.isPaid}`);
      } else {
        console.warn(`⚠️ No Firebase record found for order ${order_id}`);
      }
    }

    res.json({ message: "Webhook processed", order_id, status: statusInfo.status });
  } catch (error) {
    console.error("Webhook error:", error);
    res.status(500).json({ message: "Webhook processing failed" });
  }
});

// Payment finish redirect - FIXED VERSION
app.get("/payment-finish", async (req, res) => {
  try {
    const { order_id, status_code, transaction_status } = req.query;
    
    if (!order_id) {
      return res.status(400).json({
        success: false,
        message: "Order ID is required",
        redirect: "error"
      });
    }

    console.log(`🔍 Payment finish called for order: ${order_id}`);
    console.log(`📊 Query params:`, req.query);

    // Check actual status from Midtrans
    let actualStatus = null;
    let midtransData = null;
    
    try {
      midtransData = await checkMidtransStatus(order_id);
      actualStatus = midtransData.transaction_status;
      console.log(`📡 Midtrans status check: ${actualStatus}`);
      
      // Update database with actual status using consistent mapping
      if (firebaseEnabled) {
        const paymentsRef = db.collection("payments");
        const snapshot = await paymentsRef.where("order_id", "==", order_id).get();
        
        if (!snapshot.empty) {
          const doc = snapshot.docs[0];
          const statusInfo = mapTransactionStatus(actualStatus);

          await doc.ref.update({
            status: statusInfo.status,
            is_paid: statusInfo.isPaid,
            transaction_status: actualStatus,
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          });
          
          console.log(`💾 Database updated: ${statusInfo.status}, isPaid: ${statusInfo.isPaid}`);
        }
      }
    } catch (error) {
      console.error("❌ Error checking Midtrans status:", error.message);
      // Fallback to query params if API call fails
      actualStatus = transaction_status;
    }

    // Determine final status using consistent mapping
    const finalStatus = actualStatus || transaction_status || "unknown";
    const statusInfo = mapTransactionStatus(finalStatus);
    
    let message = "Payment status unknown";
    let redirect = "error";

    switch (statusInfo.status) {
      case "success":
        message = "Payment completed successfully";
        redirect = "home";
        break;
      case "pending":
        message = "Payment is still pending";
        redirect = "pending";
        break;
      case "cancelled":
        message = "Payment was cancelled";
        redirect = "cancelled";
        break;
      case "expired":
        message = "Payment has expired";
        redirect = "expired";
        break;
      case "failed":
        message = "Payment failed";
        redirect = "failed";
        break;
      default:
        message = `Payment status: ${finalStatus}`;
        redirect = "error";
    }

    console.log(`✅ Final response: ${statusInfo.status.toUpperCase()} - ${message}`);
    
    // Return consistent JSON response
    res.json({
      success: statusInfo.isPaid,
      message,
      order_id,
      status: statusInfo.status,
      is_paid: statusInfo.isPaid,
      can_navigate_home: statusInfo.canNavigateHome,
      transaction_status: finalStatus,
      redirect,
      // Include additional Midtrans data if available
      ...(midtransData && {
        fraud_status: midtransData.fraud_status,
        payment_type: midtransData.payment_type,
        gross_amount: midtransData.gross_amount,
        transaction_time: midtransData.transaction_time
      })
    });

  } catch (error) {
    console.error("❌ Payment finish error:", error);
    res.status(500).json({
      success: false,
      message: "Internal server error",
      order_id: req.query.order_id || "unknown",
      status: "error",
      is_paid: false,
      can_navigate_home: false,
      redirect: "error"
    });
  }
});

// Check payment status - IMPROVED VERSION
app.get("/payment-status/:orderId", async (req, res) => {
  try {
    const { orderId } = req.params;
    console.log(`🔍 Checking payment status for order: ${orderId}`);

    // First check Midtrans directly
    let midtransData = null;
    try {
      midtransData = await checkMidtransStatus(orderId);
      console.log(`📡 Midtrans status for ${orderId}: ${midtransData.transaction_status}`);
    } catch (error) {
      console.log(`⚠️ Could not fetch from Midtrans for ${orderId}: ${error.message}`);
    }

    // Check Firebase if available
    let firebaseData = null;
    let firebaseUpdateSuccess = false;
    
    if (firebaseEnabled) {
      const snapshot = await db.collection("payments")
        .where("order_id", "==", orderId)
        .get();

      if (!snapshot.empty) {
        firebaseData = snapshot.docs[0].data();
        
        // Update Firebase with latest Midtrans data if available
        if (midtransData) {
          const statusInfo = mapTransactionStatus(midtransData.transaction_status);

          await snapshot.docs[0].ref.update({
            status: statusInfo.status,
            is_paid: statusInfo.isPaid,
            transaction_status: midtransData.transaction_status,
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Update local firebaseData to reflect changes
          firebaseData = { 
            ...firebaseData, 
            status: statusInfo.status, 
            is_paid: statusInfo.isPaid,
            transaction_status: midtransData.transaction_status
          };
          firebaseUpdateSuccess = true;
          
          console.log(`💾 Firebase updated for ${orderId}: ${statusInfo.status}, isPaid: ${statusInfo.isPaid}`);
        }
      }
    }

    if (!firebaseData && !midtransData) {
      return res.status(404).json({ 
        success: false,
        message: "Payment not found",
        order_id: orderId
      });
    }

    // Use Midtrans as source of truth, fallback to Firebase
    const currentTransactionStatus = midtransData ? midtransData.transaction_status : firebaseData?.transaction_status;
    const statusInfo = mapTransactionStatus(currentTransactionStatus);

    // Determine message based on status
    let message = "Payment status unknown";
    switch (statusInfo.status) {
      case "success":
        message = "Payment successful!";
        break;
      case "pending":
        message = "Payment status: pending";
        break;
      case "cancelled":
        message = "Payment was cancelled";
        break;
      case "expired":
        message = "Payment has expired";
        break;
      case "failed":
        message = "Payment failed";
        break;
      default:
        message = `Payment status: ${currentTransactionStatus}`;
    }

    // Return comprehensive response
    const responseData = {
      success: true,
      order_id: orderId,
      status: statusInfo.status,
      is_paid: statusInfo.isPaid,
      can_navigate_home: statusInfo.canNavigateHome,
      transaction_status: currentTransactionStatus,
      message,
      firebase_update_success: firebaseUpdateSuccess,
      debug_mapping: `${currentTransactionStatus} -> ${statusInfo.status}`,
      // Include Midtrans details if available
      ...(midtransData && {
        fraud_status: midtransData.fraud_status,
        payment_type: midtransData.payment_type,
        gross_amount: midtransData.gross_amount,
        transaction_time: midtransData.transaction_time
      })
    };

    console.log(`✅ Status check result for ${orderId}: ${statusInfo.status}, isPaid: ${statusInfo.isPaid}`);
    res.json(responseData);
    
  } catch (error) {
    console.error("❌ Status check error:", error);
    res.status(500).json({ 
      success: false,
      message: "Failed to check status",
      order_id: req.params.orderId,
      error: error.message
    });
  }
});

// Health check
app.get("/health", (req, res) => {
  res.json({
    status: "OK",
    firebase_enabled: firebaseEnabled,
    timestamp: new Date().toISOString(),
  });
});

// Root endpoint
app.get("/", (req, res) => {
  res.json({
    message: "Payment Backend Server - FIXED VERSION",
    firebase_enabled: firebaseEnabled,
    endpoints: [
      "POST /reset - Send email",
      "POST /generate-snap-token - Create payment",
      "POST /midtrans-webhook - Payment webhook",
      "GET /payment-finish - Payment redirect (fixed)",
      "GET /payment-status/:orderId - Check status (improved)",
      "GET /health - Health check"
    ],
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`🔥 Firebase: ${firebaseEnabled ? 'Enabled' : 'Disabled'}`);
});