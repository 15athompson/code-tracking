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
            <li><a href="#staff">Staff</a></li>
            <li><a href="#room-types">Room Types</a></li>
            <li><a href="#bathroom-types">Bathroom Types</a></li>
        </ul>
    </nav>
    <main>
        <section id="staff">
            <h2>Staff Management</h2>
            <form id="staff-form">
                <input type="text" name="first_name" placeholder="First Name" required>
                <input type="text" name="last_name" placeholder="Last Name" required>
                <input type="text" name="title" placeholder="Title" required>
                <input type="text" name="role" placeholder="Role" required>
                <input type="number" name="manager_id" placeholder="Manager ID">
                <button type="submit">Add Staff</button>
            </form>
            <div id="staff-list"></div>
        </section>

        <section id="room-types">
            <h2>Room Types Management</h2>
            <form id="room-type-form">
                <input type="text" name="room_type_code" placeholder="Room Type Code" required>
                <input type="text" name="room_type_name" placeholder="Room Type Name" required>
                <input type="number" name="modern_style" placeholder="Modern Style (0 or 1)" required>
                <input type="number" name="deluxe" placeholder="Deluxe (0 or 1)" required>
                <input type="number" name="maximum_guests" placeholder="Maximum Guests" required>
                <button type="submit">Add Room Type</button>
            </form>
            <div id="room-type-list"></div>
        </section>

        <section id="bathroom-types">
            <h2>Bathroom Types Management</h2>
            <form id="bathroom-type-form">
                <input type="text" name="bathroom_type_code" placeholder="Bathroom Type Code" required>
                <input type="text" name="bathroom_type_name" placeholder="Bathroom Type Name" required>
                <button type="submit">Add Bathroom Type</button>
            </form>
            <div id="bathroom-type-list"></div>
        </section>
    </main>
    <script src="script.js"></script>
</body>
</html>