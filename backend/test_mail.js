const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'mottaikhoanphu102@gmail.com',
    pass: 'anpsfjckbxmmawvj'
  }
});

transporter.sendMail({
  from: '"Phúc Long Tea & Coffee" <mottaikhoanphu102@gmail.com>',
  to: 'nubbieim982@gmail.com',
  subject: '[Phúc Long] Mã xác thực khôi phục mật khẩu (Test)',
  html: '<h2 style="color: #0C5A30;">Mã OTP của bạn là: 889911</h2><p>Mã có hiệu lực trong 5 phút.</p>'
}, (err, info) => {
  if (err) {
    console.error('❌ SMTP ERROR:', err);
  } else {
    console.log('✅ SUCCESS:', info.response);
  }
});
