# Talkify Backend

A comprehensive Node.js backend for Talkify calling applications with Socket.IO, Firebase integration, and JWT authentication.

## 🚀 Features

- **JWT Authentication** - Secure token-based authentication
- **Firebase Integration** - OTP verification using Firebase Admin SDK
- **Socket.IO** - Real-time call signaling and communication
- **FCM Notifications** - Push notifications for incoming calls
- **MongoDB** - User and call data storage
- **Rate Limiting** - API protection against abuse
- **Modular Architecture** - Clean, maintainable code structure

## 📁 Project Structure

```
backend/
├── controllers/
│   ├── authController.js         # Authentication logic
│   ├── userController.js         # User management
│   └── callController.js         # Call signaling logic
├── middleware/
│   └── authMiddleware.js         # JWT verification middleware
├── models/
│   ├── User.js                   # User schema
│   └── Call.js                   # Call metadata schema
├── routes/
│   ├── authRoutes.js             # Authentication routes
│   ├── userRoutes.js             # User routes
│   └── callRoutes.js             # Call routes
├── services/
│   ├── firebaseAdminService.js   # Firebase Admin SDK service
│   └── fcmService.js             # FCM notification service
├── socket/
│   └── callSocket.js             # Socket.IO call signaling
├── utils/
│   └── jwtUtils.js               # JWT token utilities
├── config/
│   └── db.js                     # Database configuration
├── app.js                        # Express app setup
├── server.js                     # Server initialization
└── package.json                  # Dependencies
```

## 🛠️ Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Environment Setup**
   ```bash
   cp .env.example .env
   ```
   
   Update `.env` with your configuration:
   ```env
   # Server Configuration
   PORT=3000
   NODE_ENV=development
   
   # Database
   MONGODB_URI=mongodb://localhost:27017/talkify-app
   
   # JWT
   JWT_SECRET=your-super-secret-jwt-key
   JWT_REFRESH_SECRET=your-super-secret-refresh-key
   
   # Firebase
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
   FIREBASE_CLIENT_EMAIL=your-client-email
   ```

4. **Start the server**
   ```bash
   # Development
   npm run dev
   
   # Production
   npm start
   ```

## 📡 API Endpoints

### Authentication
- `POST /api/auth/login` - Login with Firebase OTP
- `POST /api/auth/refresh` - Refresh JWT token
- `POST /api/auth/logout` - Logout user
- `GET /api/auth/verify` - Verify JWT token

### Users
- `GET /api/users` - Get user list
- `GET /api/users/profile` - Get current user profile
- `PUT /api/users/profile` - Update user profile
- `PUT /api/users/fcm-token` - Update FCM token
- `PUT /api/users/status` - Update online status
- `GET /api/users/:userId` - Get user by ID

### Calls
- `POST /api/calls/initiate` - Initiate a call
- `POST /api/calls/end` - End a call
- `GET /api/calls/history` - Get call history
- `GET /api/calls/:callId` - Get call details
- `PUT /api/calls/:callId/status` - Update call status

## 🔌 Socket.IO Events

### Client to Server
- `call-user` - Initiate a call
- `answer-call` - Answer incoming call
- `ice-candidate` - Send ICE candidate
- `end-call` - End current call
- `reject-call` - Reject incoming call
- `user-typing` - Typing indicator

### Server to Client
- `connected` - Connection established
- `incoming-call` - Incoming call notification
- `call-initiated` - Call initiation confirmed
- `call-answered` - Call answered by callee
- `call-ended` - Call ended notification
- `call-rejected` - Call rejected notification
- `ice-candidate` - ICE candidate received
- `user-typing` - Typing indicator

## 🔐 Authentication Flow

1. **Login**: Frontend sends Firebase ID token + FCM token
2. **Verification**: Backend verifies token with Firebase Admin SDK
3. **JWT Generation**: Backend creates JWT access + refresh tokens
4. **Storage**: User data and FCM token stored in MongoDB
5. **Authorization**: All subsequent requests require JWT token

## 📱 Call Signaling Flow

1. **Call Initiation**: Caller sends `call-user` event with offer
2. **Notification**: Callee receives `incoming-call` event + push notification
3. **Answer**: Callee sends `answer-call` event with answer
4. **ICE Exchange**: Both parties exchange ICE candidates
5. **Call End**: Either party sends `end-call` event

## 🔧 Configuration

### Environment Variables
- `PORT` - Server port (default: 3000)
- `MONGODB_URI` - MongoDB connection string
- `JWT_SECRET` - JWT signing secret
- `FIREBASE_PROJECT_ID` - Firebase project ID
- `FIREBASE_PRIVATE_KEY` - Firebase service account private key
- `FIREBASE_CLIENT_EMAIL` - Firebase service account email

### Database Models

#### User Schema
```javascript
{
  uid: String,           // Firebase UID
  name: String,          // User display name
  phone: String,         // Phone number
  fcmToken: String,      // FCM token for notifications
  isOnline: Boolean,     // Online status
  lastSeen: Date,        // Last seen timestamp
  profilePicture: String // Profile picture URL
}
```

#### Call Schema
```javascript
{
  callId: String,        // Unique call identifier
  caller: ObjectId,      // Caller user reference
  callee: ObjectId,      // Callee user reference
  status: String,        // Call status
  startTime: Date,       // Call start time
  endTime: Date,         // Call end time
  duration: Number,      // Call duration in seconds
  callType: String       // 'audio' or 'video'
}
```

## 🚀 Getting Started

1. Set up MongoDB database
2. Configure Firebase project and get service account credentials
3. Update environment variables
4. Install dependencies and start the server
5. Test API endpoints and Socket.IO connections

## 📝 Notes

- All API endpoints require JWT authentication except `/api/auth/login`
- Socket.IO connections require JWT token in handshake
- FCM tokens are automatically validated before storage
- Rate limiting is applied to prevent API abuse
- CORS is configured for cross-origin requests

## 🔍 Development

- Use `npm run dev` for development with auto-restart
- Check console logs for debugging information
- Monitor MongoDB connection status
- Test Socket.IO events using Socket.IO client tools

## 📄 License

This project is licensed under the ISC License.
