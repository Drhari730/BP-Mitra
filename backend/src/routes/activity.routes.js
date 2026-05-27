// Module 4 – Activity / Step Tracker routes
const { Router } = require('express');
const { authenticate } = require('../middleware/auth.middleware');
const ActivityController = require('../controllers/activity.controller');

const router = Router();
router.use(authenticate);

router.post('/sync', ActivityController.syncActivity);
router.get('/today', ActivityController.getTodayActivity);
router.get('/history', ActivityController.getActivityHistory);

module.exports = router;
