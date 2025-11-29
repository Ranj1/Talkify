const jwt = require('jsonwebtoken');

/**
 * Generate JWT token for user
 * @param {Object} user - User object with uid
 * @param {Object} options - JWT options
 * @returns {String} JWT token
 */
const generateToken = (user, options = {}) => {
  const payload = {
    uid: user.uid,
    phone: user.phone,
    name: user.name
  };

  const defaultOptions = {
    expiresIn: process.env.JWT_EXPIRES_IN || '24h',
    issuer: process.env.JWT_ISSUER || 'talkify-app',
    audience: process.env.JWT_AUDIENCE || 'talkify-users'
  };

  const jwtOptions = { ...defaultOptions, ...options };

  return jwt.sign(payload, process.env.JWT_SECRET, jwtOptions);
};

/**
 * Generate refresh token
 * @param {Object} user - User object with uid
 * @returns {String} Refresh token
 */
const generateRefreshToken = (user) => {
  const payload = {
    uid: user.uid,
    type: 'refresh'
  };

  return jwt.sign(payload, process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
    issuer: process.env.JWT_ISSUER || 'talkify-app',
    audience: process.env.JWT_AUDIENCE || 'talkify-users'
  });
};

/**
 * Verify JWT token
 * @param {String} token - JWT token
 * @param {String} secret - JWT secret (optional)
 * @returns {Object} Decoded token payload
 */
const verifyToken = (token, secret = process.env.JWT_SECRET) => {
  return jwt.verify(token, secret);
};

/**
 * Decode JWT token without verification
 * @param {String} token - JWT token
 * @returns {Object} Decoded token payload
 */
const decodeToken = (token) => {
  return jwt.decode(token);
};

/**
 * Check if token is expired
 * @param {String} token - JWT token
 * @returns {Boolean} True if expired
 */
const isTokenExpired = (token) => {
  try {
    const decoded = jwt.decode(token);
    if (!decoded || !decoded.exp) return true;
    
    const currentTime = Math.floor(Date.now() / 1000);
    return decoded.exp < currentTime;
  } catch (error) {
    return true;
  }
};

/**
 * Generate token pair (access + refresh)
 * @param {Object} user - User object
 * @returns {Object} Token pair
 */
const generateTokenPair = (user) => {
  return {
    accessToken: generateToken(user),
    refreshToken: generateRefreshToken(user),
    expiresIn: process.env.JWT_EXPIRES_IN || '24h'
  };
};

module.exports = {
  generateToken,
  generateRefreshToken,
  verifyToken,
  decodeToken,
  isTokenExpired,
  generateTokenPair
};
