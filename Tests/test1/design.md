# Design Specification

## System Architecture
The hotel management system will be a three-tier application consisting of:

1.  **Presentation Tier (Front-end):**
    *   Provides the user interface for interacting with the system.
    *   Built using HTML, CSS, and JavaScript.
    *   Will allow receptionists and managers to perform their tasks.
2.  **Application Tier (Back-end):**
    *   Implements the business logic of the system.
    *   Built using Node.js and Express.js.
    *   Handles requests from the front-end and interacts with the database.
3.  **Data Tier (Database):**
    *   Stores the system's data.
    *   Uses a relational database (MySQL) based on the provided database design.

## Class Diagrams
```mermaid
classDiagram
    class Room {
        -room_number: int
        -room_type_code: varchar
        -status: varchar
        -price: decimal
    }
    class Guest {
        -guest_id: int
        -title: varchar
        -first_name: varchar
        -last_name: varchar
        -address_id: int
        -company_id: int
    }
    class Reservation {
        -reservation_id: int
        -guest_id: int
        -room_number: int
        -check_in_date: date
        -check_out_date: date
        -promotion_code: varchar
    }
    class Staff {
        -staff_id: int
        -title: varchar
        -first_name: varchar
        -last_name: varchar
        -role: varchar
    }
    class Complaint {
        -complaint_id: int
        -reservation_id: int
        -category_code: varchar
        -staff_id: int
        -complaint_date: datetime
    }
    class Invoice {
        -invoice_id: int
        -reservation_id: int
        -amount: decimal
        -payment_code: varchar
        -payment_reference: varchar
    }
    Room "1" -- "*" Reservation : books
    Guest "1" -- "*" Reservation : makes
    Staff "1" -- "*" Reservation : processes
    Reservation "1" -- "*" Complaint : has
    Reservation "1" -- "1" Invoice : has
    Guest "0..1" -- "0..*" Guest : company
    
```

## Flowcharts
```mermaid
graph LR
    A[Start] --> B{Check Room Availability};
    B -- Available --> C[Select Room];
    B -- Not Available --> D[End];
    C --> E[Enter Guest Details];
    E --> F[Confirm Reservation];
```

## Pseudocode
(To be added in subsequent steps)

## Justification
This three-tier architecture provides a clear separation of concerns, making the system more maintainable and scalable. The front-end will handle user interactions, the back-end will handle business logic, and the database will handle data storage. This approach aligns with best practices for software development.
