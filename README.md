# MessEase –  Mess Management System

A Flutter-based mobile application designed to simplify  mess operations through digital meal management, student services, billing, leave applications, and administrative controls.

## Overview

**MessEase** aims to replace manual hostel mess management processes with a centralized digital platform. It provides students with an easy way to manage their meals, view weekly menus, submit leave applications, and communicate complaints.

The application also provides administrators and wardens with tools to manage students, menus, meal records, billing, leave requests, and feedback.

## Objectives

- Digitize hostel and mess management operations.
- Simplify daily meal selection and tracking.
- Automate meal charge calculation and monthly billing.
- Improve communication between students and administration.
- Provide role-based access for students and administrators.
- Maintain synchronized data using Firebase services.

## Features

### Student Module

- Student registration and login.
- Username availability checking.
- Student dashboard.
- View weekly mess menus.
- Select or cancel meals before the cutoff time.
- View meal selection history.
- View meal charges and monthly bills.
- Submit leave applications.
- Track leave application status.
- Submit complaints and feedback.
- Track complaint resolution status.

### Admin / Warden Module

- Secure administrator login.
- Admin dashboard.
- Manage student records.
- Create and update weekly menus.
- Monitor student meal selections.
- Configure meal rates.
- Generate monthly bills.
- Review and approve or reject leave applications.
- Manage complaints and provide responses.

### General Features

- Firebase-based authentication.
- Role-based navigation and access.
- Cloud-based data management.
- Input validation and error handling.
- Responsive application interface.

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform application development |
| Dart | Application programming language |
| Firebase Authentication | User authentication |
| Cloud Firestore | Cloud database |
| Firebase Storage | Planned storage for complaint images |
| Material Design 3 | Application UI |

## Application Architecture

The application follows a modular structure that separates screens, services, models, and reusable widgets.

```text
MessEase/
│
├── android/
├── ios/
├── web/
├── lib/
│   ├── models/
│   │   └── user_model.dart
│   │
│   ├── screens/
│   │   ├── login_page.dart
│   │   ├── registration_page.dart
│   │   ├── auth_wrapper.dart
│   │   ├── student_dashboard.dart
│   │   └── admin_dashboard.dart
│   │
│   ├── services/
│   │   ├── auth_service.dart
│   │   └── user_service.dart
│   │
│   ├── utils/
│   │   └── validators.dart
│   │
│   ├── widgets/
│   │   ├── custom_text_field.dart
│   │   ├── google_sign_in_button.dart
│   │   └── password_strength_indicator.dart
│   │
│   ├── main.dart
│   └── firebase_options.dart
│
├── test/
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

*Note: The structure above describes the current and intended project organization. Update it as additional modules and files are implemented.*

## Firebase Database Structure

The initial Firestore data structure includes:

```text
Firestore Database
│
├── users/
│   └── {uid}/
│       ├── uid
│       ├── username
│       ├── email
│       ├── role
│       └── createdAt
│
└── usernames/
    └── {username}/
        ├── username
        └── uid
```

Additional collections will be introduced for menus, meal selections, bills, leave applications, and complaints.

## Role-Based Access

MessEase supports two application roles:

| Role | Access |
|---|---|
| Student | Student dashboard and student services |
| Admin/Warden | Administrative dashboard and management services |

New registrations receive the `student` role by default. Administrator accounts are provisioned separately through a trusted administrative process.

## Getting Started

### Prerequisites

Install the following before running the project:

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- Git
- A Firebase project

### 1. Clone the Repository

```bash
git clone https://github.com/itubayounas/MessEase.git
```

### 2. Navigate to the Project

```bash
cd MessEase
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Configure Firebase

Connect the Flutter application to your own Firebase project using FlutterFire CLI.

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Enable the required Firebase services:

- Firebase Authentication
- Cloud Firestore

Configure Firebase Storage when implementing complaint image uploads.

Make sure your Firebase security rules are configured before using real student or administrator accounts.

### 5. Run the Application

For Chrome:

```bash
flutter run -d chrome
```

For an available Android device:

```bash
flutter run
```


