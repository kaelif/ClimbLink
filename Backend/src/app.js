// ============================================
// DATABASE MODE: Uncomment to load environment variables
// ============================================
// require('dotenv').config();

const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const stackRouter = require('./routes/stack');

const app = express();

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.use('/', stackRouter);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
});

module.exports = app;


