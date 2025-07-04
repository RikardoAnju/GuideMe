// server.js
require('dotenv').config(); // ⬅️ Tambahkan ini di paling atas

const express = require('express');
const cors = require('cors');
const midtransClient = require('midtrans-client');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Midtrans configuration (pakai dari .env)
const snap = new midtransClient.Snap({
    isProduction: false,
    serverKey: process.env.MIDTRANS_SERVER_KEY,
    clientKey: process.env.MIDTRANS_CLIENT_KEY
});

// Endpoint untuk generate snap token
app.post('/generate-snap-token', async (req, res) => {
    try {
        const { order_id, gross_amount, customer_details, item_details } = req.body;

        const parameter = {
            transaction_details: {
                order_id: order_id,
                gross_amount: gross_amount
            },
            customer_details: customer_details,
            item_details: item_details,
            enabled_payments: [
                'credit_card', 'bca_va', 'bni_va', 'bri_va', 'mandiri_va',
                'permata_va', 'other_va', 'gopay', 'shopeepay', 'dana',
                'ovo', 'linkaja', 'jenius', 'klik_bca', 'bca_klikbca',
                'bca_klikpay', 'cimb_clicks', 'danamon_online', 'uob_ezpay',
                'indomaret', 'alfamart', 'akulaku'
            ],
            callbacks: {
                finish: 'https://yourdomain.com/payment-finish'
            }
        };

        const transaction = await snap.createTransaction(parameter);

        res.json({
            snap_token: transaction.token,
            redirect_url: transaction.redirect_url
        });
    } catch (error) {
        console.error('Error generating snap token:', error);
        res.status(500).json({
            error: 'Failed to generate snap token',
            message: error.message
        });
    }
});

// Endpoint untuk handle notification dari Midtrans
app.post('/midtrans-notification', (req, res) => {
    try {
        const notification = req.body;
        console.log('Midtrans notification:', notification);

        snap.transaction.notification(notification)
            .then((statusResponse) => {
                const orderId = statusResponse.order_id;
                const transactionStatus = statusResponse.transaction_status;
                const fraudStatus = statusResponse.fraud_status;

                console.log(`Transaction notification received. Order ID: ${orderId}. Transaction status: ${transactionStatus}. Fraud status: ${fraudStatus}`);

                if (transactionStatus == 'capture') {
                    if (fraudStatus == 'challenge') {
                        console.log('Transaction captured with fraud status challenge');
                    } else if (fraudStatus == 'accept') {
                        console.log('Transaction captured and accepted');
                    }
                } else if (transactionStatus == 'settlement') {
                    console.log('Transaction settled');
                } else if (transactionStatus == 'cancel' ||
                          transactionStatus == 'deny' ||
                          transactionStatus == 'expire') {
                    console.log('Transaction cancelled/denied/expired');
                } else if (transactionStatus == 'pending') {
                    console.log('Transaction pending');
                }

                res.status(200).send('OK');
            })
            .catch((error) => {
                console.error('Error handling notification:', error);
                res.status(500).send('Internal Server Error');
            });
    } catch (error) {
        console.error('Error processing notification:', error);
        res.status(500).send('Internal Server Error');
    }
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'OK', message: 'Server is running' });
});

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});

module.exports = app;
