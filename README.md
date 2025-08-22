# Nexus – Collaborative Workspace and Task Management

Nexus is a **cross-platform Flutter application** designed as a comprehensive collaborative workspace and task management tool. It helps users manage personal tasks, collaborate in teams, and stay organized with powerful features like Kanban boards, notifications, and offline sync.

This project is built with **Flutter + Provider** for state management, and integrates with **Firebase** for authentication, cloud storage, and synchronization.

---

## Features

###  User Authentication & Profile Management
- Secure sign up and login with email & password (Firebase Auth).
- User profile creation and editing.
- Secure handling of user data.

###  Task & Goal Management
- Create, edit, and delete tasks.
- Tasks include: title, description, due date, priority, and assignee.
- Create long-term goals with associated tasks.
- Sort & filter tasks by:
    - Due date
    - Priority
    - Completion status
    - Assignee

###  Collaborative Features
- **Task comments** with timestamps and author info.
- **Team creation & management** for collaborative projects.
- **Task assignment** to team members.
- **Activity feed** showing updates (status changes, new comments, assignments).

### Kanban Board & List Views
- Drag-and-drop Kanban board (e.g., *To-Do → In Progress → Done → Blocked*).
- Toggle between Kanban board and traditional list view.

### Notifications & Reminders
- Local notifications for deadlines & reminders.
- Push notifications for collaborative updates (task assigned, new comments, approaching due dates).

### Offline-first with Sync
- Local database support using **Hive/Isar**.
- Robust sync with **Firebase Firestore** when online.
- Handles conflicts gracefully to ensure data integrity.

### File & Image Upload
- Developed Laravel API for task attachments (images/files) with preview support.

---

## 🛠 Tech Stack

- **Language:** Dart
- **Framework:** Flutter
- **State Management:** Provider
- **Backend (BaaS):** Firebase (Auth, Firestore, Storage, Cloud Messaging)
- **Local Database:** Hive / Isar
- **Notifications:** flutter_local_notifications + Firebase Cloud Messaging
- **Version Control:** Git + GitHub

---

## 📂 Project Setup

1. **Clone the repository**
   ```bash
   git clone 
   cd nexus
