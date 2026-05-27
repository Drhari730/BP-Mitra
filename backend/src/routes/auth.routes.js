// Authentication routes: register, login, refresh token.
const { Router } = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { query } = require('../config/database');
const { logger } = require('../utils/logger');
const rateLimit = require('express-rate-limit');

const router = Router();

// Tighter rate limit on auth endpoints to prevent brute force.
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: { error: 'Too many authentication attempts. Try again in 15 minutes.' },
});

router.use(authLimiter);

// ── Register ─────────────────────────────────────────────────
router.post('/register', async (req, res) => {
  const { full_name, email, password, date_of_birth, gender, weight_kg, height_cm } = req.body;

  if (!full_name || !email || !password) {
    return res.status(422).json({ error: 'full_name, email, password are required.' });
  }
  if (password.length < 8) {
    return res.status(422).json({ error: 'Password must be at least 8 characters.' });
  }

  try {
    const exists = await query('SELECT id FROM users WHERE email = $1', [email.toLowerCase()]);
    if (exists.rowCount) return res.status(409).json({ error: 'Email already registered.' });

    const hash = await bcrypt.hash(password, 12);
    const result = await query(
      `INSERT INTO users (id, full_name, email, password_hash, date_of_birth, gender, weight_kg, height_cm)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       RETURNING id, full_name, email, created_at`,
      [uuidv4(), full_name, email.toLowerCase(), hash, date_of_birth || null, gender || null, weight_kg || null, height_cm || null],
    );

    const user = result.rows[0];
    const token = generateToken(user);
    res.status(201).json({ user, token });
  } catch (err) {
    logger.error('register error', { error: err.message });
    res.status(500).json({ error: 'Registration failed.' });
  }
});

// ── Login ────────────────────────────────────────────────────
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(422).json({ error: 'email and password are required.' });
  }

  try {
    const result = await query(
      'SELECT id, full_name, email, password_hash FROM users WHERE email = $1',
      [email.toLowerCase()],
    );
    if (!result.rowCount) return res.status(401).json({ error: 'Invalid credentials.' });

    const user = result.rows[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) return res.status(401).json({ error: 'Invalid credentials.' });

    const token = generateToken(user);
    res.json({ user: { id: user.id, full_name: user.full_name, email: user.email }, token });
  } catch (err) {
    logger.error('login error', { error: err.message });
    res.status(500).json({ error: 'Login failed.' });
  }
});

function generateToken(user) {
  return jwt.sign(
    { sub: user.id, email: user.email },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' },
  );
}

module.exports = router;
