# MediMitra – Digital Health Record Management for Migrant Workers

## 1. Overview

**MediMitra** is a mobile‑first platform designed for migrant workers to manage their health records, receive AI‑powered insights, set medicine reminders, and securely share reports with doctors via time‑limited QR codes. The entire AI backend (summarization and conversational assistant) runs locally on the user's laptop using open‑source LLMs (Ollama + Llama 3), ensuring data privacy and no recurring API costs. The mobile app connects to the laptop over the local Wi‑Fi network, so no internet connection is required for the AI features.

- **Target Users:** Migrant workers in Kerala (and eventually across India).
- **Alignment:** SDG 3 (Good Health), SDG 8 (Decent Work), SDG 10 (Reduced Inequalities).

---

## 2. Core Features

| Feature | Description |
| :--- | :--- |
| **Report Collection** | Upload medical reports (PDF/Image) from gallery or camera. |
| **AI Summarizer** | Extracts structured info (patient, doctor, medicines, etc.) from uploaded reports. |
| **AI Assistant (RAG)** | Answers questions about user's health records and general medical knowledge using an offline LLM. |
| **Medicine Reminder** | Schedules local notifications with dosing instructions (e.g., "Take 200 mg with food"). |
| **QR Code Sharing** | Generates a time‑limited QR code that doctors can scan to view the user's summary and reports. |
| **Profile Management** | Collects and stores user profile (name, phone, allergies, etc.) with optional fields. |
| **Google Sign‑in** | Authenticate with Google; after login, user completes required profile fields. |
| **Future: Insurance Claim** | Submit claims directly from the app by selecting relevant reports. |

---

## 3. System Architecture

### 3.1 High‑Level Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Mobile App (Flutter)                     │
│  - Firebase Auth (Google Sign‑in, Phone)                    │
│  - Firestore (profile, reports, shares)                     │
│  - Firebase Storage (report images)                         │
│  - Hive (local offline storage)                             │
│  - Local notifications                                      │
└───────────────────────────┬─────────────────────────────────┘
                            │ HTTP (local network)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Laptop (Backend & AI)                     │
│  - FastAPI (Python)                                         │
│  - Ollama (Llama 3 8B Instruct, 4‑bit)                      │
│  - ChromaDB (vector database)                               │
│  - Tesseract OCR                                            │
│  - Firebase Admin SDK                                       │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Data Flow

1. **Sign‑in & Profile:** User signs in with Google (or phone). App checks if profile exists; if not, prompts to complete required fields (name, phone). Profile is stored in Firestore under `users/{uid}`.

2. **Report Upload:** Flutter app sends image to laptop's `/upload_report` endpoint → laptop runs Tesseract OCR → summarizer (Llama) extracts structured data → saves summary to Firestore and ChromaDB (local) → returns summary to app → app stores summary in Hive for offline access.

3. **AI Assistant:** App sends query to laptop's `/chat` endpoint → laptop retrieves relevant chunks from ChromaDB → prompts Llama → returns answer → app displays answer and optionally uses text‑to‑speech.

4. **Medicine Reminders:** App stores reminder in Firestore (for sync) and local Hive → schedules local notification using `flutter_local_notifications` with daily repeat.

5. **QR Code Sharing:** App calls laptop's `/generate_share` endpoint → laptop stores token in Firestore (`shares` collection) → returns URL → app generates QR code → doctor scans → web view validates token and displays summary.

---

## 4. Tech Stack

| Layer | Technology |
| :--- | :--- |
| **Mobile App** | Flutter (Dart) |
| **Backend (on laptop)** | FastAPI (Python), Firebase Admin SDK |
| **AI Backend** | Ollama (local) + Llama 3 8B Instruct (4‑bit quantized) |
| **OCR** | Tesseract (local) |
| **Vector DB** | ChromaDB (local, persistent) |
| **Embeddings** | intfloat/multilingual-e5-small |
| **Cloud Services** | Firebase (Auth, Firestore, Storage, Hosting) |
| **Local Notifications** | flutter_local_notifications + workmanager |
| **Local Storage** | Hive (offline reports & reminders) |

---

## 5. Security & Environment Setup

### 5.1 Environment Variables

MediMitra uses environment variables for secure credential management.

1. **Locate** the `backend/.env.example` file.
2. **Copy** it to `backend/.env`.
3. **Fill in** your `FIREBASE_CREDENTIALS_PATH` or `FIREBASE_SERVICE_ACCOUNT_JSON`.
4. **Add** your `GEMINI_API_KEY`.

> [!IMPORTANT]
> Never commit `.env` or `serviceAccountKey.json` to version control. They are explicitly excluded in `.gitignore`.

---

## 6. Detailed Implementation Steps

### 6.1 Laptop Setup (AI Backend)

1. **Install Ollama** and pull the model:
   ```bash
   curl -fsSL https://ollama.com/install.sh | sh
   ollama serve &
   ollama pull llama3:8b-instruct-q4_K_M
   ```

2. **Set up Python environment:**
   ```bash
   pip install fastapi uvicorn chromadb sentence-transformers pytesseract opencv-python firebase-admin
   ```

3. **Set up Firebase:**
   - Enable Firestore and Storage in test mode.
   - Download the service account key and place it as `serviceAccountKey.json` in the backend folder.
   - Set the storage bucket name in `firebase_config.py`.

4. **Create FastAPI app** with endpoints:
   - `/upload_report` – accept image, run Tesseract OCR, summarise with Llama, store in Firestore and ChromaDB.
   - `/chat` – accept query, retrieve relevant chunks, build prompt, call Ollama, return answer.
   - `/generate_share` and `/share/{token}` for QR sharing.
   - `/reports/{user_id}` to fetch all reports from Firestore.

5. **Run the server:**
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000
   ```

### 6.2 Firebase Setup

1. **Authentication** – Enable Google Sign‑in and Phone in the Firebase console.
2. **Firestore Collections** (created automatically on first write):
   - `users` – user profile (name, phone, weight, height, blood group, allergies, etc.)
   - `reports` – metadata and AI‑extracted summary
   - `medicines` – reminder details
   - `qrShares` – tokens and expiry
3. **Firebase Storage** – stores uploaded report images.

### 6.3 Flutter App Implementation

1. **Authentication** – Use `firebase_auth` and `google_sign_in`. After login, check profile existence in Firestore; if missing, navigate to Profile Setup screen.

2. **Profile Management:**
   - Required fields: Full name, Phone number
   - Optional fields: Weight, Height, Blood Group, Allergies, Address, Guardian Contact
   - Store under `users/{uid}`; allow editing later in Profile Screen.

3. **Local Database** – Use `hive` to store reports and medicines offline.

4. **Local Notifications** – `flutter_local_notifications` with `workmanager` for background scheduling. Use `zonedSchedule` with daily repeat.

5. **AI Assistant Chat** – Call laptop's `/chat` endpoint via local IP. Show typing indicator. Voice input via `speech_to_text`; voice output via `flutter_tts`.

6. **Report Upload** – Use `image_picker`, send to `/upload_report`. On response, store summary in Firestore and local Hive.

7. **QR Code Share** – Call `/generate_share`, render QR with `qr_flutter`. Share via WhatsApp/email.

### 6.4 Web View for QR Access

- Simple HTML/JS page hosted on Firebase Hosting.
- Reads token from URL query parameter, fetches from backend `/share/{token}`, validates expiry, and displays summary and report image.

---

## 7. Data Models (Firestore)

### `users`

| Field | Type | Description |
| :--- | :--- | :--- |
| `name` | string | Required – full name |
| `phone` | string | Required – mobile number |
| `weight` | number | Optional – in kg |
| `height` | number | Optional – in cm |
| `bloodGroup` | string | Optional |
| `allergies` | string | Optional |
| `email` | string | Auto‑filled from Google |
| `address` | string | Optional |
| `guardianContact` | string | Optional |

### `reports`

| Field | Type | Description |
| :--- | :--- | :--- |
| `userId` | string | Reference to user document |
| `imageUrl` | string | Public URL from Storage |
| `rawText` | string | OCR extracted text |
| `summary` | object | Structured summary (patient_name, report_date, diagnosis, medicines array, etc.) |
| `timestamp` | timestamp | Upload time |

### `medicines`

| Field | Type | Description |
| :--- | :--- | :--- |
| `userId` | string | Reference to user |
| `reportId` | string | Optional – reference to report |
| `name` | string | Medicine name |
| `dosage` | string | e.g., 200 mg |
| `dosingInstruction` | string | e.g., "with food" |
| `timings` | array | List of `{time: "09:00", taken: bool}` |
| `startDate` | timestamp | When to start |
| `endDate` | timestamp | Optional |
| `active` | bool | Still active |

### `qrShares`

| Field | Type | Description |
| :--- | :--- | :--- |
| `token` | string | Unique token (document ID) |
| `userId` | string | Who created the share |
| `reportIds` | array | List of Firestore report IDs |
| `expiresAt` | timestamp | Expiry time |
| `createdAt` | timestamp | Creation time |

---

## 8. User Flows

### 8.1 Onboarding
1. User opens app → chooses Google Sign‑in (or phone login).
2. After authentication, app checks if profile exists in Firestore.
3. If not, shows Profile Setup screen with required fields (name, phone) and optional fields.
4. User fills required fields (others can be skipped) → profile saved → proceeds to home screen.

### 8.2 Profile Screen (Editable)
- User can view/edit all profile fields except email (auto‑filled).
- Save changes updates Firestore.

### 8.3 Uploading a Report
1. Home screen → tap "Add Report" → choose file (image/PDF).
2. App sends image to laptop backend → backend runs OCR and summarization → returns structured summary.
3. App stores summary in local Hive and uploads to Firestore.
4. User sees summary; if medicines detected, option to add reminders.

### 8.4 AI Assistant
1. Tap "Ask AI" → opens chat.
2. Type or speak a question (e.g., *"What was my last blood test result?"* or *"मुझे कौन सी दवा लेनी है?"*).
3. App sends query to laptop's `/chat` endpoint.
4. Response appears; optionally spoken aloud.
5. User can follow up.

### 8.5 Medicine Reminder
1. From summary or manually, user adds medicine.
2. Enter name, dosage, dosing instruction, times (e.g., 9:00, 21:00).
3. App schedules local notifications.
4. At scheduled time, notification fires: *"Take Ferrous Sulfate – 200 mg – with breakfast"*.
5. User taps notification → opens app to mark taken.

### 8.6 QR Share
1. User selects one or more reports.
2. Sets expiry (e.g., 24 hours) → tap "Generate QR".
3. App calls backend, gets URL, shows QR code.
4. Doctor scans → sees read‑only summary and report image.

---

## 9. Challenges & Mitigations

| Challenge | Mitigation |
| :--- | :--- |
| **LLM size vs GPU memory** | Use 4‑bit quantization (`q4_K_M`) of Llama 3 8B; fallback to Phi‑3‑mini (3.8B) or Mistral 7B with 3‑bit. |
| **Hindi support in LLM** | Use a system prompt encouraging Hindi responses; test with Aya‑23 if needed. |
| **OCR accuracy for Hindi** | Tesseract with Hindi language pack; ensure images are clear. Allow manual correction for poor quality. |
| **Local notifications after device restart** | Use `workmanager` to re‑schedule reminders on app start. |
| **Offline data access** | Hive stores all reports and reminders locally; Firestore sync occurs when online. |

---

## 10. Future Scope

- **Insurance Claim Integration** – API to submit claims to insurers.
- **Multi‑language Expansion** – Add Malayalam, Tamil, etc., using multilingual models.
- **Wearable Integration** – Sync with smartwatches for vital signs.
- **Telemedicine** – In‑app video consultation with doctors.
- **Health Insights** – AI‑driven trend analysis (e.g., blood pressure over time).

---

## 11. Conclusion

**MediMitra** provides a complete, privacy‑focused digital health solution for migrant workers. By combining a powerful offline AI backend (running locally on a laptop with Ollama and ChromaDB) with a user‑friendly Flutter app, it addresses a critical real‑world problem. The architecture is scalable, the features are well‑defined, and the use of open‑source tools ensures zero recurring costs – ideal for a hackathon entry that is both innovative and practical.

---

## 12. Appendix: Sample API Endpoints

### `/upload_report` (POST)
- **Input:** `user_id`, `language`, `file` (multipart/form‑data)
- **Process:** OCR → summarisation → store in Firestore and ChromaDB → return summary JSON

### `/chat` (POST)
- **Input:** `{ "user_id": "...", "query": "...", "language": "..." }`
- **Process:** Retrieve relevant chunks from ChromaDB → build prompt → call Ollama → return answer

### `/reports/{user_id}` (GET)
- **Process:** Query Firestore for all reports of the user → return array of summaries

### `/generate_share` (POST)
- **Input:** `{ "user_id": "...", "report_ids": [...], "expiry_minutes": 1440 }`
- **Process:** Generate random token, store in Firestore, return share URL

### `/share/{token}` (GET)
- **Process:** Validate token, fetch reports from Firestore, return list of summaries and image URLs
