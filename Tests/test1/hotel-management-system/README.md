### 1. Database Connection (PHP Example)

First, create a file named `db_connection.php` to handle the database connection.

```php
<?php
$servername = "localhost";
$username = "your_username";
$password = "your_password";
$dbname = "hotel_DB";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>
```

### 2. HTML Interface

Create an HTML file named `index.html` for the user interface.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hotel Management System</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <h1>Hotel Management System</h1>
    
    <h2>Staff Management</h2>
    <form id="staffForm">
        <input type="text" id="first_name" placeholder="First Name" required>
        <input type="text" id="last_name" placeholder="Last Name" required>
        <input type="text" id="title" placeholder="Title" required>
        <input type="text" id="role" placeholder="Role" required>
        <input type="number" id="manager_id" placeholder="Manager ID (optional)">
        <button type="submit">Add Staff</button>
    </form>

    <h2>Room Types</h2>
    <form id="roomTypeForm">
        <input type="text" id="room_type_code" placeholder="Room Type Code" required>
        <input type="text" id="room_type_name" placeholder="Room Type Name" required>
        <input type="number" id="modern_style" placeholder="Modern Style (0 or 1)" required>
        <input type="number" id="deluxe" placeholder="Deluxe (0 or 1)" required>
        <input type="number" id="maximum_guests" placeholder="Maximum Guests" required>
        <button type="submit">Add Room Type</button>
    </form>

    <script src="script.js"></script>
</body>
</html>
```

### 3. JavaScript for Form Submission

Create a file named `script.js` to handle form submissions.

```javascript
document.getElementById('staffForm').addEventListener('submit', function(event) {
    event.preventDefault();
    const formData = new FormData(this);
    
    fetch('add_staff.php', {
        method: 'POST',
        body: formData
    })
    .then(response => response.text())
    .then(data => {
        alert(data);
        this.reset();
    })
    .catch(error => console.error('Error:', error));
});

document.getElementById('roomTypeForm').addEventListener('submit', function(event) {
    event.preventDefault();
    const formData = new FormData(this);
    
    fetch('add_room_type.php', {
        method: 'POST',
        body: formData
    })
    .then(response => response.text())
    .then(data => {
        alert(data);
        this.reset();
    })
    .catch(error => console.error('Error:', error));
});
```

### 4. PHP Scripts for Adding Data

Create `add_staff.php` to handle staff addition.

```php
<?php
include 'db_connection.php';

$first_name = $_POST['first_name'];
$last_name = $_POST['last_name'];
$title = $_POST['title'];
$role = $_POST['role'];
$manager_id = $_POST['manager_id'] ? $_POST['manager_id'] : 'NULL';

$sql = "INSERT INTO staff (first_name, last_name, title, role, manager_id) VALUES ('$first_name', '$last_name', '$title', '$role', $manager_id)";

if ($conn->query($sql) === TRUE) {
    echo "New staff added successfully";
} else {
    echo "Error: " . $sql . "<br>" . $conn->error;
}

$conn->close();
?>
```

Create `add_room_type.php` to handle room type addition.

```php
<?php
include 'db_connection.php';

$room_type_code = $_POST['room_type_code'];
$room_type_name = $_POST['room_type_name'];
$modern_style = $_POST['modern_style'];
$deluxe = $_POST['deluxe'];
$maximum_guests = $_POST['maximum_guests'];

$sql = "INSERT INTO room_type (room_type_code, room_type_name, modern_style, deluxe, maximum_guests) VALUES ('$room_type_code', '$room_type_name', $modern_style, $deluxe, $maximum_guests)";

if ($conn->query($sql) === TRUE) {
    echo "New room type added successfully";
} else {
    echo "Error: " . $sql . "<br>" . $conn->error;
}

$conn->close();
?>
```

### 5. CSS for Basic Styling

Create a file named `styles.css` for basic styling.

```css
body {
    font-family: Arial, sans-serif;
    margin: 20px;
}

h1, h2 {
    color: #333;
}

form {
    margin-bottom: 20px;
}

input {
    display: block;
    margin: 5px 0;
    padding: 10px;
    width: 200px;
}

button {
    padding: 10px;
    background-color: #007BFF;
    color: white;
    border: none;
    cursor: pointer;
}

button:hover {
    background-color: #0056b3;
}
```

### Summary

This basic interface allows users to add staff and room types to the hotel management system. You can expand this by adding more features such as viewing, updating, and deleting records, as well as implementing user authentication and authorization. Make sure to handle security aspects like SQL injection and data validation in a production environment.