# Talkify

A real-time voice and video calling app built with Flutter and Node.js. Think of it as a lightweight VoIP app where you can make crystal-clear audio and video calls over the internet.

I built this to understand how WebRTC actually works under the hood, and to get hands-on experience with real-time communication protocols. Plus, I wanted something that could handle both audio and video without being bloated.

## Features

- Phone number authentication via Firebase OTP
- Audio and video calling using WebRTC
- Real-time call signaling with Socket.IO
- Push notifications for incoming calls (even when app is closed)
- Toggle camera on/off during video calls
- Mute/unmute microphone
- Online/offline status for users
- Call history tracking
- Works on both Android and iOS

## Tech Stack

**Frontend:**
- Flutter 3.3.0+ (Dart)
- GetX for state management
- flutter_webrtc for peer-to-peer connections
- socket_io_client for real-time signaling
- Firebase Auth & Firebase Cloud Messaging

**Backend:**
- Node.js with Express
- Socket.IO for WebRTC signaling
- MongoDB (Mongoose)
- JWT authentication
- Firebase Admin SDK

## Project Structure

```
Talkify/
│
├── talkify-backend/
│   ├── controllers/        # Auth, user, and call logic
│   ├── models/             # MongoDB schemas
│   ├── routes/             # API endpoints
│   ├── socket/             # Socket.IO signaling handlers
│   ├── services/           # Firebase & FCM services
│   ├── middleware/         # JWT verification
│   └── server.js           # Entry point
│
└── talkify-frontend/
    └── lib/
        ├── controllers/    # GetX state management
        ├── models/         # Data models
        ├── services/       # API, Socket, WebRTC, Firebase
        ├── views/          # UI screens
        └── widgets/        # Reusable components
```

## Installation & Setup

### Prerequisites

You'll need:
- Node.js (v16+)
- MongoDB (local or Atlas)
- Flutter SDK 3.3.0+
- A Firebase project with Auth and Cloud Messaging enabled

### Backend Setup

1. Navigate to the backend folder:
```bash
cd talkify-backend
npm install
```

2. Create a `.env` file:
```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/talkify-app
JWT_SECRET=your-secret-here
JWT_REFRESH_SECRET=your-refresh-secret
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
```

3. Get Firebase credentials from [Firebase Console](https://console.firebase.google.com) → Project Settings → Service Accounts → Generate New Private Key

4. Start the server:
```bash
npm run dev
```

The server runs on `http://localhost:3000`

### Frontend Setup

1. Go to the frontend folder:
```bash
cd talkify-frontend
flutter pub get
```

2. Set up Firebase for Flutter:
```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
```

3. Update the API endpoint in `lib/core/config.dart`:
```dart
class AppConfig {
  // For Android emulator:
  static const String baseUrl = 'http://10.0.2.2:3000';
  
  // For physical device, use your computer's IP:
  // static const String baseUrl = 'http://192.168.x.x:3000';
}
```

4. For Android, make sure `android/app/build.gradle` has:
```gradle
minSdkVersion 24  // WebRTC needs this
```

5. Add permissions to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

6. For iOS, add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for calls</string>
```

## Running the App

**Start the backend:**
```bash
cd talkify-backend
npm run dev
```

**Run the Flutter app:**
```bash
cd talkify-frontend
flutter run
```

Or build a release version:
```bash
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

### Testing

You'll need two devices (or one device + one emulator) to test calls:
1. Launch the app on both devices
2. Login with different phone numbers
3. Once logged in, you'll see the users list
4. Tap the call icon next to a user to initiate a call
5. Accept on the other device

## Screenshots

<table>
  <tr>
    <td><img src="screenshots/welcome.jpeg" width="200"/></td>
    <td><img src="screenshots/phone_input.jpeg" width="200"/></td>
    <td><img src="screenshots/otp.jpeg" width="200"/></td>
    <td><img src="screenshots/users.jpeg" width="200"/></td>
  </tr>
  <tr>
    <td align="center">Welcome Screen</td>
    <td align="center">Phone Input</td>
    <td align="center">OTP Verification</td>
    <td align="center">Users List</td>
  </tr>
  <tr>
    <td><img src="screenshots/audio_call.jpeg" width="200"/></td>
    <td><img src="screenshots/video_call.jpeg" width="200"/></td>
    
  </tr>
  <tr>
    <td align="center">Audio Call</td>
    <td align="center">Video Call</td>
   
  </tr>
</table>

> Note: Add your actual screenshots to a `screenshots/` folder

## API Endpoints

### Authentication
- `POST /api/auth/login` - Login with Firebase token
- `POST /api/auth/refresh` - Refresh JWT token
- `POST /api/auth/logout` - Logout user

### Users
- `GET /api/users` - Get all users
- `GET /api/users/profile` - Get current user
- `PUT /api/users/fcm-token` - Update FCM token
- `PUT /api/users/status` - Update online status

### Calls
- `POST /api/calls/initiate` - Start a call
- `POST /api/calls/end` - End a call
- `GET /api/calls/history` - Get call history

### Socket Events

**Client → Server:**
- `call-user` - Initiate call with offer
- `answer-call` - Answer with SDP answer
- `ice-candidate` - Send ICE candidate
- `reject-call` - Reject incoming call
- `end-call` - Hang up

**Server → Client:**
- `incoming-call` - Receive call notification
- `call-answered` - Other party answered
- `ice-candidate` - ICE candidate from peer
- `call-rejected` - Call was rejected
- `call-ended` - Call ended by peer




