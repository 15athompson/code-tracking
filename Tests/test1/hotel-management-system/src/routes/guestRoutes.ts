<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hotel Management System</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <header>
        <h1>Hotel Management System</h1>
    </header>
    <nav>
        <ul>
            <li><a href="#addStaff">Add Staff</a></li>
            <li><a href="#viewStaff">View Staff</a></li>
            <li><a href="#addRoomType">Add Room Type</a></li>
            <li><a href="#viewRoomTypes">View Room Types</a></li>
        </ul>
    </nav>
    <main>
        <section id="addStaff">
            <h2>Add Staff</h2>
            <form id="staffForm">
                <input type="text" name="first_name" placeholder="First Name" required>
                <input type="text" name="last_name" placeholder="Last Name" required>
                <input type="text" name="title" placeholder="Title" required>
                <input type="text" name="role" placeholder="Role" required>
                <input type="number" name="manager_id" placeholder="Manager ID">
                <button type="submit">Add Staff</button>
            </form>
        </section>
        <section id="viewStaff">
            <h2>Staff List</h2>
            <div id="staffList"></div>
        </section>
        <section id="addRoomType">
            <h2>Add Room Type</h2>
            <form id="roomTypeForm">
                <input type="text" name="room_type_code" placeholder="Room Type Code" required>
                <input type="text" name="room_type_name" placeholder="Room Type Name" required>
                <input type="number" name="modern_style" placeholder="Modern Style (0 or 1)" required>
                <input type="number" name="deluxe" placeholder="Deluxe (0 or 1)" required>
                <input type="number" name="maximum_guests" placeholder="Maximum Guests" required>
                <button type="submit">Add Room Type</button>
            </form>
        </section>
        <section id="viewRoomTypes">
            <h2>Room Types List</h2>
            <div id="roomTypeList"></div>
        </section>
    </main>
    <script src="script.js"></script>
</body>
</html>