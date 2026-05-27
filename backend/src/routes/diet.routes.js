// Module 2 – DASH Diet routes
const { Router } = require('express');
const { authenticate } = require('../middleware/auth.middleware');
const DietController = require('../controllers/diet.controller');

const router = Router();
router.use(authenticate);

router.post('/log', DietController.logMeal);
router.get('/log', DietController.getDayLog);
router.get('/sodium-summary', DietController.getDailySodiumSummary);
router.delete('/log/:id', DietController.deleteFoodEntry);

module.exports = router;
