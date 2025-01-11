# Reflective Essay

This essay will discuss the key design, implementation, and testing techniques used in the development of the hotel management system backend.

## Requirements

The requirements for this project were derived from the provided database schema and the user's specifications. The main goal was to create a backend that could handle core functionalities such as room availability, guest reservations, check-ins, check-outs, and guest information retrieval.

## Design

The design of the backend was based on a RESTful API architecture using Node.js and Express.js. The API endpoints were designed to interact with a MySQL database.

## Implementation

The implementation involved setting up a Node.js project, connecting to the MySQL database, and creating API endpoints to handle the required functionalities. The `mysql` and `express` packages were used to facilitate this.

## Testing

The testing phase involved creating unit tests using Jest and Supertest. These tests were designed to verify the functionality of the API endpoints.

## Challenges

One of the main challenges encountered was the authentication error when connecting to the MySQL database. This was resolved by adding the `authSwitchHandler` to the database connection settings. Another challenge was the repeated failures of the `replace_in_file` tool, which was resolved by using `write_to_file` instead.

## Lessons Learned

This project provided valuable experience in developing a backend for a database-driven application. It also highlighted the importance of careful planning, thorough testing, and effective error handling.
