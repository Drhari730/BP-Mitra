// Module 5 – AI Clinical Assistant routes
const { Router } = require('express');
const { authenticate } = require('../middleware/auth.middleware');
const AiController = require('../controllers/ai.controller');

const router = Router();
router.use(authenticate);

router.post('/evaluate', AiController.evaluate);
router.get('/history', AiController.getSessionHistory);

module.exports = router;
