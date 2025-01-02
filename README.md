# Mobile Controller Remotely

This Flutter app connects to a local server and provides multiple functionalities for interacting with the device's native features, such as accessing call logs, contacts, messages, gallery, camera, files, and WhatsApp chats. The server is built using the `shelf` and `shelf_router` libraries to handle HTTP requests, and the app communicates with native methods through platform channels.

## Features

The app provides the following API endpoints:

### 1. **/hello**
- **Method**: `GET`
- **Description**: A test endpoint that returns a simple greeting.
- **Response**: `Hello from Flutter!`

### 2. **/call_logs**
- **Method**: `GET`
- **Description**: Fetch the device's call logs using a native method.
- **Response**: List of call logs (in string format).

### 3. **/make_call**
- **Method**: `POST`
- **Description**: Make a call to the specified phone number.
- **Request Body**: 
  ```json
  {
    "phoneNumber": "<phone_number>"
  }
  ```
- **Response**: Call log information (in string format).

### 4. **/get_contacts**
- **Method**: `POST`
- **Description**: Fetch all contacts from the device.
- **Response**: List of contacts (in string format).

### 5. **/get_messages**
- **Method**: `POST`
- **Description**: Fetch messages associated with a specified phone number.
- **Request Body**:
  ```json
  {
    "phoneNumber": "<phone_number>"
  }
  ```
- **Response**: List of messages (in string format).

### 6. **/get_gallery**
- **Method**: `POST`
- **Description**: Fetch gallery images from the device.
- **Response**: List of gallery images (in string format).

### 7. **/get_files**
- **Method**: `POST`
- **Description**: Fetch all files from the device.
- **Response**: List of files (in string format).

### 8. **/access_camera**
- **Method**: `POST`
- **Description**: Request access to the device’s camera.
- **Response**: Camera access status (in string format).

### 9. **/get_whatsapp_chats**
- **Method**: `POST`
- **Description**: Fetch WhatsApp chats associated with a specified phone number and message.
- **Request Body**:
  ```json
  {
    "phoneNumber": "<phone_number>",
    "message": "<message>"
  }
  ```
- **Response**: WhatsApp chat information (in string format).

## Setup

### Prerequisites
- Flutter 2.x or later
- Dart 2.x or later
- A device/emulator with native Android or iOS functionality
- Shelf and Shelf Router packages

### Installation
1. Clone this repository:
   ```bash
   git clone https://github.com/your-repository-url.git
   cd your-repository-folder
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Start the server:
   ```bash
   flutter run
   ```

### Native Code Setup
For each of the API methods, you will need to implement the corresponding native code for iOS and Android in your Flutter app (e.g., using platform channels). The following native functionalities are required:

- Access to call logs, contacts, messages, gallery, files, camera, and WhatsApp chats.
- Appropriate permissions for reading contacts, making calls, sending/receiving messages, accessing the gallery, and using the camera.

### API Server

The server will run on `http://<device-ip>:8080`, where `<device-ip>` is the IP address of the machine running the server. The server listens for incoming requests and responds based on the endpoints defined.

## Example API Calls

### Get Call Logs
```bash
curl -X GET http://<device-ip>:8080/call_logs
```

### Make a Call
```bash
curl -X POST http://<device-ip>:8080/make_call -d '{"phoneNumber": "1234567890"}' -H "Content-Type: application/json"
```

### Get Contacts
```bash
curl -X POST http://<device-ip>:8080/get_contacts
```

### Get Messages for a Specific Phone Number
```bash
curl -X POST http://<device-ip>:8080/get_messages -d '{"phoneNumber": "1234567890"}' -H "Content-Type: application/json"
```

### Access Camera
```bash
curl -X POST http://<device-ip>:8080/access_camera
```

## Notes
- The server runs asynchronously, so it does not block the UI thread.
- Make sure to handle permissions appropriately in the native code for each platform.
