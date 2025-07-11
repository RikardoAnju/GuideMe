const axios = require("axios");
const crypto = require("crypto");
const admin = require("firebase-admin");

// Initialize Firebase
let db = null;
let firebaseEnabled = false;

function initFirebase() {
  if (!admin.apps.length) {
    try {
      // Check if all required Firebase environment variables are present
      const requiredEnvVars = [
        'FIREBASE_PROJECT_ID',
        'FIREBASE_PRIVATE_KEY',
        'FIREBASE_CLIENT_EMAIL'
      ];
      
      const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
      
      if (missingVars.length > 0) {
        console.warn(`⚠️ Missing Firebase environment variables: ${missingVars.join(', ')}`);
        return;
      }

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
      console.log("✅ Firebase initialized successfully");
    } catch (error) {
      console.warn("⚠️ Firebase initialization failed:", error.message);
      firebaseEnabled = false;
    }
  } else {
    db = admin.firestore();
    firebaseEnabled = true;
  }
}

// Status mapping function
function mapTransactionStatus(midtransStatus) {
  const statusMapping = {
    'settlement': { status: 'success', isPaid: true, canNavigateHome: true },
    'capture': { status: 'success', isPaid: true, canNavigateHome: true },
    'pending': { status: 'pending', isPaid: false, canNavigateHome: false },
    'cancel': { status: 'cancelled', isPaid: false, canNavigateHome: false },
    'expire': { status: 'expired', isPaid: false, canNavigateHome: false },
    'deny': { status: 'failed', isPaid: false, canNavigateHome: false },
    'failure': { status: 'failed', isPaid: false, canNavigateHome: false },
    'default': { status: 'unknown', isPaid: false, canNavigateHome: false }
  };
  return statusMapping[midtransStatus] || statusMapping['default'];
}

// Check Midtrans status with better error handling
async function checkMidtransStatus(orderId) {
  try {
    const serverKey = process.env.MIDTRANS_SERVER_KEY;
    if (!serverKey) {
      throw new Error("MIDTRANS_SERVER_KEY environment variable is not set");
    }

    const encodedKey = Buffer.from(serverKey + ":").toString("base64");
    
    // Use production URL if not in sandbox mode
    const baseUrl = process.env.MIDTRANS_IS_PRODUCTION === 'true' 
      ? 'https://api.midtrans.com' 
      : 'https://api.sandbox.midtrans.com';
    
    const response = await axios.get(
      `${baseUrl}/v2/${orderId}/status`,
      {
        headers: {
          Authorization: `Basic ${encodedKey}`,
          "Content-Type": "application/json",
        },
        timeout: 10000, // 10 second timeout
      }
    );
    
    return response.data;
  } catch (error) {
    console.error("Error checking Midtrans status:", error.response?.data || error.message);
    throw error;
  }
}

// CORS headers
function setCorsHeaders(res) {
  const allowedOrigins = process.env.ALLOWED_ORIGINS 
    ? process.env.ALLOWED_ORIGINS.split(',') 
    : ['*'];
  
  res.setHeader('Access-Control-Allow-Origin', allowedOrigins[0]);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Max-Age', '86400');
}

// Validate required environment variables
function validateEnvironment() {
  const requiredVars = ['MIDTRANS_SERVER_KEY'];
  const missingVars = requiredVars.filter(varName => !process.env[varName]);
  
  if (missingVars.length > 0) {
    throw new Error(`Missing required environment variables: ${missingVars.join(', ')}`);
  }
}

// Main handler
export default async function handler(req, res) {
  try {
    setCorsHeaders(res);
    
    if (req.method === 'OPTIONS') {
      return res.status(200).end();
    }

    // Validate environment variables
    validateEnvironment();
    
    // Initialize Firebase
    initFirebase();

    const { method, url } = req;
    const path = url.split('?')[0];

    console.log(`📝 ${method} ${path} - ${new Date().toISOString()}`);

    // Root endpoint
    if (method === 'GET' && path === '/') {
      return res.json({
        message: "Payment Backend Server - Vercel Version",
        version: "1.0.0",
        firebase_enabled: firebaseEnabled,
        environment: process.env.NODE_ENV || 'development',
        endpoints: [
          "POST /reset - Send OTP email",
          "POST /generate-snap-token - Create payment",
          "POST /midtrans-webhook - Payment webhook",
          "GET /payment-finish - Payment redirect",
          "GET /payment-status/:orderId - Check status",
          "GET /health - Health check"
        ],
      });
    }

    // Health check
    if (method === 'GET' && path === '/health') {
      return res.json({
        status: "OK",
        firebase_enabled: firebaseEnabled,
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
      });
    }

    // Send OTP email
    if (method === 'POST' && path === '/reset') {
      const { from, to, subject, html } = req.body;

      if (!from || !to || !subject || !html) {
        return res.status(400).json({ 
          success: false,
          message: "Missing required fields: from, to, subject, html" 
        });
      }

      if (!process.env.MAILERSEND_API_KEY) {
        return res.status(500).json({ 
          success: false,
          message: "Email service not configured" 
        });
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
            timeout: 15000,
          }
        );

        return res.json({ 
          success: true,
          message: "Email sent successfully" 
        });
      } catch (error) {
        console.error("Email error:", error.response?.data || error.message);
        return res.status(500).json({ 
          success: false,
          message: "Failed to send email",
          error: error.response?.data?.message || error.message
        });
      }
    }

    // Generate payment token
    if (method === 'POST' && path === '/generate-snap-token') {
      const { order_id, gross_amount, customer_details, item_details, payment_type } = req.body;

      if (!order_id || !gross_amount || !customer_details || !item_details) {
        return res.status(400).json({ 
          success: false,
          message: "Missing required fields: order_id, gross_amount, customer_details, item_details" 
        });
      }

      // Validate order_id format
      if (!/^[a-zA-Z0-9_-]+$/.test(order_id)) {
        return res.status(400).json({ 
          success: false,
          message: "Invalid order_id format. Only alphanumeric characters, hyphens, and underscores are allowed." 
        });
      }

      const serverKey = process.env.MIDTRANS_SERVER_KEY;
      const encodedKey = Buffer.from(serverKey + ":").toString("base64");

      const transactionData = {
        transaction_details: { 
          order_id, 
          gross_amount: parseInt(gross_amount) 
        },
        customer_details: {
          first_name: customer_details.first_name || "Customer",
          email: customer_details.email || "",
          phone: customer_details.phone || "",
        },
        item_details: item_details.map(item => ({
          id: item.id,
          price: parseInt(item.price),
          quantity: parseInt(item.quantity),
          name: item.name,
        })),
        credit_card: { secure: true },
        callbacks: {
          finish: `${process.env.FRONTEND_URL || 'https://yourapp.com'}/payment-finish?order_id=${order_id}`,
        }
      };

      try {
        const baseUrl = process.env.MIDTRANS_IS_PRODUCTION === 'true' 
          ? 'https://app.midtrans.com' 
          : 'https://app.sandbox.midtrans.com';

        const response = await axios.post(
          `${baseUrl}/snap/v1/transactions`,
          transactionData,
          {
            headers: {
              "Content-Type": "application/json",
              Authorization: `Basic ${encodedKey}`,
            },
            timeout: 15000,
          }
        );

        // Save to Firebase with enhanced data structure
        if (firebaseEnabled) {
          try {
            const paymentData = {
              order_id,
              status: "pending",
              is_paid: false,
              gross_amount: parseInt(gross_amount),
              customer_details,
              item_details,
              payment_type: payment_type || 'general',
              snap_token: response.data.token,
              transaction_status: "pending",
              created_at: admin.firestore.FieldValue.serverTimestamp(),
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
              // Handle both event and destination payments
              ...(payment_type === 'event' && {
                userId: customer_details.userId,
                eventId: customer_details.eventId,
                eventName: customer_details.eventName,
                eventData: customer_details.eventData,
                userEmail: customer_details.email,
                userName: customer_details.first_name,
                quantity: item_details[0]?.quantity || 1,
                totalAmount: parseInt(gross_amount),
                isFree: parseInt(gross_amount) === 0
              }),
              ...(payment_type === 'destination' && {
                userId: customer_details.userId,
                destinasiId: customer_details.destinasiId,
                destinasiName: customer_details.destinasiName,
                destinasiData: customer_details.destinasiData,
                userEmail: customer_details.email,
                userName: customer_details.first_name,
                quantity: item_details[0]?.quantity || 1,
                totalAmount: parseInt(gross_amount),
                isFree: parseInt(gross_amount) === 0
              })
            };

            await db.collection("payments").add(paymentData);
            console.log(`💾 Payment record created for ${order_id} with status: pending`);
          } catch (firebaseError) {
            console.error("Firebase save error:", firebaseError.message);
            // Continue even if Firebase fails
          }
        }

        return res.json({
          success: true,
          snap_token: response.data.token,
          redirect_url: response.data.redirect_url,
          order_id
        });
      } catch (error) {
        console.error("Payment token error:", error.response?.data || error.message);
        return res.status(500).json({ 
          success: false,
          message: "Failed to generate payment token",
          error: error.response?.data?.error_messages || error.message
        });
      }
    }

    // Midtrans webhook
    if (method === 'POST' && path === '/midtrans-webhook') {
      const { order_id, status_code, gross_amount, signature_key, transaction_status } = req.body;

      if (!order_id || !status_code || !gross_amount || !signature_key) {
        return res.status(400).json({ 
          success: false,
          message: "Missing required webhook fields" 
        });
      }

      // Verify signature
      const serverKey = process.env.MIDTRANS_SERVER_KEY;
      const expectedSignature = crypto
        .createHash("sha512")
        .update(order_id + status_code + gross_amount + serverKey)
        .digest("hex");

      if (signature_key !== expectedSignature) {
        console.error(`❌ Invalid signature for order ${order_id}`);
        return res.status(401).json({ 
          success: false,
          message: "Invalid signature" 
        });
      }

      const statusInfo = mapTransactionStatus(transaction_status);
      console.log(`🔔 Webhook received for ${order_id}: ${transaction_status} -> ${statusInfo.status}`);

      // Update Firebase
      if (firebaseEnabled) {
        try {
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
          }
        } catch (firebaseError) {
          console.error("Firebase update error:", firebaseError.message);
        }
      }

      return res.json({ 
        success: true,
        message: "Webhook processed successfully", 
        order_id, 
        status: statusInfo.status 
      });
    }

    // Payment finish redirect
    if (method === 'GET' && path === '/payment-finish') {
      const { order_id, status_code, transaction_status } = req.query;
      
      if (!order_id) {
        return res.status(400).json({
          success: false,
          message: "Order ID is required",
          redirect: "error"
        });
      }

      console.log(`🔍 Payment finish called for order: ${order_id}`);

      // Check actual status from Midtrans
      let actualStatus = null;
      let midtransData = null;
      
      try {
        midtransData = await checkMidtransStatus(order_id);
        actualStatus = midtransData.transaction_status;
        console.log(`📡 Midtrans status check: ${actualStatus}`);
        
        // Update database
        if (firebaseEnabled) {
          try {
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
          } catch (firebaseError) {
            console.error("Firebase update error:", firebaseError.message);
          }
        }
      } catch (error) {
        console.error("❌ Error checking Midtrans status:", error.message);
        actualStatus = transaction_status;
      }

      const finalStatus = actualStatus || transaction_status || "unknown";
      const statusInfo = mapTransactionStatus(finalStatus);
      
      let message = "Payment status unknown";
      let redirect = "error";

      switch (statusInfo.status) {
        case "success":
          message = "Payment completed successfully";
          redirect = "success";
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

      return res.json({
        success: statusInfo.isPaid,
        message,
        order_id,
        status: statusInfo.status,
        is_paid: statusInfo.isPaid,
        can_navigate_home: statusInfo.canNavigateHome,
        transaction_status: finalStatus,
        redirect,
        ...(midtransData && {
          fraud_status: midtransData.fraud_status,
          payment_type: midtransData.payment_type,
          gross_amount: midtransData.gross_amount,
          transaction_time: midtransData.transaction_time
        })
      });
    }

    // Check payment status
    if (method === 'GET' && path.startsWith('/payment-status/')) {
      const orderId = path.split('/payment-status/')[1];
      
      if (!orderId) {
        return res.status(400).json({ 
          success: false,
          message: "Order ID is required" 
        });
      }

      console.log(`🔍 Checking payment status for order: ${orderId}`);

      // Check Midtrans directly
      let midtransData = null;
      try {
        midtransData = await checkMidtransStatus(orderId);
        console.log(`📡 Midtrans status for ${orderId}: ${midtransData.transaction_status}`);
      } catch (error) {
        console.log(`⚠️ Could not fetch from Midtrans for ${orderId}: ${error.message}`);
      }

      // Check Firebase
      let firebaseData = null;
      let firebaseUpdateSuccess = false;
      
      if (firebaseEnabled) {
        try {
          const snapshot = await db.collection("payments")
            .where("order_id", "==", orderId)
            .get();

          if (!snapshot.empty) {
            firebaseData = snapshot.docs[0].data();
            
            // Update Firebase with latest Midtrans data
            if (midtransData) {
              const statusInfo = mapTransactionStatus(midtransData.transaction_status);

              await snapshot.docs[0].ref.update({
                status: statusInfo.status,
                is_paid: statusInfo.isPaid,
                transaction_status: midtransData.transaction_status,
                updated_at: admin.firestore.FieldValue.serverTimestamp(),
              });

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
        } catch (firebaseError) {
          console.error("Firebase query error:", firebaseError.message);
        }
      }

      if (!firebaseData && !midtransData) {
        return res.status(404).json({ 
          success: false,
          message: "Payment not found",
          order_id: orderId
        });
      }

      const currentTransactionStatus = midtransData ? midtransData.transaction_status : firebaseData?.transaction_status;
      const statusInfo = mapTransactionStatus(currentTransactionStatus);

      let message = "Payment status unknown";
      switch (statusInfo.status) {
        case "success":
          message = "Payment successful!";
          break;
        case "pending":
          message = "Payment is pending";
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

      return res.json({
        success: true,
        order_id: orderId,
        status: statusInfo.status,
        is_paid: statusInfo.isPaid,
        can_navigate_home: statusInfo.canNavigateHome,
        transaction_status: currentTransactionStatus,
        message,
        firebase_update_success: firebaseUpdateSuccess,
        ...(midtransData && {
          fraud_status: midtransData.fraud_status,
          payment_type: midtransData.payment_type,
          gross_amount: midtransData.gross_amount,
          transaction_time: midtransData.transaction_time
        })
      });
    }

    // 404 for unmatched routes
    return res.status(404).json({ 
      success: false,
      message: "Endpoint not found",
      path: path,
      method: method
    });

  } catch (error) {
    console.error("❌ Handler error:", error);
    return res.status(500).json({ 
      success: false,
      message: "Internal server error",
      error: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
    });
  }
}