# Staff Tracking System

![App Banner](https://via.placeholder.com/800x200?text=Staff+Tracking+App) <!-- Replace with actual banner -->

A real-time staff attendance and location tracking system with geofencing capabilities, built with Flutter and Firebase.

## ✨ Key Features

### 👨‍💼 Admin Panel
| Feature | Description |
|---------|-------------|
| 📍 Location Management | Create/edit office locations with OpenStreetMap integration |
| 👥 Staff Management | Register staff accounts and assign office locations |
| 🗺️ Live Tracking | View real-time staff locations during work hours |
| 📊 Analytics Dashboard | Daily work summaries and historical movement data |
| 🎭 Simulation Mode | Visualize staff movement patterns on interactive maps |

### 👷 Staff App
| Feature | Description |
|---------|-------------|
| 🕒 Geofenced Punch In/Out | Only allowed within 100m of assigned office |
| 📍 Background Location Tracking | Automatic GPS updates every 2 minutes |
| 📅 Session Management | Multiple punch in/out sessions per day |
| ⏱️ Work Summary | Daily breakdown of worked hours and locations |

## 🛠️ Technology Stack

**Frontend**  
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

**Backend**  
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Cloud Firestore](https://img.shields.io/badge/Cloud_Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)

**Maps & Location**  
![OpenStreetMap](https://img.shields.io/badge/OpenStreetMap-7EBC6F?style=for-the-badge&logo=openstreetmap&logoColor=white)
![Geolocator](https://img.shields.io/badge/Geolocation-000000?style=for-the-badge)

## 🚀 Installation

### Prerequisites
- Flutter SDK (v3.0.0 or higher)
- Dart SDK (v2.17.0 or higher)
- Firebase account
- Android Studio/Xcode (for emulator testing)

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-repo/staff-tracking-app.git
   cd staff-tracking-app
   
2. **Install dependencies**
   ```bash
   flutter pub get
  
3. **Configure Firebase:**

   + Use the Firebase Console to create a project.
   + Enable Authentication, Firestore, and Storage.
   + Download google-services.json for Android and place it in android/app/.
   + Download GoogleService-Info.plist for iOS and place it in ios/Runner/.
     
4. **Enable location permissions:**

   + Add the required permissions in AndroidManifest.xml and Info.plist:

     + ACCESS_FINE_LOCATION
     + ACCESS_BACKGROUND_LOCATION (Android 10+)
     + NSLocationAlwaysUsageDescription, etc.
5. **Run the app:**
   ```bash
     flutter run
## 🔒 Permissions Required
+ Location (foreground and background)
+ Internet
+ Local storage (for Hive)


## 🙌 Contributing
Contributions are welcome!
1. Fork this repository.
2. Create a new branch (git checkout -b feature-xyz).
3. Commit your changes (git commit -am 'Add feature xyz').
4. Push to the branch (git push origin feature-xyz).
5. Create a pull request.

## 📞 Contact
Developed by Ashwin K N

📧 Email: ashwinknprojects@gmail.com

🌐 Portfolio: https://github.com/ashwinkn2004/
