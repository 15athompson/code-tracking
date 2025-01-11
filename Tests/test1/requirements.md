# Requirements Specification

## Introduction
This document outlines the requirements for a hotel management system. The system will manage hotel rooms, reservations, guests, staff, and other related information. It will replace a paper-based system currently used by the hotel.

## Functional Requirements
The system must:

*   **Room Management:**
    *   Allow receptionists to view room availability.
    *   Allow management to maintain a room cleaning rota.
    *   Track room types, features, and pricing.
*   **Guest Management:**
    *   Support guest registration, check-in, and check-out.
    *   Manage guest details, including contact information and company affiliations.
    *   Allow guests to make reservations.
    *   Support a guest/company relationship.
*   **Reservation Management:**
    *   Manage room bookings, including check-in and check-out information.
    *   Record reservation history.
    *   Apply promotional discounts to reservations.
*   **Complaint Management:**
    *   Log guest complaints.
    *   Allow management to find patterns in complaints.
*   **Reporting:**
    *   Report on reservation history and promotion usage.
    *   Generate a marketing list.
    *   Report on total revenue by room type and occupancy.
*   **Staff Management:**
    *   Manage staff details, including roles and manager assignments.
    *   Track staff activities related to reservations, check-ins, check-outs, and complaints.
*   **Invoice Management:**
    *   Generate invoices for reservations.
    *   Record payment information.

## Non-Functional Requirements
The system must:

*   **Security:**
    *   Comply with the Data Protection Act (DPA, 2018) and GDPR.
    *   Protect sensitive guest and company information.
    *   Implement access control based on staff roles.
    *   Use encryption to secure data.
    *   Implement a strict password policy.
    *   Regularly backup data.
*   **Performance:**
    *   Provide efficient data manipulation and retrieval.
    *   Use indexes to improve query performance.
*   **Usability:**
    *   Provide a user-friendly interface for receptionists and other staff.
*   **Maintainability:**
    *   Be designed with modularity and maintainability in mind.
    *   Use clear and well-documented code.
*   **Scalability:**
    *   Be able to handle a growing number of rooms, guests, and reservations.

## Use Cases
*   **View Room Availability:** A receptionist views available rooms for a given date range.
*   **Make a Reservation:** A receptionist makes a reservation for a guest.
*   **Check-in a Guest:** A receptionist checks in a guest.
*   **Check-out a Guest:** A receptionist checks out a guest.
*   **Log a Complaint:** A receptionist logs a guest complaint.
*   **Generate a Report:** A manager generates a report on reservation history.
*   **Maintain Room Cleaning Rota:** A manager maintains the room cleaning rota.

## Data Models
The system will use the relational database design provided in the database project, including tables for rooms, guests, reservations, staff, complaints, invoices, and other related entities.

## Justification
These requirements are based on the provided assignment brief, the database project, and the identified needs of a hotel management system. The functional requirements cover the core functionalities of the system, while the non-functional requirements ensure the system is secure, performant, usable, maintainable, and scalable. The use cases provide a high-level overview of how users will interact with the system.
