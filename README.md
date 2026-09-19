# 🎓 Smart Attendance Platform

> AI-ready, dual-app ecosystem for seamless student attendance tracking and management

A comprehensive platform combining a powerful Admin application for faculty and a personalized Student dashboard. Built to simplify class management, attendance marking, and academic term transitions with real-time Firebase syncing.

## ✨ Features

### 👨‍🏫 Admin App (Faculty Portal)
- **Class & Stream Management:** Dynamically create and manage academic streams (e.g., BCA, B.Tech) and semesters.
- **Student Onboarding:** Add students manually or utilize bulk CSV imports for entire cohorts.
- **Interactive Attendance:** Beautiful calendar grid UI to mark students as Present, Absent, or Holiday with a single tap.
- **Smart Promotions:** Seamlessly promote students to the next semester while preserving their historical attendance records.
- **Advanced Analytics:** Toggle between specific Months, Semester 1 (Jan-Jun), Semester 2 (Jul-Dec), or full Yearly rollups.
- **Role-based Access:** Super admin controls to manage teacher permissions.

### 🎓 Student App (Student Portal)
- **Secure Access:** Student login using Roll Number and Stream.
- **Real-time Dashboard:** Instantly view personal attendance statistics.
- **Dynamic Views:** Sleek UI dropdown to switch between Monthly calendar, Semester, and Yearly percentage breakdowns.
- **Visual Analytics:** Interactive Gauge Charts and color-coded status badges for quick visual feedback.

---

## 🚀 Quick Start

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed
- Dart SDK
- Firebase account ([firebase.google.com](https://firebase.google.com))

### 1. Clone and Install

```bash
# Clone the repository
git clone https://github.com/umang4zq/attendace_app_flutter.git

# Setup Admin App
cd my_attendance_app
flutter pub get

# Setup Student App (If separated)
cd ../my_attendance_student_app
flutter pub get
```

### 2. Environment Setup (Firebase)

**Required Configuration:**
1. Create a Firebase project.
2. Enable **Firestore Database** (Start in test mode or configure rules).
3. Download `google-services.json` and place it in `android/app/` for both apps.
4. Download `GoogleService-Info.plist` and place it in `ios/Runner/` for both apps.

### 3. Run Development Server

```bash
# Run Admin App
cd my_attendance_app
flutter run

# Run Student App
cd ../my_attendance_student_app
flutter run
```

---

## 📁 Project Structure

```text
attendace_app_flutter/
├── android/                   # Android native code
├── ios/                       # iOS native code
├── assets/                    # Static assets (images, icons, etc.)
├── lib/                       
│   ├── models/                # Data models (StudentModel, DateModel)
│   ├── providers/             # State management 
│   ├── screens/               # UI Screens
│   │   ├── dashboard/         # Main dashboard views
│   │   ├── attendance/        # Calendar and breakdown views 
│   │   └── auth/              # Login and registration
│   ├── services/              # External API & Firebase interactions
│   │   └── firestore_service.dart  
│   ├── theme/                 # App colors, tokens, text styles
│   └── widgets/               # Reusable UI components (GaugeChart)
├── pubspec.yaml               # Dependencies
└── README.md                  # Project documentation
```

---

## 🔧 Tech Stack

### Frontend / Mobile
- **Framework:** Flutter (Cross-platform)
- **Language:** Dart
- **UI Architecture:** Material Design 3
- **Animations:** `flutter_animate` package
- **Charts:** Custom Canvas / Gauge implementations

### Backend / Infrastructure
- **Database:** Firebase Cloud Firestore (NoSQL)
- **State Management:** Provider / Local `setState`
- **Auth:** Firebase Auth (Planned/Implemented)

---

## 🗄️ Database Architecture (Firestore)

The core attendance data relies on a deeply nested, highly scalable Firestore structure designed for easy academic rollups:

```text
streams (collection)
 └── [streamId] (document - e.g., "BCA")
      ├── name: "BCA"
      ├── createdAt: timestamp
      └── students (subcollection)
           └── [studentId] (document)
                ├── name: "John Doe"
                ├── rollno: "13"
                ├── stream: "BCA"
                ├── semester: "2"
                └── attendance (subcollection)
                     └── [yyyy-MM] (document - e.g., "2026-09")
                          └── days (subcollection)
                               └── [dd] (document - e.g., "15")
                                    ├── status: "Present" / "Absent" / "Holiday"
                                    └── timestamp: timestamp
```

### 📈 Attendance Calculation Logic
- **Month Mode:** Queries a specific `yyyy-MM` collection. Displays an interactive grid.
- **Semester/Year Mode:** Uses `fetchAggregatedAttendance` to batch query multiple months (e.g., `[1,2,3,4,5,6]` for Sem 1). Hides the interactive grid and instead displays a dynamic list breaking down the percentage per month, accompanied by a global Gauge Chart.

---

## 🤖 AI Assistant Context (For AI IDEs)

*If you are an AI assistant analyzing this codebase, here are your strict instructions and the essential context you need:*

**Your Role:** You are an expert Flutter Developer. Your goal is to help maintain, debug, and scale this platform while strictly following the defined architecture.

**Key Workflows to remember:** 
  - **Promotions:** Students are promoted by changing their `semester` property, but they remain in the same `streamId` document so historical attendance can be calculated seamlessly without migrating huge subcollections.
  - **UI Consistency:** Rely heavily on `PopupMenuButton` in AppBars instead of bulky horizontal scroll lists to save screen real estate. Use `flutter_animate` for micro-interactions.

---

## 🤝 Contributing

1. Create a feature branch (`git checkout -b feature/amazing-feature`)
2. Commit your changes (`git commit -m 'feat: add some amazing feature'`)
3. Push to the branch (`git push origin feature/amazing-feature`)
4. Open a Pull Request

---

## 📄 License

Proprietary - All rights reserved. 
Copyright © 2026.

---

**Made with ❤️ for modern academic institutions**
