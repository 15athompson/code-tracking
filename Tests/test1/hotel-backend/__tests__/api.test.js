const request = require('supertest');
const app = require('../index');

describe('API Endpoints', () => {
  it('should return 200 for /', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toEqual(200);
  });

  it('should return 200 for /rooms', async () => {
    const res = await request(app).get('/rooms');
    expect(res.statusCode).toEqual(200);
  });

  it('should return 201 for /reservations', async () => {
    const res = await request(app)
      .post('/reservations')
      .send({
        guest_id: 1,
        room_id: 1,
        check_in_date: '2024-12-01',
        check_out_date: '2024-12-05',
      });
    expect(res.statusCode).toEqual(201);
  });

  it('should return 200 for /checkin/:reservation_id', async () => {
    const res = await request(app)
      .put('/checkin/1')
      .send({
        staff_id: 1,
        check_in_time: '2024-12-01 14:00:00',
      });
    expect(res.statusCode).toEqual(200);
  });

    it('should return 200 for /checkout/:reservation_id', async () => {
    const res = await request(app)
      .put('/checkout/1')
      .send({
        staff_id: 1,
        check_out_time: '2024-12-05 11:00:00',
      });
    expect(res.statusCode).toEqual(200);
  });

  it('should return 200 for /guests/:guest_id', async () => {
    const res = await request(app).get('/guests/1');
    expect(res.statusCode).toEqual(200);
  });
});
