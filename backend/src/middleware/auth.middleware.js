// JWT authentication middleware – validates Bearer tokens on protected routes.
const jwt = require('jsonwebtoken');
const { logger } = require('../utils/logger');

const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or malformed Authorization header.' });
  }

  const token = authHeader.slice(7);
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = payload.sub;
    req.userEmail = payload.email;
    next();
  } catch (err) {
    logger.warn('Invalid JWT', { error: err.message });
    res.status(401).json({ error: 'Invalid or expired access token.' });
  }
};

module.exports = { authenticate };
