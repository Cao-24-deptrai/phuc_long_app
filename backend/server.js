const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Official Sender Configuration
const SENDER_EMAIL = process.env.EMAIL_USER || 'mottaikhoanphu102@gmail.com';
const SENDER_NAME = 'Phúc Long Tea & Coffee System';

// 1. Health Check Endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'Backend REST API Server for Phúc Long App is running',
    timestamp: new Date().toISOString(),
  });
});

// 2. REST API: Forgot Password OTP Email
app.post('/api/users/forgot-password', async (req, res) => {
  const { recipientEmail, otpCode } = req.body;

  if (!recipientEmail || !otpCode) {
    return res.status(400).json({
      success: false,
      message: 'Thiếu thông tin recipientEmail hoặc otpCode trong Request Body',
    });
  }

  // Strip all spaces from App Password for Gmail SMTP
  const rawPass = process.env.EMAIL_PASS || '';
  const appPassword = rawPass.replace(/\s+/g, '').trim();

  // If App Password is missing, log simulation & return success with notice
  if (!appPassword) {
    console.log('====================================================');
    console.log('✉️ REST API FORGOT PASSWORD OTP (SIMULATION LOG)');
    console.log(`Từ (From): ${SENDER_NAME} <${SENDER_EMAIL}>`);
    console.log(`Tới (To): ${recipientEmail}`);
    console.log(`Mã OTP 6 chữ số: ${otpCode}`);
    console.log('Lưu ý: Chưa điền EMAIL_PASS (App Password 16 ký tự) trong file backend/.env');
    console.log('====================================================');

    return res.json({
      success: true,
      simulated: true,
      message: 'REST API tiếp nhận thành công. (Mã OTP đã in ra Server Console do chưa điền EMAIL_PASS)',
      otpCode: otpCode,
    });
  }

  try {
    // Create Nodemailer Transporter for Gmail SMTP
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: SENDER_EMAIL,
        pass: appPassword,
      },
    });

    const nowString = new Date().toLocaleString('vi-VN');

    const mailOptions = {
      from: `"${SENDER_NAME}" <${SENDER_EMAIL}>`,
      to: recipientEmail,
      subject: '[Phúc Long] Mã xác thực khôi phục mật khẩu (REST API)',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-radius: 12px; overflow: hidden;">
          <div style="background-color: #0C5A30; padding: 24px; text-align: center;">
            <h1 style="color: #ffffff; margin: 0; font-size: 24px;">Phúc Long Tea & Coffee</h1>
          </div>
          <div style="padding: 24px; background-color: #ffffff;">
            <h3 style="color: #1E293B;">Yêu Cầu Khôi Phục Mật Khẩu (Backend REST API)</h3>
            <p style="color: #64748B; font-size: 14px;">Xin chào,</p>
            <p style="color: #64748B; font-size: 14px;">Mã OTP xác nhận đổi mật khẩu cho tài khoản <b>${recipientEmail}</b> của bạn là:</p>
            <div style="background-color: #F8FAFC; border: 1px dashed #CBD5E1; padding: 16px; text-align: center; margin: 20px 0; border-radius: 8px;">
              <span style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #0C5A30;">${otpCode}</span>
            </div>
            <p style="color: #64748B; font-size: 13px;">Mã này có hiệu lực trong vòng 5 phút. Vui lòng không chia sẻ mã này cho bất kỳ ai.</p>
            <p style="color: #94A3B8; font-size: 12px; margin-top: 24px;">Thời gian gửi qua REST API: ${nowString}</p>
          </div>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log(`✅ [REST API] Email OTP đã được gửi thành công đến ${recipientEmail} qua Gmail SMTP`);

    return res.json({
      success: true,
      simulated: false,
      message: 'Email OTP đã được phát trực tiếp vào hòm thư qua Backend REST API + SMTP!',
    });
  } catch (error) {
    console.error('⚠️ [REST API] Lỗi phát email SMTP:', error.message);
    return res.status(500).json({
      success: false,
      message: `Lỗi kết nối Gmail SMTP Server: ${error.message}`,
    });
  }
});

// 3. REST API: Password Reset Success Notification
app.post('/api/users/password-reset-success', async (req, res) => {
  const { recipientEmail } = req.body;
  if (!recipientEmail) {
    return res.status(400).json({ success: false, message: 'Thiếu recipientEmail' });
  }

  console.log(`✅ [REST API] Xác nhận đổi mật khẩu thành công cho ${recipientEmail}`);
  return res.json({ success: true, message: 'Đã lưu trạng thái đổi mật khẩu thành công' });
});

// Start Express Server
app.listen(PORT, () => {
  console.log(`====================================================`);
  console.log(`🚀 Phúc Long Backend REST API Server đang chạy tại:`);
  console.log(`👉 Local: http://localhost:${PORT}`);
  console.log(`👉 Health: http://localhost:${PORT}/api/health`);
  console.log(`👉 Forgot Password Endpoint: POST http://localhost:${PORT}/api/users/forgot-password`);
  console.log(`====================================================`);
});
