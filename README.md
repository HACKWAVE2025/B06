# GameEco 🌿
**Small Clicks, Big Impact**

GameEco is an innovative eco-gamification mobile application that transforms environmental consciousness into engaging, interactive experiences. The app encourages sustainable living through gamified activities, task completion, and AI-powered verification systems.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-ffca28?style=for-the-badge&logo=firebase&logoColor=black)
![Node.js](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)
![Google AI](https://img.shields.io/badge/Google%20AI-4285F4?style=for-the-badge&logo=google&logoColor=white)

## 🌟 Features

### 🎮 **Dual Mode Experience**
- **Kid Mode (Under 15)**: Gamified learning experience with the EcoSort game
- **Next-Gen Mode (15+)**: Task-based environmental challenges with real-world impact

### 🎯 **Core Functionality**
- **🔐 Multi-Authentication System**: Google OAuth and Email/Password authentication
- **📱 Role-Based Dashboards**: Customized experiences for different user types
- **🎮 EcoSort Game**: Interactive drag-and-drop recycling game with scoring system
- **📋 Daily Environmental Tasks**: Real-world eco-friendly challenges
- **📸 AI-Powered Task Verification**: Smart photo verification using Google Gemini AI
- **⭐ Eco Points System**: Gamified reward system for completed activities
- **🎨 Interactive Onboarding**: Beautiful flashcard-style introduction screens

### 🎲 **EcoSort Game Features**
- Real-time gameplay with 60-second rounds
- Three sorting categories: Recycle, Organic, and Trash
- Streak-based scoring system
- Dynamic difficulty progression
- Coin rewards based on performance

### 📋 **Daily Tasks System**
- 6 Different eco-friendly activities:
  - Plastic waste collection
  - Sapling plantation
  - Avoiding single-use plastics
  - Using public transport/walking
  - Saving electricity
  - Educating friends about sustainability
- Camera integration for proof submission
- AI verification of task completion
- Real-time status tracking

## 🛠️ Tech Stack

### **Frontend (Mobile App)**
- **Framework**: Flutter (Dart)
- **State Management**: StatefulWidget with setState
- **UI Components**: Material Design 3
- **Navigation**: Flutter Navigation 2.0

### **Backend Services**
- **Authentication**: Firebase Auth with Google Sign-In
- **Database**: Cloud Firestore (NoSQL)
- **File Storage**: Cloudinary (Image hosting)
- **AI Service**: Google Gemini AI (Image verification)

### **Backend API Server**
- **Runtime**: Node.js with Express
- **AI Integration**: Google GenAI SDK
- **Image Processing**: Cloudinary API
- **Deployment**: Vercel

### **Key Dependencies**

#### Flutter Dependencies
```yaml
dependencies:
  firebase_core: ^3.4.0
  firebase_auth: ^5.3.1
  google_sign_in: ^6.2.1
  cloud_firestore: ^5.6.12
  camera: ^0.11.0+2
  permission_handler: ^11.3.1
  http: ^1.2.2
  cupertino_icons: ^1.0.8
```

#### Backend Dependencies
```json
{
  "@google/genai": "^1.28.0",
  "express": "^4.21.2",
  "dotenv": "^16.4.7",
  "firebase-admin": "^13.1.0",
  "mime": "^2.6.0",
  "node-fetch": "^3.3.2"
}
```

## 🏗️ Architecture

### **Mobile App Structure**
```
lib/
├── main.dart                 # Entry point & Firebase initialization
├── splash_screen.dart        # Loading screen with branding
├── flashcards_screen.dart   # Onboarding experience
├── auth_page.dart           # Mode selection (Kid/Next-Gen)
├── login_page.dart          # Authentication forms
├── dashboard.dart           # Role-based main interface
├── eco_sort_game.dart       # Interactive recycling game
├── daily_tasks.dart         # Environmental task list
├── task_detail_page.dart    # Task completion & verification
└── firebase_options.dart    # Firebase configuration
```

### **Backend API Structure**
```
ai_backend/
├── server.js                # Express server & Gemini AI integration
├── package.json            # Node.js dependencies
├── vercel.json             # Deployment configuration
└── api/
    └── gemini.js           # AI verification endpoints
```

## 🚀 Getting Started

### **Prerequisites**
- Flutter SDK (3.9.2+)
- Node.js (16+)
- Firebase project setup
- Google AI API key
- Cloudinary account

### **Installation**

1. **Clone the repository**
   ```bash
   git clone https://github.com/HACKWAVE2025/B06.git
   cd B06
   ```

2. **Flutter App Setup**
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons:main
   ```

3. **Firebase Configuration**
   - Add your `google-services.json` to `android/app/`
   - Update `firebase_options.dart` with your Firebase config

4. **Backend Setup**
   ```bash
   cd ai_backend
   npm install
   ```

5. **Environment Variables**
   Create `.env` in `ai_backend/`:
   ```env
   GEMINI_API_KEY=your_google_ai_api_key
   PORT=3000
   ```

6. **Run the Application**
   ```bash
   # Start backend server
   cd ai_backend && npm start
   
   # Run Flutter app
   flutter run
   ```

## 🎮 How It Works

### **User Journey**
1. **Splash Screen**: Brand introduction with logo and tagline
2. **Onboarding**: Interactive flashcards explaining app benefits
3. **Mode Selection**: Choose between Kid Mode or Next-Gen Mode
4. **Authentication**: Google OAuth or email/password registration
5. **Dashboard**: Personalized interface based on user role
6. **Activities**: 
   - **Kids**: Play EcoSort game to earn points
   - **Adults**: Complete daily environmental tasks
7. **Verification**: AI-powered photo verification for task completion
8. **Progress Tracking**: Real-time points and achievement system

### **AI Verification Process**
1. User captures photo of completed environmental task
2. Image uploaded to Cloudinary for hosting
3. Backend processes image with Google Gemini AI
4. AI analyzes photo against task requirements
5. Returns verification result (true/false)
6. Points awarded for successful verification
7. Task status updated in Firestore database

## 🎨 UI/UX Design

### **Color Palette**
- **Primary**: Deep Green (`#27463A`)
- **Secondary**: Ivory (`#EDE7E3`)
- **Accent**: Green Accent (`#66BB6A`)
- **Background**: Dark (`#121212`)
- **Success**: Light Green (`#22C55E`)
- **Warning**: Orange (`#F29D38`)

### **Design Philosophy**
- **Minimalist Interface**: Clean, intuitive navigation
- **Eco-Friendly Aesthetics**: Nature-inspired color schemes
- **Gamification Elements**: Points, streaks, and achievements
- **Responsive Design**: Optimized for various screen sizes
- **Accessibility**: High contrast and readable typography

## 🔐 Security Features

- **Firebase Authentication**: Secure user management
- **Image Duplicate Detection**: SHA-256 hashing prevents reuse
- **Input Validation**: Server-side request validation
- **CORS Protection**: Configured for production environments
- **API Rate Limiting**: Prevents abuse of AI verification endpoints

## 🌍 Environmental Impact

GameEco promotes real-world environmental actions through:
- **Waste Reduction**: Plastic collection and recycling education
- **Carbon Footprint**: Encouraging public transport usage
- **Energy Conservation**: Electricity saving challenges
- **Green Awareness**: Environmental education and community building
- **Sustainable Habits**: Long-term behavior modification through gamification

## 🙏 Acknowledgments

- **Google AI**: Gemini API for intelligent image verification
- **Firebase**: Backend-as-a-Service platform
- **Cloudinary**: Cloud-based image management
- **Flutter Community**: UI components and best practices
- **Environmental Organizations**: Inspiration for eco-friendly challenges

---