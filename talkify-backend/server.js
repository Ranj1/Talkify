require('dotenv').config();
const http = require('http');
const mongoose = require('mongoose');
const app = require('./app');
const socketService = require('./services/socketService');

// Import routes
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const callRoutes = require('./routes/callRoutes');

/**
 * Server Configuration
 * Sets up HTTP server, Socket.IO, and database connection
 */

const PORT = process.env.PORT || 3000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/talkify';

// Create HTTP server
const server = http.createServer(app);

// Setup routes (existing APIs remain unchanged)
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/calls', callRoutes);

// Initialize Socket.IO service for real-time features
socketService.initialize(server);

// Connect to MongoDB
mongoose.connect(MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => {
  console.log('✅ Connected to MongoDB');
})
.catch((error) => {
  console.error('❌ MongoDB connection error:', error);
  process.exit(1);
});

// Handle MongoDB connection events
mongoose.connection.on('connected', () => {
  console.log('📊 MongoDB connected successfully');
});

mongoose.connection.on('error', (error) => {
  console.error('📊 MongoDB connection error:', error);
});

mongoose.connection.on('disconnected', () => {
  console.log('📊 MongoDB disconnected');
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close(() => {
    console.log('Process terminated');
    mongoose.connection.close();
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  server.close(() => {
    console.log('Process terminated');
    mongoose.connection.close();
  });
});

// Start server
server.listen(PORT, () => {
  console.log('🚀 Talkify Backend Server Started');
  console.log(`📡 Server running on port ${PORT}`);
  console.log(`🌐 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`📊 MongoDB: ${MONGODB_URI}`);
  console.log(`🔌 Socket.IO: Enabled for real-time chat & WebRTC`);
  console.log(`👥 Online users: ${socketService.getOnlineUsersCount()}`);
  console.log('=====================================');
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

module.exports = { server, socketService };
