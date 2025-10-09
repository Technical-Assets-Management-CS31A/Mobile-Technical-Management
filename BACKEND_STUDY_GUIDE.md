# Backend Technical Assets Management - Frontend Study Guide

## 📋 Table of Contents
1. [Quick URL Reference](#quick-url-reference)
2. [API Overview](#api-overview)
3. [Authentication System](#authentication-system)
4. [Data Models & DTOs](#data-models--dtos)
5. [API Endpoints Reference](#api-endpoints-reference)
6. [Error Handling Patterns](#error-handling-patterns)
7. [Image Handling](#image-handling)
8. [User Roles & Permissions](#user-roles--permissions)
9. [Flutter Integration Guidelines](#flutter-integration-guidelines)

---

## 🚀 Quick URL Reference

### All API Endpoints at a Glance

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| **Authentication** |
| POST | `/api/v1/auth/register` | Register new user | ❌ |
| POST | `/api/v1/auth/login` | User login | ❌ |
| POST | `/api/v1/auth/logout` | User logout | ✅ |
| POST | `/api/v1/auth/refresh-token` | Refresh access token | ❌ |
| **User Management** |
| GET | `/api/v1/users/me` | Get current user profile | ✅ |
| GET | `/api/v1/users` | Get all users | ✅ (Admin/Staff) |
| PATCH | `/api/v1/users/students/{id}/profile` | Update student profile | ✅ |
| PATCH | `/api/v1/users/teachers/{id}/profile` | Update teacher profile | ✅ |
| PATCH | `/api/v1/users/staff/{id}/profile` | Update staff profile | ✅ |
| PATCH | `/api/v1/users/admin/{id}/profile` | Update admin profile | ✅ |
| DELETE | `/api/v1/users/{id}` | Delete user | ✅ (Admin) |
| **Item Management** |
| GET | `/api/v1/items` | Get all items | ✅ (Admin/Staff) |
| GET | `/api/v1/items/{id}` | Get item by ID | ✅ (Admin/Staff) |
| POST | `/api/v1/items` | Create new item | ✅ (Admin/Staff) |
| PUT | `/api/v1/items/{id}` | Update item | ✅ (Admin/Staff) |
| DELETE | `/api/v1/items/archive{id}` | Archive item | ✅ (Admin) |
| **Lending Management** |
| GET | `/api/v1/lentItems` | Get all lent items | ✅ (Admin/Staff) |
| GET | `/api/v1/lentItems/{id}` | Get lent item by ID | ✅ (Admin/Staff) |
| GET | `/api/v1/lentItems/date/{dateTime}` | Get lent items by date | ✅ (Admin/Staff) |
| POST | `/api/v1/lentItems` | Create lending record | ✅ (Admin/Staff) |
| POST | `/api/v1/lentItems/guests` | Create guest lending record | ✅ (Admin/Staff) |
| PATCH | `/api/v1/lentItems/{id}` | Update lending record | ✅ (Admin/Staff) |
| DELETE | `/api/v1/lentItems/{id}` | Soft delete lending record | ✅ (Admin/Staff) |
| **Archive Management** |
| GET | `/api/v1/archiveitems` | Get all archived items | ✅ (Admin/Staff) |
| GET | `/api/v1/archiveitems/{id}` | Get archived item by ID | ✅ (Admin/Staff) |
| DELETE | `/api/v1/archiveitems/restore/{id}` | Restore archived item | ✅ (Admin) |
| DELETE | `/api/v1/archiveitems/{id}` | Permanently delete archived item | ✅ (Admin) |
| **Statistics** |
| GET | `/api/summary` | Get overall summary | ✅ (Admin/Staff) |
| GET | `/api/summary/items` | Get item statistics | ✅ (Admin/Staff) |
| GET | `/api/summary/lent-items` | Get lending statistics | ✅ (Admin/Staff) |
| GET | `/api/summary/users` | Get user statistics | ✅ (Admin/Staff) |
| **Utilities** |
| GET | `/api/v1/barcodes/{text}` | Generate barcode image | ✅ |

---

## 🌐 API Overview

### Base URL Structure
```
Base URL: https://your-backend-url.com
API Version: v1
```

### Common Headers
```dart
{
  'Content-Type': 'application/json',
  'Authorization': 'Bearer {access_token}', // For protected endpoints
}
```

### Response Format
All API responses follow this consistent pattern:
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { /* actual data */ },
  "errors": null
}
```

---

## 🔐 Authentication System

### Login Flow
```dart
// POST /api/v1/auth/login
{
  "identifier": "username_or_email",
  "password": "user_password"
}

// Response
{
  "success": true,
  "message": "Login successful",
  "data": {
    "id": "guid",
    "username": "string",
    "email": "string",
    "userRole": "Student|Teacher|Staff|Admin|SuperAdmin",
    "status": "Active|Inactive"
  }
}
```

### Token Management
- **Access Token**: 15 minutes expiry, stored in HttpOnly cookie
- **Refresh Token**: 7 days expiry, stored in HttpOnly cookie
- **Auto-refresh**: Use refresh endpoint when access token expires

### Registration Flow
```dart
// POST /api/v1/auth/register
// Different DTOs based on user role:

// Student Registration
{
  "username": "string",
  "firstName": "string",
  "lastName": "string",
  "middleName": "string?",
  "email": "string",
  "phoneNumber": "string",
  "role": "Student",
  "password": "string",
  "confirmPassword": "string",
  "studentIdNumber": "string",
  "course": "string",
  "year": "string",
  "section": "string",
  "street": "string",
  "cityMunicipality": "string",
  "province": "string",
  "postalCode": "string",
  "profilePicture": "File?",
  "frontStudentIdPicture": "File?",
  "backStudentIdPicture": "File?"
}

// Teacher Registration
{
  "username": "string",
  "firstName": "string",
  "lastName": "string",
  "email": "string",
  "phoneNumber": "string",
  "role": "Teacher",
  "password": "string",
  "confirmPassword": "string",
  "department": "string"
}

// Staff Registration
{
  "username": "string",
  "firstName": "string",
  "lastName": "string",
  "email": "string",
  "phoneNumber": "string",
  "role": "Staff",
  "password": "string",
  "confirmPassword": "string",
  "position": "string"
}
```

---

## 📊 Data Models & DTOs

### User Models
```dart
// Base User
class UserDto {
  String id;
  String username;
  String email;
  UserRole userRole;
  String? status;
}

// Student Profile
class StudentDto extends UserDto {
  String? frontStudentIdPicture;
  String? backStudentIdPicture;
  String lastName;
  String? middleName;
  String firstName;
  String studentIdNumber;
  String phoneNumber;
  String course;
  String section;
  String year;
  String? profilePicture;
  String street;
  String cityMunicipality;
  String province;
  String postalCode;
}

// Teacher Profile
class TeacherDto extends UserDto {
  String lastName;
  String? middleName;
  String firstName;
  String department;
  String? phoneNumber;
}

// Staff Profile
class StaffDto extends UserDto {
  String lastName;
  String? middleName;
  String firstName;
  String phoneNumber;
  String position;
}
```

### Item Models
```dart
class ItemDto {
  String id;
  String serialNumber; // Format: "SN-{number}"
  String? image; // Base64 string
  String itemName;
  String itemType;
  String? itemModel;
  String itemMake;
  String? description;
  ItemCategory category;
  ItemCondition condition;
  DateTime createdAt;
  DateTime updatedAt;
}

enum ItemCategory {
  Electronics,
  Keys,
  MediaEquipment,
  Tools,
  Miscellaneous
}

enum ItemCondition {
  New,        // Green
  Good,       // Teal/Blue
  Defective,  // Red
  Refurbished, // Purple
  NeedRepair  // Orange
}
```

### Lending Models
```dart
class LentItemsDto {
  String id;
  String? itemId;
  String? userId;
  String? teacherId;
  String borrowerFullName;
  String borrowerRole;
  String? teacherFullName;
  String room;
  String subjectTimeSchedule;
  DateTime lentAt;
  DateTime? returnedAt;
  String remarks;
}

// For registered users
class CreateLentItemDto {
  String itemId;
  String? userId;
  String? teacherId;
  String room;
  String subjectTimeSchedule;
}

// For guest users
class CreateLentItemsForGuestDto {
  String itemId;
  String borrowerFirstName;
  String borrowerLastName;
  String borrowerRole;
  String? studentIdNumber; // Required if role is "Student"
  String teacherFirstName;
  String teacherLastName;
  String room;
  String subjectTimeSchedule;
}
```

---

## 🛠️ API Endpoints Reference

### Complete URL Reference

#### Base URL Structure
```
Base URL: https://your-backend-url.com
API Version: v1
```

#### Authentication Endpoints
```
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/logout
POST /api/v1/auth/refresh-token
```

#### User Management Endpoints
```
GET  /api/v1/users/me
GET  /api/v1/users
PATCH /api/v1/users/students/{id}/profile
PATCH /api/v1/users/teachers/{id}/profile
PATCH /api/v1/users/staff/{id}/profile
PATCH /api/v1/users/admin/{id}/profile
DELETE /api/v1/users/{id}
```

#### Item Management Endpoints
```
GET    /api/v1/items
GET    /api/v1/items/{id}
POST   /api/v1/items
PUT    /api/v1/items/{id}
DELETE /api/v1/items/archive{id}
```

#### Lending Endpoints
```
GET    /api/v1/lentItems
GET    /api/v1/lentItems/{id}
GET    /api/v1/lentItems/date/{dateTime}
POST   /api/v1/lentItems
POST   /api/v1/lentItems/guests
PATCH  /api/v1/lentItems/{id}
DELETE /api/v1/lentItems/{id}
```

#### Archive Endpoints
```
GET    /api/v1/archiveitems
GET    /api/v1/archiveitems/{id}
DELETE /api/v1/archiveitems/restore/{id}
DELETE /api/v1/archiveitems/{id}
```

#### Statistics Endpoints
```
GET /api/summary
GET /api/summary/items
GET /api/summary/lent-items
GET /api/summary/users
```

#### Utility Endpoints
```
GET /api/v1/barcodes/{text}
```

---

### Detailed Endpoint Documentation

### Authentication Endpoints
```dart
// Login
POST /api/v1/auth/login
Body: LoginUserDto
Response: ApiResponse<UserDto>

// Register
POST /api/v1/auth/register
Body: RegisterUserDto (varies by role)
Response: ApiResponse<UserDto>

// Logout
POST /api/v1/auth/logout
Headers: Authorization required
Response: ApiResponse<object>

// Refresh Token
POST /api/v1/auth/refresh-token
Response: ApiResponse<String> // New access token
```

### User Management Endpoints
```dart
// Get current user profile
GET /api/v1/users/me
Headers: Authorization required
Response: ApiResponse<BaseProfileDto>

// Get all users (Admin/Staff only)
GET /api/v1/users
Headers: Authorization required, AdminOrStaff policy
Response: ApiResponse<List<UserDto>>

// Update student profile
PATCH /api/v1/users/students/{id}/profile
Headers: Authorization required
Body: UpdateStudentProfileDto (FormData)
Response: ApiResponse<object>

// Update teacher profile
PATCH /api/v1/users/teachers/{id}/profile
Headers: Authorization required
Body: UpdateTeacherProfileDto
Response: ApiResponse<object>

// Update staff profile
PATCH /api/v1/users/staff/{id}/profile
Headers: Authorization required
Body: UpdateStaffProfileDto
Response: ApiResponse<object>

// Delete user (Admin only)
DELETE /api/v1/users/{id}
Headers: Authorization required, Admin role
Response: ApiResponse<object>
```

### Item Management Endpoints
```dart
// Get all items (Admin/Staff only)
GET /api/v1/items
Headers: Authorization required, AdminOrStaff policy
Response: ApiResponse<List<ItemDto>>

// Get item by ID
GET /api/v1/items/{id}
Headers: Authorization required, AdminOrStaff policy
Response: ApiResponse<ItemDto>

// Create item
POST /api/v1/items
Headers: Authorization required, AdminOrStaff policy
Body: CreateItemsDto (FormData with image)
Response: ApiResponse<ItemDto>

// Update item
PUT /api/v1/items/{id}
Headers: Authorization required, AdminOrStaff policy
Body: UpdateItemsDto (FormData with optional image)
Response: ApiResponse<object>

// Archive item (Admin only)
DELETE /api/v1/items/archive{id}
Headers: Authorization required, Admin role
Response: ApiResponse<object>
```

### Lending Endpoints
```dart
// Get all lent items (Admin/Staff only)
GET /api/v1/lentItems
Headers: Authorization required, AdminOrStaff policy
Response: ApiResponse<List<LentItemsDto>>

// Get lent item by ID
GET /api/v1/lentItems/{id}
Headers: Authorization required, AdminOrStaff policy
Response: ApiResponse<LentItemsDto>

// Get lent items by date
GET /api/v1/lentItems/date/{dateTime}
Headers: Authorization required, AdminOrStaff policy
Response: ApiResponse<LentItemsDto>

// Create lending record (registered user)
POST /api/v1/lentItems
Headers: Authorization required, AdminOrStaff policy
Body: CreateLentItemDto
Response: ApiResponse<LentItemsDto>

// Create lending record (guest user)
POST /api/v1/lentItems/guests
Headers: Authorization required, AdminOrStaff policy
Body: CreateLentItemsForGuestDto
Response: ApiResponse<LentItemsDto>

// Update lending record
PATCH /api/v1/lentItems/{id}
Headers: Authorization required, AdminOrStaff policy
Body: UpdateLentItemDto
Response: ApiResponse<object>

// Soft delete lending record
DELETE /api/v1/lentItems/{id}
Headers: Authorization required, AdminOrStaff policy
Response: ApiResponse<object>
```

### Archive Endpoints
```dart
// Get all archived items (Admin/Staff only)
GET /api/v1/archiveitems
Headers: Authorization required, AdminOrStaff policy
Response: ApiResponse<List<ArchiveItemsDto>>

// Get archived item by ID
GET /api/v1/archiveitems/{id}
Headers: Authorization required, AdminOrStaff policy
Response: ApiResponse<ArchiveItemsDto>

// Restore archived item (Admin only)
DELETE /api/v1/archiveitems/restore/{id}
Headers: Authorization required, Admin role
Response: ApiResponse<ItemDto>

// Permanently delete archived item (Admin only)
DELETE /api/v1/archiveitems/{id}
Headers: Authorization required, Admin role
Response: ApiResponse<String>
```

### Statistics Endpoints
```dart
// Get overall summary (Admin/Staff only)
GET /api/summary
Headers: Authorization required, AdminOrStaff policy
Response: ApiResponse<SummaryDto>

// Get item statistics
GET /api/summary/items
Headers: Authorization required, AdminOrStaff policy
Response: ApiResponse<ItemCount>

// Get lending statistics
GET /api/summary/lent-items
Headers: Authorization required, AdminOrStaff policy
Response: ApiResponse<LentItemsCount>

// Get user statistics
GET /api/summary/users
Headers: Authorization required, AdminOrStaff policy
Response: ApiResponse<ActiveUserCount>
```

### Utility Endpoints
```dart
// Generate barcode
GET /api/v1/barcodes/{text}
Headers: Authorization required
Response: PNG image file
```

---

## ⚠️ Error Handling Patterns

### HTTP Status Codes
- `200 OK`: Successful operation
- `201 Created`: Resource created successfully
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Authentication required
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `409 Conflict`: Duplicate resource (e.g., serial number)
- `500 Internal Server Error`: Server error

### Error Response Format
```json
{
  "success": false,
  "message": "Error description",
  "data": null,
  "errors": ["Detailed error 1", "Detailed error 2"]
}
```

### Common Error Scenarios
```dart
// Duplicate serial number
{
  "success": false,
  "message": "An item with serial number 'SN-123456' already exists.",
  "data": null,
  "errors": null
}

// Validation errors
{
  "success": false,
  "message": "Validation failed",
  "data": null,
  "errors": [
    "Password must be at least 8 characters long",
    "Email format is invalid"
  ]
}

// Authentication errors
{
  "success": false,
  "message": "Invalid username or password",
  "data": null,
  "errors": null
}
```

---

## 🖼️ Image Handling

### Image Upload Format
- **Content-Type**: `multipart/form-data`
- **Field Name**: `image`, `profilePicture`, `frontStudentIdPicture`, `backStudentIdPicture`
- **Supported Formats**: PNG, JPG, JPEG, WEBP
- **Max Size**: 10MB
- **Storage**: Base64 encoded in database

### Image Response Format
```dart
// Images are returned as Base64 strings
{
  "id": "guid",
  "image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
  // other fields...
}
```

### Flutter Implementation Tips
```dart
// Convert File to Base64
String base64Image = base64Encode(await imageFile.readAsBytes());

// Display Base64 image
Image.memory(
  base64Decode(base64ImageString),
  fit: BoxFit.cover,
)

// Upload image with FormData
FormData formData = FormData.fromMap({
  'image': await MultipartFile.fromFile(
    imageFile.path,
    filename: 'image.png',
  ),
  // other fields...
});
```

---

## 👥 User Roles & Permissions

### Role Hierarchy
1. **SuperAdmin**: Full system access
2. **Admin**: User and item management
3. **Staff**: Item and lending management
4. **Teacher**: Limited access (can supervise lending)
5. **Student**: Basic access (can borrow items)

### Permission Matrix
| Action | SuperAdmin | Admin | Staff | Teacher | Student |
|--------|------------|-------|-------|---------|---------|
| View Items | ✅ | ✅ | ✅ | ✅ | ✅ |
| Create Items | ✅ | ✅ | ✅ | ❌ | ❌ |
| Update Items | ✅ | ✅ | ✅ | ❌ | ❌ |
| Delete Items | ✅ | ✅ | ❌ | ❌ | ❌ |
| View Users | ✅ | ✅ | ✅ | ❌ | ❌ |
| Create Users | ✅ | ✅ | ❌ | ❌ | ❌ |
| Delete Users | ✅ | ✅ | ❌ | ❌ | ❌ |
| View Lending | ✅ | ✅ | ✅ | ✅ | ❌ |
| Create Lending | ✅ | ✅ | ✅ | ❌ | ❌ |
| Update Lending | ✅ | ✅ | ✅ | ❌ | ❌ |
| View Archive | ✅ | ✅ | ✅ | ❌ | ❌ |
| Restore Items | ✅ | ✅ | ❌ | ❌ | ❌ |

### Authorization Headers
```dart
// Check user role in Flutter
if (userRole == 'Admin' || userRole == 'Staff') {
  // Show admin/staff features
}

// Role-based UI
Widget buildUserManagementButton() {
  if (currentUser.role == 'Admin' || currentUser.role == 'SuperAdmin') {
    return ElevatedButton(
      onPressed: () => navigateToUserManagement(),
      child: Text('Manage Users'),
    );
  }
  return SizedBox.shrink();
}
```

---

## 📱 Flutter Integration Guidelines

### 1. HTTP Client Setup
```dart
class ApiClient {
  static const String baseUrl = 'https://your-backend-url.com';
  late Dio _dio;
  
  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
    ));
    
    // Add interceptors for auth, logging, etc.
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LogInterceptor());
  }
}
```

### 2. Authentication Interceptor
```dart
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add auth token to headers
    final token = AuthService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 errors with token refresh
    if (err.response?.statusCode == 401) {
      _handleTokenRefresh().then((_) {
        // Retry original request
      });
    }
    handler.next(err);
  }
}
```

### 3. Model Classes
```dart
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String>? errors;
  
  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });
  
  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return ApiResponse<T>(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      errors: json['errors']?.cast<String>(),
    );
  }
}
```

### 4. Service Layer Pattern
```dart
class ItemService {
  final ApiClient _apiClient;
  
  ItemService(this._apiClient);
  
  Future<ApiResponse<List<ItemDto>>> getAllItems() async {
    try {
      final response = await _apiClient.get('/api/v1/items');
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List).map((item) => ItemDto.fromJson(item)).toList(),
      );
    } catch (e) {
      throw Exception('Failed to fetch items: $e');
    }
  }
  
  Future<ApiResponse<ItemDto>> createItem(CreateItemsDto item) async {
    try {
      final formData = FormData.fromMap({
        'itemName': item.itemName,
        'serialNumber': item.serialNumber,
        'category': item.category.toString(),
        'condition': item.condition.toString(),
        if (item.image != null) 'image': await MultipartFile.fromFile(item.image!.path),
      });
      
      final response = await _apiClient.post('/api/v1/items', data: formData);
      return ApiResponse.fromJson(
        response.data,
        (data) => ItemDto.fromJson(data),
      );
    } catch (e) {
      throw Exception('Failed to create item: $e');
    }
  }
}
```

### 5. State Management Integration
```dart
// Using Provider/Riverpod/Bloc
class ItemNotifier extends StateNotifier<AsyncValue<List<ItemDto>>> {
  final ItemService _itemService;
  
  ItemNotifier(this._itemService) : super(const AsyncValue.loading()) {
    loadItems();
  }
  
  Future<void> loadItems() async {
    state = const AsyncValue.loading();
    try {
      final response = await _itemService.getAllItems();
      if (response.success) {
        state = AsyncValue.data(response.data ?? []);
      } else {
        state = AsyncValue.error(response.message, StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
```

### 6. Error Handling Widget
```dart
class ErrorHandler {
  static void handleApiError(ApiResponse response, BuildContext context) {
    if (!response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.red,
        ),
      );
      
      if (response.errors != null && response.errors!.isNotEmpty) {
        // Show detailed errors in dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Validation Errors'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: response.errors!.map((error) => Text(error)).toList(),
            ),
          ),
        );
      }
    }
  }
}
```

### 7. Form Validation
```dart
class ItemFormValidator {
  static String? validateSerialNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Serial number is required';
    }
    if (!value.startsWith('SN-')) {
      return 'Serial number must start with SN-';
    }
    return null;
  }
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain special character';
    }
    return null;
  }
}
```

---

## 🚀 Quick Start Checklist

### Backend Integration Setup
- [ ] Configure base URL and API endpoints
- [ ] Set up HTTP client with interceptors
- [ ] Implement authentication token management
- [ ] Create model classes for all DTOs
- [ ] Set up error handling and response parsing
- [ ] Implement image upload/download functionality
- [ ] Add role-based UI components
- [ ] Set up form validation
- [ ] Implement state management for API calls
- [ ] Add loading states and error boundaries

### Testing Endpoints
- [ ] Test authentication flow (login/register/logout)
- [ ] Test CRUD operations for items
- [ ] Test lending functionality
- [ ] Test user profile management
- [ ] Test image upload and display
- [ ] Test role-based access control
- [ ] Test error handling scenarios

---

## 📝 Notes

- All timestamps are in UTC format
- Serial numbers are automatically prefixed with "SN-"
- Images are stored as Base64 strings in the database
- Refresh tokens are automatically managed via cookies
- CORS is configured for Flutter development on localhost
- The system supports both registered users and guest lending
- Archive system provides soft delete with restore capability

---

*This study guide should be your primary reference when developing the Flutter frontend. Keep it updated as the backend evolves.*
