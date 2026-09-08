const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./config/swagger');
const apiRoutes = require('./routes/api');
const { notFoundHandler, errorHandler } = require('./middleware/errorHandler');

const app = express();

// Security and utility middleware
app.use(helmet({
  contentSecurityPolicy: false // Allow Swagger UI inline scripts & styles
}));
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',').map(s => s.trim())
  : ['http://localhost:3000', 'http://localhost:5173', 'http://localhost:5174', 'http://127.0.0.1:3000', 'http://127.0.0.1:5173', 'http://127.0.0.1:5174'];

app.use(cors({
  origin: (origin, callback) => {
    // Allow non-browser requests (mobile apps, Postman, curl)
    if (!origin) return callback(null, true);
    if (process.env.NODE_ENV !== 'production' || allowedOrigins.includes(origin)) {
      return callback(null, origin);
    }
    return callback(new Error('CORS policy: Not allowed by CORS'));
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'Origin'],
  credentials: true
}));
app.options('*', cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// HTTP Request Logger
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

// Raw OpenAPI JSON spec endpoint (for Postman / Insomnia / Swagger Editor import)
app.get('/api-docs.json', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.send(swaggerSpec);
});

// Swagger UI Documentation endpoints
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
app.use('/api/v1/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Base route
app.get('/', (req, res) => {
  res.json({
    name: 'HerDoor Node.js API Service',
    status: 'Running',
    swaggerDocs: '/api-docs',
    openApiJson: '/api-docs.json',
    endpoints: {
      api: '/api/v1',
      docs: '/api/v1/docs',
      health: '/api/v1/health'
    }
  });
});

// API Routes
app.use('/api/v1', apiRoutes);

// Error Handling Middleware
app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
