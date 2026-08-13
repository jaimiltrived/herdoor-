require('dotenv').config();
const app = require('./app');

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, () => {
  console.log(`=================================`);
  console.log(` Server running in ${process.env.NODE_ENV || 'development'} mode`);
  console.log(` Listening on port http://localhost:${PORT}`);
  console.log(` Health check: http://localhost:${PORT}/api/v1/health`);
  console.log(`=================================`);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  console.error(`Unhandled Rejection Error: ${err.message}`);
  server.close(() => process.exit(1));
});
