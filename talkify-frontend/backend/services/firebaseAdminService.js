const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

/**
 * Firebase Admin Service
 * Handles Firebase Admin SDK operations for OTP verification
 */
class FirebaseAdminService {
  constructor() {
    this.app = null;
    this.auth = null;
    this.initialized = false;
  }

  /**
   * Initialize Firebase Admin SDK
   */
  async initialize() {
    try {
      if (this.initialized) {
        return;
      }
      //console.log("-------".serviceAccount.project_id);
      //console.log("🪙 Received ID token:", idToken);

      // Initialize Firebase Admin SDK
      if (!admin.apps.length) {
        // Load service account key from file
        const serviceAccount = require('./serviceAccountKey.json');
        
        this.app = admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: serviceAccount.project_id
        });
      } else {
        this.app = admin.app();
      }

      this.auth = admin.auth();
      this.initialized = true;
      
      console.log('Firebase Admin SDK initialized successfully');
    } catch (error) {
      console.error('Firebase Admin SDK initialization error:', error);
      throw error;
    }
  }

  /**
   * Verify Firebase ID token
   * @param {String} idToken - Firebase ID token
   * @returns {Object} Decoded token with user info
   */
  async verifyIdToken(idToken) {
    try {
      if (!this.initialized) {
        await this.initialize();
      }

      const decodedToken = await this.auth.verifyIdToken(idToken);
      return {
        uid: decodedToken.uid,
        phone: decodedToken.phone_number,
        email: decodedToken.email,
        emailVerified: decodedToken.email_verified,
        phoneVerified: decodedToken.phone_number_verified,
        name: decodedToken.name,
        picture: decodedToken.picture
      };
    } catch (error) {
      console.error('Firebase ID token verification error:', error);
      throw new Error('Invalid Firebase ID token');
    }
  }

  /**
   * Get user by UID
   * @param {String} uid - Firebase UID
   * @returns {Object} User record
   */
  async getUser(uid) {
    try {
      if (!this.initialized) {
        await this.initialize();
      }

      const userRecord = await this.auth.getUser(uid);
      return {
        uid: userRecord.uid,
        phone: userRecord.phoneNumber,
        email: userRecord.email,
        emailVerified: userRecord.emailVerified,
        phoneVerified: userRecord.phoneNumber ? true : false,
        name: userRecord.displayName,
        picture: userRecord.photoURL,
        disabled: userRecord.disabled,
        createdAt: userRecord.metadata.creationTime,
        lastSignIn: userRecord.metadata.lastSignInTime
      };
    } catch (error) {
      console.error('Firebase get user error:', error);
      throw new Error('User not found in Firebase');
    }
  }

  /**
   * Create custom token for testing
   * @param {String} uid - Firebase UID
   * @param {Object} additionalClaims - Additional custom claims
   * @returns {String} Custom token
   */
  async createCustomToken(uid, additionalClaims = {}) {
    try {
      if (!this.initialized) {
        await this.initialize();
      }

      return await this.auth.createCustomToken(uid, additionalClaims);
    } catch (error) {
      console.error('Firebase custom token creation error:', error);
      throw new Error('Failed to create custom token');
    }
  }

  /**
   * Set custom claims for user
   * @param {String} uid - Firebase UID
   * @param {Object} claims - Custom claims
   */
  async setCustomUserClaims(uid, claims) {
    try {
      if (!this.initialized) {
        await this.initialize();
      }

      await this.auth.setCustomUserClaims(uid, claims);
    } catch (error) {
      console.error('Firebase set custom claims error:', error);
      throw new Error('Failed to set custom claims');
    }
  }
}

// Export singleton instance
module.exports = new FirebaseAdminService();
