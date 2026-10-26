const jwt = require('jsonwebtoken');

const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: 'Token tidak ditemukan. Silakan login terlebih dahulu.' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    console.error('JWT Verify Error:', err.message, 'Token:', token.substring(0, 20) + '...', 'Secret:', process.env.JWT_SECRET ? 'exists' : 'missing');
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, message: 'Sesi telah habis. Silakan login kembali.', code: 'TOKEN_EXPIRED' });
    }
    return res.status(403).json({ success: false, message: 'Token tidak valid.' });
  }
};

const adminOnly = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ success: false, message: 'Akses ditolak. Hanya admin yang dapat mengakses endpoint ini.' });
  }
  next();
};

module.exports = { verifyToken, adminOnly };