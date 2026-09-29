# 🌾 AgriConnect

**AgriConnect** is a smart agriculture platform designed to help farmers make better decisions using **real-time market prices, AI-based recommendations, and digital agricultural services**.

The project combines a **Flutter mobile application** with a **Python FastAPI backend** to provide farmers with useful market information and intelligent recommendations.

## 🚀 Features

* 🌱 Farmer-friendly mobile application
* 📊 Real-time agricultural market prices
* 🏪 Mandi/APMC market information
* 📍 Market and location-based information
* 💰 Crop price comparison
* 🤖 AI/ML-based recommendations
* 🚚 Transportation cost consideration
* 📈 Helps farmers identify potentially better markets for selling crops
* 🔥 Firebase integration
* ⚡ FastAPI backend
* 📱 Cross-platform Flutter application

## 🏗️ Project Architecture

```text
                 ┌─────────────────────┐
                 │      Farmer         │
                 │   Flutter Mobile    │
                 │       App           │
                 └──────────┬──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │   AgriConnect API   │
                 │      FastAPI        │
                 └──────────┬──────────┘
                            │
             ┌──────────────┼──────────────┐
             ▼              ▼              ▼
       ┌───────────┐  ┌───────────┐  ┌───────────┐
       │ Government│  │  Firebase │  │ AI / ML   │
       │ Mandi Data│  │  Services │  │ Module    │
       └───────────┘  └───────────┘  └───────────┘
```

## 🛠️ Technologies Used

### Frontend

* Flutter
* Dart

### Backend

* Python
* FastAPI

### Database & Cloud

* Firebase
* Firestore

### Data Source

* Government agricultural market/mandi data
* Data.gov.in APIs

### AI/ML

* Machine Learning
* Intelligent market recommendation

## 📂 Project Structure

```text
agriconnect/
│
├── android/             # Android application files
├── backend/             # FastAPI backend
│
├── lib/                 # Flutter application source code
│   ├── screens/
│   ├── widgets/
│   ├── services/
│   └── ...
│
├── test/                # Flutter tests
├── web/                 # Flutter web configuration
│
├── firebase.json        # Firebase configuration
├── pubspec.yaml         # Flutter dependencies
├── analysis_options.yaml
├── .gitignore
└── README.md
```

## ⚙️ Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/jaykar22/agriconnect.git
```

Go to the project folder:

```bash
cd agriconnect
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Run the Flutter Application

```bash
flutter run
```

Make sure an Android device/emulator or supported device is connected.

## 🐍 Backend Setup

Go to the backend folder:

```bash
cd backend
```

Create a Python virtual environment:

```bash
python -m venv venv
```

Activate it on Windows:

```bash
venv\Scripts\activate
```

Install the required packages:

```bash
pip install -r requirements.txt
```

Start the FastAPI server:

```bash
uvicorn main:app --reload
```

The backend will normally be available at:

```text
http://127.0.0.1:8000
```

FastAPI documentation:

```text
http://127.0.0.1:8000/docs
```

## 📊 Market Price API

AgriConnect uses agricultural market data to provide information such as:

* State
* District
* Market/APMC
* Commodity
* Variety
* Grade
* Arrival date
* Minimum price
* Maximum price
* Modal price

Example workflow:

```text
Farmer selects crop
        ↓
AgriConnect requests market data
        ↓
Market prices are retrieved
        ↓
Markets are compared
        ↓
Transportation cost is considered
        ↓
AI/ML recommendation is generated
        ↓
Farmer receives useful market information
```

## 🤖 AI-Based Recommendation

The recommendation module can consider factors such as:

* Crop
* Quantity
* Market price
* Distance
* Transportation cost
* Expected revenue
* Net selling value

For example:

```text
Crop: Tomato
Quantity: 100 Kg

Market Price: ₹15/Kg
Gross Value: ₹1500

Transportation Cost: ₹450

Estimated Net Value: ₹1050
```

This helps farmers understand the potential value of selling their crop at different markets.

## 🔥 Firebase

Firebase can be used for application services such as:

* Authentication
* Firestore database
* User information
* Farmer data
* Application data

Firebase configuration should be properly configured before running the complete application.

## 🔐 Environment Variables

API keys and sensitive credentials should **not** be committed to GitHub.

Example:

```text
DATA_GOV_API_KEY=your_api_key
DATA_GOV_API_URL=your_api_url
```

Use environment variables or a local `.env` configuration for sensitive information.

> ⚠️ Never upload private API keys, passwords, Firebase service-account credentials, or other secrets to GitHub.

## 🎯 Project Objectives

1. Provide farmers with easily accessible agricultural market information.
2. Reduce the difficulty of finding suitable markets.
3. Provide market price information using government data.
4. Consider transportation costs when comparing markets.
5. Use AI/ML techniques to provide intelligent recommendations.
6. Build a simple and farmer-friendly digital platform.
7. Help farmers make data-driven selling decisions.

## 🔮 Future Scope

* 📈 Crop price prediction
* 🌦️ Weather-based recommendations
* 🌱 Crop disease detection
* 🗣️ Voice assistant for farmers
* 🌐 Multiple regional languages
* 📍 GPS-based nearest market detection
* 🔔 Market price alerts
* 📊 Advanced market analytics
* 🤖 Improved AI-based crop selling recommendations
* 💳 Digital agricultural marketplace integration

## 👨‍💻 Developers

**AgriConnect**

Developed as an academic/project initiative focused on applying **Flutter, FastAPI, Firebase, Government agricultural data, and AI/ML** to agriculture.

## 📜 License

This project is developed for educational and research purposes.

---

⭐ If you find this project useful, consider giving the repository a star.
