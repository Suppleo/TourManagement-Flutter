# 🌍 Tour Management App

A full-featured mobile application for browsing, booking, and managing tour packages. Built with Flutter and designed for both customer and admin roles with comprehensive CRUD operations and real-time interactions.

## 📱 Overview

This Flutter application provides a complete tour management solution with dual user interfaces:

- **Customer Interface**: Browse tours, make bookings, manage profiles, and interact with AI chatbot
- **Admin Interface**: Complete CRUD operations for tours, users, bookings, reviews, and more

## 🏗️ Architecture

### Tech Stack

| Layer                | Technology                |
| -------------------- | ------------------------- |
| **Frontend**         | Flutter (Dart)            |
| **Backend**          | Node.js with GraphQL      |
| **Database**         | MongoDB (tour_management) |
| **AI Integration**   | Google Gemini API         |
| **State Management** | Provider Pattern          |
| **Navigation**       | GoRouter                  |
| **Network**          | GraphQL Flutter           |

### Project Structure

```
lib/
├── core/
│   ├── gemini_service.dart      # AI ChatBot integration
│   └── network/
│       ├── api_config.dart      # API endpoints configuration
│       └── graphql_service.dart # GraphQL client setup
├── models/                      # Data models
├── providers/                   # State management
├── screens/
│   ├── admin/                   # Admin interface screens
│   ├── auth/                    # Authentication screens
│   └── customer/                # Customer interface screens
├── graphql/
│   ├── mutations/               # GraphQL mutations
│   └── queries/                 # GraphQL queries
└── widgets/                     # Reusable UI components
```

## 🚀 Key Features

### 👤 Customer Features

- **🔐 Authentication**
  - Email/Password login
  - Google OAuth integration
  - User registration
- **🏖️ Tour Management**
  - Browse tour listings with filters
  - View detailed tour information
  - Search tours by location
- **📅 Booking System**
  - Create and manage bookings
  - Payment integration (Stripe)
  - Booking history and status tracking
- **✍️ Review System**
  - Write and view tour reviews
  - Rating system
- **👤 Profile Management**
  - Update personal information
  - View booking history
  - Profile customization
- **🤖 AI ChatBot**
  - Interactive tour recommendations
  - FAQ support
  - Location-based tour suggestions

### 🛠️ Admin Features

- **👥 User Management**
  - View all users
  - Update user information
  - Delete users
- **🧳 Tour Management**
  - Create, edit, delete tours
  - Manage tour categories
  - Upload tour images/videos
- **📋 Booking Management**
  - View all bookings
  - Update booking status
  - Booking analytics
- **⭐ Review Moderation**
  - Moderate user reviews
  - Approve/reject reviews
- **🎟️ Voucher System**
  - Create and manage vouchers
  - Discount code generation
- **📊 Dashboard**
  - Analytics and statistics
  - System logs
  - Activity monitoring

## 🛠️ Installation & Setup

### Prerequisites

- Flutter SDK (^3.8.1)
- Dart SDK
- Android Studio / VS Code
- Node.js (for backend)

### Frontend Setup

```bash
# Clone the repository
git clone <repository-url>
cd mobile_flutter-main

# Install dependencies
flutter pub get

# Run the application
flutter run
```

### Environment Configuration

Create a `.env` file in the root directory:

```env
GRAPHQL_URL=http://10.0.2.2:4000/graphql
UPLOAD_URL=http://10.0.2.2:4000/api/upload
GEMINI_API_KEY=your_gemini_api_key
```

## 📦 Dependencies

### Core Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  graphql_flutter: ^5.1.2
  provider: ^6.1.1
  go_router: ^12.1.0
  flutter_form_builder: ^10.0.1
  intl: ^0.19.0
  flutter_dotenv: ^5.0.2
  image_picker: ^1.0.7
  dio: ^5.4.0
  cached_network_image: ^3.3.1
  webview_flutter: ^4.13.0
  uni_links: ^0.5.1
```

## 🔧 Configuration

### API Configuration

The app connects to a GraphQL backend with the following endpoints:

- **GraphQL**: `http://10.0.2.2:4000/graphql`
- **File Upload**: `http://10.0.2.2:4000/api/upload`
- **Static Files**: `http://10.0.2.2:4000/uploads/`

### AI Integration

The ChatBot feature integrates with Google Gemini API for:

- Tour recommendations
- FAQ responses
- Location-based suggestions

## 🎯 Key Components

### State Management

The app uses Provider pattern for state management with dedicated providers for:

- `AuthProvider`: Authentication state
- `TourProvider`: Tour data management
- `BookingProvider`: Booking operations
- `ReviewProvider`: Review management
- `ProfileProvider`: User profile data
- `VoucherProvider`: Voucher system
- `CategoryProvider`: Tour categories
- `PaymentProvider`: Payment processing
- `LogProvider`: System logs

### GraphQL Integration

Comprehensive GraphQL integration with:

- **Mutations**: User operations, tour CRUD, booking management
- **Queries**: Data fetching for tours, users, bookings, reviews
- **Real-time updates**: Live data synchronization

### Navigation

Uses GoRouter for efficient navigation with:

- Role-based routing (Admin/Customer)
- Deep linking support
- Route protection

## 🎨 UI/UX Features

- **Responsive Design**: Works on various screen sizes
- **Material Design**: Modern UI components
- **Dark/Light Theme**: Theme customization
- **Loading States**: Smooth user experience
- **Error Handling**: User-friendly error messages
- **Form Validation**: Input validation and feedback

## 🔐 Security Features

- **JWT Authentication**: Secure token-based auth
- **Role-based Access**: Admin/Customer permissions
- **Input Validation**: Server-side validation
- **Secure API Calls**: HTTPS communication
- **Token Management**: Automatic token refresh

## 🚀 Deployment

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Support

For support and questions:

- Create an issue in the repository
- Contact the developer directly

---

**Built with ❤️ using Flutter and GraphQL**
