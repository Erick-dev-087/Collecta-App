# Group Payments API Documentation

This document provides a comprehensive overview of the Group Payments backend. This API facilitates the management of organizations, members, events, and M-Pesa Daraja payment integrations (STK Push).

## 🚀 Tech Stack

- **Framework**: [FastAPI](https://fastapi.tiangolo.com/) (Python)
- **Database**: PostgreSQL (with SQLAlchemy for Async ORM)
- **Migrations**: Alembic (typically used with SQLAlchemy, assumed for DB setup)
- **Authentication**: JWT (JSON Web Tokens) with OAuth2 Password Flow
- **Integrations**: Safaricom Daraja API (M-Pesa)

---

## 🏗️ Architecture & Structure

The codebase is organized into the following key directories within `src/`:

- `app.py`: The FastAPI application entry point, lifecycle events (DB table creation), CORS configuration, and router inclusions.
- `model.py`: SQLAlchemy ORM models defining the database schema.
- `routes/`: Contains the FastAPI routers (API endpoints).
- `service/`: Contains the business logic layer, separating it from the HTTP layer.
- `schemas/`: Pydantic models used for request validation and response serialization.
- `db/`: Database connection and session management.

---

## 🗄️ Database Models

The database is built around a multi-tenant-like structure focused on **Organizations**:

- **Organizations**: The top-level entity. Contains a name, slug, branding colors, and logo.
- **OrganizationPaymentDestination**: Stores Daraja shortcodes and account numbers linked to an organization.
- **User**: System administrators or managers belonging to an organization.
- **Members**: People who belong to an organization and can contribute to events.
- **Events**: Specific collections or causes created by an organization.
- **Payments**: Records of transactions initiated by members (or anonymous payers) for a specific event.
- **PaymentCallbacks**: Raw callback logs received from Safaricom Daraja to update payment statuses.

---

## 🔌 API Routes & Core Features

### 1. Authentication (`/api/v1/auth`)
The authentication system secures the admin and management routes.
- **Flow**: Uses `OAuth2PasswordRequestForm`. Users provide a username (email) and password to receive a JWT access token.
- **Endpoints**:
    - `POST /register`: Registers a new user.
    - `POST /login`: Authenticates a user and returns access/refresh tokens.
    - `POST /refresh`: Refreshes an expired access token.
    - `POST /logout`: Logs out the current user.
    - `POST /forgot-password` / `POST /reset-password` / `POST /change-password`: Password management flow.

### 2. Members Management (`/api/v1/members`)
Members belong to an organization and are the individuals contributing to events.
- **Endpoints**:
    - `POST /`: Create a new member.
    - `GET /org/{org_id}`: Retrieve a paginated list of members for an organization.
    - `GET /org/{org_id}/top-contributors`: Retrieves the top contributing members.
    - `GET /org/{org_id}/inactive`: Retrieves members who haven't contributed in a given timeframe.
    - `POST /org/{org_id}/bulk-import`: Accepts a CSV file upload to bulk import multiple members at once.

### 3. Image Uploads (`/api/v1/upload`)
The system allows uploading images for branding and event descriptions.
- **Endpoints**:
    - `POST /upload-org-logo/{org_id}`: Uploads a logo for an organization.
    - `POST /upload-event-image/{event_id}`: Uploads a single image for an event.
    - `POST /upload-bulk-event-images/{event_id}`: Uploads multiple images for an event.
    - `DELETE` routes for removing these images.

### 4. Payments & Daraja Integration (`/api/v1/payments`)
This is the core financial engine of the application, integrating with the Safaricom Daraja API for M-Pesa STK Pushes.

#### **How Daraja Works in the Backend:**
1. **Initiation (`POST /initiate`)**:
    - A user (or anonymous payer via a WhatsApp link) initiates a payment for a specific `event_id`.
    - If the user doesn't exist in the system, they are auto-created as a `Member` on the fly using their phone number.
    - The `PaymentService` talks to the `DarajaService` to trigger the STK Push.
2. **Daraja Service (`service/daraja_service.py`)**:
    - Fetches an OAuth access token from Safaricom (`_get_access_token`).
    - Generates the base64 encoded password using the shortcode, passkey, and timestamp.
    - Sends a `POST` request to Safaricom's `processrequest` endpoint to trigger the STK push on the user's phone.
    - Returns a `CheckoutRequestID` which is saved in the `Payments` database table to track the transaction.
3. **The Callback (`POST /callback`)**:
    - Safaricom sends an asynchronous webhook to this endpoint after the user completes (or cancels) the pin prompt.
    - The `PaymentService` parses this payload, looks up the `CheckoutRequestID` in the `Payments` table, and updates the payment status (e.g., `COMPLETED`, `FAILED`).
    - The raw webhook payload is saved in the `PaymentCallbacks` table for auditing and debugging.

#### **Payment Endpoints:**
- `POST /initiate`: Triggers the M-Pesa STK Push.
- `POST /callback`: The Daraja webhook listener.
- `GET /event/{event_id}/analytics`: Fetches total collections and metrics for an event.
- `GET /org/{org_id}/export`: Generates and downloads a CSV export of all payments for an organization.
- Status and history endpoints (e.g., `/admin/stuck`, `/{id}/status`) for admins to reconcile payments.

---

## 🔒 Security & Middleware
- **CORS**: Configured in `app.py` via `CORSMiddleware`. It supports local development ports (`3000`, `5173`, `8000`) and the Vercel production URL.
- **Role-Based Access Control**: The `dependencies.py` file includes a `require_role(UserRole.ADMIN)` dependency which is used across sensitive routes (like image uploads and payment exports) to ensure only authorized users can perform those actions.

---

## 🛠️ Next Steps & Best Practices (Observations)
- **Environment Variables**: Make sure your `.env` file contains all necessary Daraja credentials (`DARAJA_CONSUMER_KEY`, `DARAJA_CONSUMER_SECRET`, `DARAJA_PASSKEY`, etc.).
- **Background Tasks**: If Daraja callbacks fail to process immediately, having a cron job or Celery worker to reconcile stuck payments might be beneficial in the future.
