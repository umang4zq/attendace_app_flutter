# Attendance Management System

> Comprehensive Flutter application suite for tracking and managing student attendance with Firebase backend.

A dual-app ecosystem consisting of an Admin Application and a Student Application, allowing institutions to seamlessly track, manage, and analyze attendance data across months, semesters, and academic years.

## 🤖 AI Assistant Context (For AI IDEs)

If you are an AI assistant analyzing this codebase, here is the essential context you need:
- **Software Type:** Mobile Application Suite (Admin & Student apps).
- **Framework:** Flutter (Dart).
- **Backend:** Firebase (Cloud Firestore).
- **Architecture Pattern:** Standard Flutter state management with dedicated Service classes (e.g., `FirestoreService`) for backend interactions.
- **Data Structure:** The core attendance data relies on a deeply nested Firestore structure: `streams -> [streamId] -> students -> [studentId] -> attendance -> [year-month] -> days -> [day]`.
- **Key Workflows:** 
  - **Promotions:** Students are promoted by changing their `semester` property, but they remain in the same `streamId` document so historical attendance can be calculated seamlessly.
  - **Aggregations:** The `fetchAggregatedAttendance` logic queries multiple months to create Semester (Sem 1: Jan-Jun, Sem 2: Jul-Dec) and Yearly rollups.

---

## ✨ Features

### 👨‍🏫 Admin App (`my_attendance_app`)
- **Stream Management:** Create, manage, and promote academic streams/classes.
- **Student Management:** Add students individually or bulk-import via CSV.
- **Attendance Tracking:** Interactive daily calendar grid to mark Present, Absent, or Holiday.
- **Advanced Analytics:** Toggle views to see attendance aggregated by:
  - Specific Month (Interactive Calendar)
  - Semester 1 (Jan-Jun Breakdown)
  - Semester 2 (Jul-Dec Breakdown)
  - Yearly (Full 12-month Breakdown)
- **Role-based Access:** Super admin features to manage teacher permissions.

### 🎓 Student App (`my_attendance_student_app`)
- **Secure Access:** Student login mechanism using Roll Number and Stream.
- **Personal Dashboard:** View personal attendance statistics in real-time.
- **Dynamic Views:** Sleek UI dropdown to switch between Monthly calendar, Semester, and Yearly percentage breakdowns.
- **Visual Analytics:** Interactive Gauge Charts and color-coded status badges.

---

## 🚀 Quick Start

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed (Stable channel recommended)
- Dart SDK
- Firebase account with a configured project

### 1. Clone and Install

```bash
# Clone the repository
git clone <your-repo-url>

# Setup Admin App
cd my_attendance_app
flutter pub get

# Setup Student App
cd ../my_attendance_student_app
flutter pub get
```

### 2. Firebase Environment Setup
Ensure you have Firebase configured for both Android and iOS:
1. Place your `google-services.json` in `android/app/`.
2. Place your `GoogleService-Info.plist` in `ios/Runner/`.
3. Ensure Firestore Rules are set up to allow authenticated reads/writes based on your security needs.

### 3. Run Development Server

```bash
# Run Admin App
cd my_attendance_app
flutter run

# Run Student App
cd my_attendance_student_app
flutter run
```

---

## 🗄️ Database Structure (Firestore)

Understanding the database hierarchy is critical for this application:

```
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

---

## 🔧 Tech Stack

### Frontend (Both Apps)
- **Framework:** Flutter
- **Language:** Dart
- **UI Components:** Material Design 3, `segmented_button`, Custom Toggle Bars.
- **Animations:** `flutter_animate`
- **Charts:** Custom Canvas/Gauge Charts

### Backend
- **Database:** Firebase Cloud Firestore
- **State Management:** Provider (or standard `setState` for localized UI state)

---

## 📁 Project Structure (General)

```
lib/
├── models/             # Data models (StudentModel, StreamModel, DateModel)
├── providers/          # State management (AdminProvider, etc.)
├── screens/            # UI Screens
│   ├── dashboard/      # Main dashboard views
│   ├── attendance/     # Calendar and breakdown views (e.g., MonthlyCalendarScreen)
│   └── auth/           # Login and registration
├── services/           # External API interactions
│   └── firestore_service.dart  # Core database logic
├── theme/              # App colors, text styles (AppColors.dart)
└── widgets/            # Reusable UI components (GaugeChart, StatBadge)
```

---

## 📈 Attendance Calculation Logic

- **Month Mode:** Queries a specific `yyyy-MM` collection. Displays an interactive grid.
- **Semester/Year Mode:** Uses `fetchAggregatedAttendance` (or `fetchAggregatedStudentAttendance`) to batch query multiple months (e.g., `[1,2,3,4,5,6]` for Sem 1). It hides the interactive grid and instead displays a `ListView` breaking down the percentage per month, accompanied by a global Gauge Chart.

---

## 🤝 Contributing

1. Create a feature branch.
2. Ensure UI changes match the modern, sleek aesthetic of the app (e.g., using `PopupMenuButton` in AppBars instead of bulky horizontal scroll lists).
3. Test thoroughly on both the Admin and Student apps, as core business logic (like Firestore queries) is often mirrored between them. 
4. Submit a Pull Request.

---

## 📄 License

Proprietary - All rights reserved.
