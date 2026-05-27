// Module 3 – Vitals (BP Readings) routes
const { Router } = require('express');
const { authenticate } = require('../middleware/auth.middleware');
const VitalsController = require('../controllers/vitals.controller');

const router = Router();
router.use(authenticate);

router.post('/', VitalsController.createReading);
router.get('/', VitalsController.listReadings);
router.get('/trend', VitalsController.getTrend);
router.get('/latest', VitalsController.getLatestReading);

module.exports = router;
