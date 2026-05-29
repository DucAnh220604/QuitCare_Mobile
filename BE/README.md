# QuitCare Backend API

Backend API for QuitCare Mobile App - Smoking Cessation Support Application

## Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

### 2. Setup MongoDB Atlas

1. Go to https://www.mongodb.com/cloud/atlas
2. Create a free account
3. Create a new cluster
4. Create a database user
5. Get your connection string
6. Copy `.env.example` to `.env` and update `MONGODB_URI`

### 3. Configure Environment

```bash
cp .env.example .env
# Edit .env with your MongoDB connection string and JWT secret
```

### 4. Run Development Server

```bash
npm install -g nodemon  # Install nodemon globally (optional)
npm run dev
```

The server will run on `http://localhost:5000`

## API Endpoints

### Authentication

#### Register

```
POST /api/auth/register
Content-Type: application/json

{
  "fullname": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "phone": "0123456789"
}

Response:
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "token": "jwt_token_here",
    "user": {
      "_id": "user_id",
      "fullname": "John Doe",
      "email": "john@example.com",
      "phone": "0123456789"
    }
  }
}
```

#### Login

```
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}

Response:
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "jwt_token_here",
    "user": {
      "_id": "user_id",
      "fullname": "John Doe",
      "email": "john@example.com",
      "phone": "0123456789"
    }
  }
}
```

#### Get Profile

```
GET /api/auth/profile
Authorization: Bearer jwt_token_here

Response:
{
  "success": true,
  "data": {
    "_id": "user_id",
    "fullname": "John Doe",
    "email": "john@example.com",
    "phone": "0123456789",
    "createdAt": "2024-01-01T00:00:00Z"
  }
}
```

## Error Responses

```json
{
  "success": false,
  "message": "Error message here"
}
```

## Technologies

- Node.js & Express
- MongoDB & Mongoose
- JWT Authentication
- Bcrypt for password hashing
