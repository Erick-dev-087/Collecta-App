# Group Payments Mobile App Specification

## Project Overview

The **Group Payments** mobile application is a platform designed to help organizations manage and track collections, events, and member contributions. A core feature of the app is seamless integration with Safaricom's M-Pesa (Daraja API) to initiate STK Pushes directly to members' phones for event contributions, and automatically reconcile those payments.

## Tech Stack

- **Frontend / Mobile Framework**: Flutter (Dart)
- **Backend / Database**: Firebase (Cloud Firestore, Authentication, Storage, Functions) OR MongoDB (with a suitable Node.js/Dart backend)
- **Integrations**: Safaricom Daraja API (M-Pesa Express / STK Push)

---

## Core Data Entities (Database Schema Concept)

Regardless of whether Firebase or MongoDB is chosen, the data structure revolves around a multi-tenant-like setup where an **Organization** is the central entity.

### 1. Organizations

The top-level entity representing the group collecting funds.

- **Fields**: Name, slug, description, branding (logo URL, primary/secondary colors).
- **Payment Settings**: M-Pesa shortcodes, account numbers, and whether they are active or default.

### 2. Users (Admins/Managers)

The administrators who manage the organization's collections.

- **Fields**: Full name, email, phone, secure authentication data.
- **Relation**: Belongs to an Organization.

### 3. Members

The people who belong to the organization and are expected to contribute to events.

- **Fields**: Full name, phone number (used for M-Pesa), email, gender.
- **Relation**: Belongs to an Organization.

### 4. Events

Specific causes, activities, or collections created by an organization.

- **Fields**: Title, description, event date, default contribution amount, whether custom amounts are allowed, status (Draft, Active, Closed), event image URL.
- **Relation**: Belongs to an Organization.

### 5. Payments (Transactions)

Records of financial contributions made toward an event.

- **Fields**: Payer name, phone number, amount, payment status (Initiated, Completed, Failed), M-Pesa receipt number, checkout request ID (from Daraja), initiated/completed timestamps.
- **Relation**: Linked to an Event, and optionally linked to a Member.

---

## Key Features & App Workflows

### 1. Authentication & Onboarding

- **Admin Login/Signup**: Secure authentication for organization administrators.
- **Password Management**: Forgot password, reset, and change password flows.

### 2. Organization Management

- **Profile**: Setup organization details, colors, and upload logos (using Firebase Storage or similar).
- **Payment Destinations**: Manage M-Pesa shortcodes and paybill/till numbers for the organization.

### 3. Member Management

- **Directory**: View a list of all members in the organization.
- **CRUD Operations**: Add new members, edit details, or remove them.
- **Insights**: View top-contributing members and identify inactive members who haven't contributed recently.
- **Bulk Import**: Ability to parse a CSV file to add multiple members at once.

### 4. Events & Collections

- **Event Creation**: Admins can create events, set target amounts (or default expected amounts), and upload cover images.
- **Analytics & Tracking**: View total collections for an event, list of members who have paid, and members with pending/failed payments.

### 5. M-Pesa Daraja Integration (The Core Engine)

This is the most critical feature. The app needs to handle mobile money payments seamlessly.

- **Payment Initiation (STK Push)**: From the app, an admin (or a member via a shared link) can initiate a payment. The app requests the payer's phone number and amount, triggering an M-Pesa STK push on the user's phone.
- **Anonymous Payers**: If a phone number initiating a payment isn't in the Member directory, the system should automatically register them as a new Member.
- **Webhook / Callback Handling**: Since Daraja callbacks are server-to-server, if Firebase is used, **Firebase Cloud Functions** (or a similar cloud worker) must be set up to listen to Safaricom's webhook, parse the `CheckoutRequestID`, and update the corresponding Payment document to `Completed` or `Failed` in real-time.

---

## Implementation Goals for the Flutter Agent

1. **Design & UI/UX**: Create a modern, responsive mobile interface using Flutter. Utilize the organization's primary/secondary colors for a branded experience.
2. **State Management**: Use robust state management (e.g., Provider, Riverpod, or BLoC) to handle asynchronous operations like fetching members, events, and payment statuses.
3. **Database Setup**: Design the NoSQL schema (Firebase/MongoDB) to efficiently query "Payments by Event" and "Payments by Member" without excessive reads.
4. **Cloud Functions**: Implement the Daraja webhook listener securely to ensure no payment callbacks are dropped or spoofed.
