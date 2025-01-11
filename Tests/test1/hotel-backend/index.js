const express = require('express');
const mysql = require('mysql');

const app = express();
const port = 3000;

app.use(express.json());

// Database connection
const db = mysql.createConnection({
  host: '127.0.0.1:3306',
  user: 'root',
  password: '23Mar004',
  database: 'Hotel_DB',
  authSwitchHandler: function ({pluginName}, cb) {
    if (pluginName === 'mysql_native_password') {
      cb(null, Buffer.from('23Mar004\0', 'ascii'))
    }
  }
});

db.connect((err) => {
  if (err) {
    console.error('Error connecting to database:', err);
    return;
  }
  console.log('Connected to database');
});

app.get('/', (req, res) => {
  res.send('Hello World!');
});

app.get('/rooms', (req, res) => {
  db.query('SELECT * FROM room', (err, results) => {
    if (err) {
      console.error('Error querying database:', err);
      res.status(500).send('Error fetching rooms');
      return;
    }
    res.json(results);
  });
});

app.post('/reservations', (req, res) => {
  const { guest_id, room_id, check_in_date, check_out_date } = req.body;
  const query = 'INSERT INTO reservation (guest_id, room_id, check_in_date, check_out_date) VALUES (?, ?, ?, ?)';
  db.query(query, [guest_id, room_id, check_in_date, check_out_date], (err, result) => {
    if (err) {
      console.error('Error creating reservation:', err);
      res.status(500).send('Error creating reservation');
      return;
    }
    res.status(201).send('Reservation created successfully');
  });
});

app.put('/checkin/:reservation_id', (req, res) => {
  const { reservation_id } = req.params;
  const { staff_id, check_in_time } = req.body;
  const query = 'INSERT INTO check_in (reservation_id, staff_id, check_in_time) VALUES (?, ?, ?)';
  db.query(query, [reservation_id, staff_id, check_in_time], (err, result) => {
    if (err) {
      console.error('Error creating check-in:', err);
      res.status(500).send('Error creating check-in');
      return;
    }
    res.status(200).send('Check-in recorded successfully');
  });
});

app.put('/checkout/:reservation_id', (req, res) => {
  const { reservation_id } = req.params;
  const { staff_id, check_out_time } = req.body;
  const query = 'INSERT INTO check_out (reservation_id, staff_id, check_out_time) VALUES (?, ?, ?)';
  db.query(query, [reservation_id, staff_id, check_out_time], (err, result) => {
    if (err) {
      console.error('Error creating check-out:', err);
      res.status(500).send('Error creating check-out');
      return;
    }
    res.status(200).send('Check-out recorded successfully');
  });
});

app.get('/guests/:guest_id', (req, res) => {
  const { guest_id } = req.params;
  const query = 'SELECT * FROM guest WHERE guest_id = ?';
  db.query(query, [guest_id], (err, results) => {
    if (err) {
      console.error('Error fetching guest:', err);
      res.status(500).send('Error fetching guest');
      return;
    }
    res.json(results);
  });
});

app.listen(port, () => {
  console.log(`Server listening at http://localhost:${port}`);
});
