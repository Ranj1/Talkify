const mongoose = require('mongoose');

/**
 * Database Configuration
 * Handles MongoDB connection and configuration
 */
class DatabaseConfig {
  constructor() {
    this.isConnected = false;
  }

  /**
   * Connect to MongoDB
   * @param {String} uri - MongoDB connection URI
   * @returns {Promise} Connection promise
   */
  async connect(uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/talkify-app') {
    try {
      if (this.isConnected) {
        console.log('📊 MongoDB already connected');
        return;
      }

      const options = {
        useNewUrlParser: true,
        useUnifiedTopology: true,
        maxPoolSize: 10, // Maintain up to 10 socket connections
        serverSelectionTimeoutMS: 5000, // Keep trying to send operations for 5 seconds
        socketTimeoutMS: 45000, // Close sockets after 45 seconds of inactivity
        bufferMaxEntries: 0, // Disable mongoose buffering
        bufferCommands: false, // Disable mongoose buffering
      };

      await mongoose.connect(uri, options);
      this.isConnected = true;
      
      console.log('✅ MongoDB connected successfully');
      console.log(`📊 Database: ${uri.split('/').pop()}`);
      
      // Set up connection event listeners
      this.setupEventListeners();
      
    } catch (error) {
      console.error('❌ MongoDB connection error:', error);
      this.isConnected = false;
      throw error;
    }
  }

  /**
   * Setup MongoDB connection event listeners
   */
  setupEventListeners() {
    mongoose.connection.on('connected', () => {
      console.log('📊 Mongoose connected to MongoDB');
      this.isConnected = true;
    });

    mongoose.connection.on('error', (error) => {
      console.error('📊 Mongoose connection error:', error);
      this.isConnected = false;
    });

    mongoose.connection.on('disconnected', () => {
      console.log('📊 Mongoose disconnected from MongoDB');
      this.isConnected = false;
    });

    // Handle application termination
    process.on('SIGINT', async () => {
      await this.disconnect();
      process.exit(0);
    });

    process.on('SIGTERM', async () => {
      await this.disconnect();
      process.exit(0);
    });
  }

  /**
   * Disconnect from MongoDB
   * @returns {Promise} Disconnection promise
   */
  async disconnect() {
    try {
      if (this.isConnected) {
        await mongoose.connection.close();
        this.isConnected = false;
        console.log('📊 MongoDB disconnected');
      }
    } catch (error) {
      console.error('❌ MongoDB disconnection error:', error);
      throw error;
    }
  }

  /**
   * Get connection status
   * @returns {Boolean} Connection status
   */
  getConnectionStatus() {
    return this.isConnected && mongoose.connection.readyState === 1;
  }

  /**
   * Get connection info
   * @returns {Object} Connection information
   */
  getConnectionInfo() {
    return {
      isConnected: this.getConnectionStatus(),
      readyState: mongoose.connection.readyState,
      host: mongoose.connection.host,
      port: mongoose.connection.port,
      name: mongoose.connection.name
    };
  }
}

module.exports = new DatabaseConfig();
