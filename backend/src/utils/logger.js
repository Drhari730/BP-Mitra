// Winston structured logger with environment-aware transports.
const { createLogger, format, transports } = require('winston');

const { combine, timestamp, errors, json, colorize, simple } = format;

const isDev = process.env.NODE_ENV !== 'production';

const logger = createLogger({
  level: process.env.LOG_LEVEL || (isDev ? 'debug' : 'info'),
  format: combine(
    timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    errors({ stack: true }),
    json(),
  ),
  defaultMeta: { service: 'bp-mitra-api' },
  transports: [
    new transports.File({ filename: 'logs/error.log', level: 'error' }),
    new transports.File({ filename: 'logs/combined.log' }),
  ],
});

if (isDev) {
  logger.add(
    new transports.Console({
      format: combine(colorize(), simple()),
    }),
  );
}

module.exports = { logger };
