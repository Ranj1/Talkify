# 📱 Talkify - VoIP Calling Application

A full-stack real-time VoIP calling application built with Flutter and Node.js, featuring audio/video calls, Firebase authentication, and push notifications.

## 📖 Description

Talkify is a modern calling application that enables users to make high-quality audio and video calls over the internet. Built with Flutter for cross-platform mobile support and Node.js for a robust backend, it leverages WebRTC for peer-to-peer communication, Socket.IO for real-time signaling, and Firebase for authentication and push notifications.

## ✨ Features

### 🎯 Core Features
- **🔐 Firebase Authentication** - Secure OTP-based phone number authentication
- **📞 Audio Calls** - High-quality voice calls with echo cancellation and noise suppression
- **📹 Video Calls** - Full HD video calling with front/back camera support
- **🔔 Push Notifications** - Real-time FCM notifications for incoming calls
- **👥 User Management** - View online users and manage contacts
- **📊 Call History** - Track all incoming and outgoing calls
- **🌐 Real-time Signaling** - Socket.IO powered call signaling and WebRTC connection

### 🎨 Advanced Features
- **Toggle Video** - Turn camera on/off during video calls
- **Mute/Unmute** - Control microphone during calls
- **Call Status** - Real-time call status updates (ringing, connected, ended)
- **Online Status** - See which users are currently online
- **Secure Storage** - JWT tokens stored securely on device
- **Rate Limiting** - Backend API protection against abuse
- **Cross-Platform** - Works on Android and iOS

## 🛠️ Tech Stack

### Frontend (Mobile App)
- **Flutter** 3.3.0+ - Cross-platform mobile framework
- **Dart** 3.3.0+ - Programming language
- **GetX** - State management and dependency injection
- **WebRTC** - Peer-to-peer audio/video communication
- **Socket.IO Client** - Real-time bidirectional communication
- **Firebase Auth** - Phone number authentication
- **Firebase Messaging** - Push notifications
- **Flutter Local Notifications** - Local notification handling
- **Lottie** - Animated UI elements
- **Pinput** - OTP input field

### Backend (Server)
- **Node.js** - JavaScript runtime
- **Express.js** - Web application framework
- **Socket.IO** - Real-time communication
- **MongoDB** - NoSQL database with Mongoose ODM
- **Firebase Admin SDK** - Server-side Firebase integration
- **JWT** - Token-based authentication
- **Bcrypt** - Password hashing
- **Helmet** - Security middleware
- **CORS** - Cross-origin resource sharing

### Additional Services
- **Firebase Cloud Messaging (FCM)** - Push notifications
- **MongoDB Atlas** - Cloud database (recommended)
- **WebRTC** - Real-time communication protocol

## 📸 Screenshots

> Add your app screenshots here
```
┌─────────────┬─────────────┬─────────────┬─────────────┐
│  Welcome    │  OTP Login  │  Users List │  Video Call │
│   Screen    │   Screen    │   Screen    │   Screen    │
└─────────────┴─────────────┴─────────────┴─────────────┘
```

## 📁 Folder Structure

```
Talkify/
│
├── talkify-backend/                 # Node.js Backend
│   ├── config/
│   │   └── db.js                    # MongoDB configuration
│   ├── controllers/
│   │   ├── authController.js        # Authentication logic
│   │   ├── callController.js        # Call management logic
│   │   └── userController.js        # User management logic
│   ├── middleware/
│   │   └── authMiddleware.js        # JWT authentication middleware
│   ├── models/
│   │   ├── User.js                  # User schema
│   │   ├── Call.js                  # Call schema
│   │   └── CallLog.js               # Call history schema
│   ├── routes/
│   │   ├── authRoutes.js            # Auth endpoints
│   │   ├── callRoutes.js            # Call endpoints
│   │   └── userRoutes.js            # User endpoints
│   ├── services/
│   │   ├── fcmService.js            # FCM push notifications
│   │   ├── firebaseAdminService.js  # Firebase Admin SDK
│   │   └── socketService.js         # Socket.IO service
│   ├── socket/
│   │   ├── index.js                 # Socket.IO initialization
│   │   └── callSocket.js            # Call signaling logic
│   ├── utils/
│   │   ├── jwtUtils.js              # JWT utilities
│   │   └── socketUtils.js           # Socket helpers
│   ├── app.js                       # Express app configuration
│   ├── server.js                    # Server entry point
│   └── package.json                 # Backend dependencies
│
└── talkify-frontend/                # Flutter Mobile App
    ├── lib/
    │   ├── core/
    │   │   ├── config.dart          # App configuration
    │   │   ├── constants.dart       # App constants
    │   │   └── theme.dart           # App theme
    │   ├── getx_controllers/
    │   │   ├── call_controller.dart         # Call state management
    │   │   ├── notification_controller.dart # Notification handling
    │   │   ├── otp_controller.dart          # OTP verification
    │   │   └── user_controller.dart         # User state management
    │   ├── models/
    │   │   ├── call_model.dart      # Call data model
    │   │   └── user_model.dart      # User data model
    │   ├── services/
    │   │   ├── api_service.dart              # HTTP API client
    │   │   ├── firebase_auth_service.dart    # Firebase authentication
    │   │   ├── firebase_notification_service.dart # FCM handling
    │   │   ├── socket_service.dart           # Socket.IO client
    │   │   └── webrtc_service.dart           # WebRTC peer connection
    │   ├── views/
    │   │   ├── auth/
    │   │   │   ├── phone_input_page.dart     # Phone number input
    │   │   │   └── otp_verification_page.dart # OTP verification
    │   │   ├── calling/
    │   │   │   ├── call_page.dart            # Active call screen
    │   │   │   └── call_notification_page.dart # Incoming call
    │   │   ├── users_list/
    │   │   │   └── users_list_page.dart      # User list screen
    │   │   └── welcome/
    │   │       └── welcome_page.dart         # Welcome screen
    │   ├── widgets/
    │   │   ├── call_button.dart              # Call action buttons
    │   │   ├── incoming_call_notification.dart # Call notification UI
    │   │   ├── lottie_loader.dart            # Loading animations
    │   │   ├── responsive_container.dart     # Responsive widgets
    │   │   └── user_tile.dart                # User list item
    │   ├── firebase_options.dart     # Firebase configuration
    │   └── main.dart                 # App entry point
    ├── android/                      # Android specific files
    ├── ios/                          # iOS specific files
    ├── assets/                       # Images and animations
    └── pubspec.yaml                  # Flutter dependencies
```

## 🚀 Setup Instructions

### Prerequisites
- Node.js (v16 or higher)
- MongoDB (local or Atlas)
- Flutter SDK (3.3.0 or higher)
- Firebase Project
- Android Studio / Xcode
- Git

### Backend Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Talkify/talkify-backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment variables**
   
   Create a `.env` file in `talkify-backend/`:
   ```env
   # Server Configuration
   PORT=3000
   NODE_ENV=development
   
   # Database
   MONGODB_URI=mongodb://localhost:27017/talkify-app
   # Or use MongoDB Atlas:
   # MONGODB_URI=mongodb+srv://<username>:<password>@cluster.mongodb.net/talkify
   
   # JWT Secrets
   JWT_SECRET=your-super-secret-jwt-key-change-this
   JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-this
   
   # Firebase Admin SDK (from Firebase Console > Project Settings > Service Accounts)
   FIREBASE_PROJECT_ID=your-firebase-project-id
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour-Private-Key-Here\n-----END PRIVATE KEY-----\n"
   FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
   ```

4. **Set up Firebase Admin SDK**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Go to Project Settings > Service Accounts
   - Click "Generate New Private Key"
   - Save the JSON file as `services/serviceAccountKey.json` (optional, or use env vars)

5. **Start the server**
   ```bash
   # Development mode (with auto-restart)
   npm run dev
   
   # Production mode
   npm start
   ```

   Server will run on `http://localhost:3000`

### Frontend Setup

1. **Navigate to frontend directory**
   ```bash
   cd ../talkify-frontend
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase for Flutter**
   
   a. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   ```
   
   b. Login to Firebase:
   ```bash
   firebase login
   ```
   
   c. Configure Firebase:
   ```bash
   flutterfire configure
   ```
   Select your Firebase project and platforms (Android/iOS)

4. **Update API endpoint**
   
   Edit `lib/core/config.dart`:
   ```dart
   class AppConfig {
     // For Android Emulator
     static const String baseUrl = 'http://10.0.2.2:3000';
     
     // For iOS Simulator
     // static const String baseUrl = 'http://localhost:3000';
     
     // For Physical Device (use your computer's local IP)
     // static const String baseUrl = 'http://192.168.x.x:3000';
   }
   ```

5. **Configure Android**
   
   a. Update `android/app/build.gradle`:
   ```gradle
   android {
       defaultConfig {
           minSdkVersion 24  // Minimum for WebRTC
           targetSdkVersion 33
       }
   }
   ```
   
   b. Add permissions in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.CAMERA"/>
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
   ```

6. **Configure iOS**
   
   a. Update `ios/Podfile`:
   ```ruby
   platform :ios, '12.0'
   ```
   
   b. Add permissions in `ios/Runner/Info.plist`:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>This app needs camera access for video calls</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>This app needs microphone access for calls</string>
   ```
   
   c. Install pods:
   ```bash
   cd ios && pod install && cd ..
   ```

7. **Run the app**
   ```bash
   # Check connected devices
   flutter devices
   
   # Run on connected device
   flutter run
   
   # Run on specific device
   flutter run -d <device-id>
   
   # Build APK for Android
   flutter build apk --release
   
   # Build for iOS
   flutter build ios --release
   ```

## 📡 API Documentation

### Base URL
```
http://localhost:3000/api
```

### Authentication Endpoints

#### 1. Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "idToken": "firebase-id-token",
  "fcmToken": "device-fcm-token",
  "name": "User Name",
  "phone": "+1234567890"
}

Response: 200 OK
{
  "message": "Login successful",
  "accessToken": "jwt-access-token",
  "refreshToken": "jwt-refresh-token",
  "user": {
    "_id": "user-id",
    "uid": "firebase-uid",
    "name": "User Name",
    "phone": "+1234567890",
    "isOnline": true
  }
}
```

#### 2. Refresh Token
```http
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "jwt-refresh-token"
}

Response: 200 OK
{
  "accessToken": "new-jwt-access-token"
}
```

#### 3. Logout
```http
POST /api/auth/logout
Authorization: Bearer <access-token>

Response: 200 OK
{
  "message": "Logout successful"
}
```

### User Endpoints

#### 1. Get All Users
```http
GET /api/users
Authorization: Bearer <access-token>

Response: 200 OK
[
  {
    "_id": "user-id",
    "name": "User Name",
    "phone": "+1234567890",
    "isOnline": true,
    "lastSeen": "2024-01-01T00:00:00.000Z"
  }
]
```

#### 2. Get User Profile
```http
GET /api/users/profile
Authorization: Bearer <access-token>

Response: 200 OK
{
  "_id": "user-id",
  "name": "User Name",
  "phone": "+1234567890",
  "isOnline": true,
  "fcmToken": "device-token"
}
```

#### 3. Update FCM Token
```http
PUT /api/users/fcm-token
Authorization: Bearer <access-token>
Content-Type: application/json

{
  "fcmToken": "new-fcm-token"
}

Response: 200 OK
{
  "message": "FCM token updated successfully"
}
```

### Call Endpoints

#### 1. Initiate Call
```http
POST /api/calls/initiate
Authorization: Bearer <access-token>
Content-Type: application/json

{
  "calleeId": "recipient-user-id",
  "callType": "audio" // or "video"
}

Response: 200 OK
{
  "callId": "unique-call-id",
  "caller": "caller-user-id",
  "callee": "callee-user-id",
  "status": "initiated",
  "callType": "audio"
}
```

#### 2. Get Call History
```http
GET /api/calls/history
Authorization: Bearer <access-token>

Response: 200 OK
[
  {
    "callId": "call-id",
    "caller": { "name": "Caller Name", "phone": "+1234567890" },
    "callee": { "name": "Callee Name", "phone": "+0987654321" },
    "status": "completed",
    "callType": "video",
    "duration": 125,
    "startTime": "2024-01-01T00:00:00.000Z",
    "endTime": "2024-01-01T00:02:05.000Z"
  }
]
```

#### 3. End Call
```http
POST /api/calls/end
Authorization: Bearer <access-token>
Content-Type: application/json

{
  "callId": "call-id"
}

Response: 200 OK
{
  "message": "Call ended successfully",
  "duration": 125
}
```

### Socket.IO Events

#### Client → Server Events

| Event | Payload | Description |
|-------|---------|-------------|
| `call-user` | `{ to: userId, offer: RTCOffer, callType: 'audio'\|'video' }` | Initiate a call |
| `answer-call` | `{ to: userId, answer: RTCAnswer }` | Answer incoming call |
| `ice-candidate` | `{ to: userId, candidate: RTCIceCandidate }` | Send ICE candidate |
| `reject-call` | `{ to: userId, callId: string }` | Reject incoming call |
| `end-call` | `{ to: userId, callId: string }` | End active call |

#### Server → Client Events

| Event | Payload | Description |
|-------|---------|-------------|
| `incoming-call` | `{ from: userId, offer: RTCOffer, callId: string, callType: string, caller: User }` | Incoming call notification |
| `call-answered` | `{ answer: RTCAnswer }` | Call was answered |
| `ice-candidate` | `{ candidate: RTCIceCandidate }` | ICE candidate received |
| `call-rejected` | `{ message: string }` | Call was rejected |
| `call-ended` | `{ message: string }` | Call was ended |
| `user-online` | `{ userId: string }` | User came online |
| `user-offline` | `{ userId: string }` | User went offline |

## 🎮 How to Run the App

### Step 1: Start Backend Server

```bash
# Terminal 1
cd talkify-backend
npm run dev

# You should see:
# ✅ MongoDB connected successfully
# ✅ Server running on port 3000
# ✅ Socket.IO initialized
```

### Step 2: Run Flutter App

```bash
# Terminal 2
cd talkify-frontend
flutter run

# Or for specific device
flutter run -d <device-id>
```

### Step 3: Test the Application

#### On Device 1:
1. Launch the app
2. Enter phone number
3. Verify OTP (use Firebase Console to get test OTP)
4. View users list

#### On Device 2:
1. Launch the app
2. Login with different phone number
3. View users list

#### Make a Call:
1. **Device 1**: Tap audio/video call icon on Device 2's user
2. **Device 2**: Receive notification and accept call
3. **Both**: Enjoy audio/video call with toggle features
4. **Either**: Tap end call button to disconnect

### Testing Tips

- **Use physical devices** for best results (emulators may have issues with audio/video)
- **Same network**: Ensure both devices can reach the backend server
- **Permissions**: Grant camera and microphone permissions when prompted
- **Firewall**: Disable firewall if connections fail locally
- **Console logs**: Check backend console for connection/signaling logs

## 🔧 Configuration

### Backend Environment Variables
```env
PORT=3000                    # Server port
MONGODB_URI=                 # MongoDB connection string
JWT_SECRET=                  # JWT signing secret
JWT_REFRESH_SECRET=          # Refresh token secret
FIREBASE_PROJECT_ID=         # Firebase project ID
FIREBASE_PRIVATE_KEY=        # Firebase private key
FIREBASE_CLIENT_EMAIL=       # Firebase service account email
```

### Frontend Configuration
```dart
// lib/core/config.dart
class AppConfig {
  static const String baseUrl = 'http://10.0.2.2:3000';
  static const String socketUrl = 'http://10.0.2.2:3000';
}
```

## 🐛 Troubleshooting

### Common Issues

#### Backend won't start
- ✅ Check MongoDB is running: `mongod --version`
- ✅ Verify `.env` file exists and has correct values
- ✅ Check port 3000 is not already in use: `lsof -i :3000`

#### Flutter build fails
- ✅ Run `flutter clean && flutter pub get`
- ✅ Check Flutter version: `flutter --version`
- ✅ Ensure minimum SDK versions are met

#### Socket connection fails
- ✅ Verify backend URL in `lib/core/config.dart`
- ✅ Check backend server is running
- ✅ For physical devices, use local IP instead of localhost

#### Video/Audio not working
- ✅ Grant camera and microphone permissions
- ✅ Test on physical devices (not emulators)
- ✅ Check WebRTC compatibility
- ✅ Ensure call type is correctly set ('audio' or 'video')

#### Push notifications not received
- ✅ Verify FCM token is updated in backend
- ✅ Check Firebase Cloud Messaging is enabled
- ✅ Ensure `google-services.json` is in `android/app/`

## 📝 License

This project is licensed under the ISC License.

## 👨‍💻 Author

Talkify Development Team

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for authentication and messaging services
- Socket.IO for real-time communication
- WebRTC for peer-to-peer connections

---

**Happy Calling! 📞📹**

