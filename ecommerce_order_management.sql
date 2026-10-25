CREATE DATABASE EcommerceDB;
USE EcommerceDB;

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    address VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

SHOW TABLES;
DESCRIBE Customers;
USE EcommerceDB;

CREATE TABLE Products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    price DECIMAL(10,2) NOT NULL,
    CHECK (price >= 0)
);

SHOW TABLES;
DESCRIBE Products;

USE EcommerceDB;

CREATE TABLE Inventory (
    inventory_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL UNIQUE,
    stock_quantity INT NOT NULL DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,
    CHECK (stock_quantity >= 0),
    FOREIGN KEY (product_id)
        REFERENCES Products(product_id)
);

SHOW TABLES;
DESCRIBE Inventory;

USE EcommerceDB;

CREATE TABLE Orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    status ENUM(
        'Pending',
        'Processing',
        'Shipped',
        'Delivered',
        'Cancelled'
    ) DEFAULT 'Pending',
    FOREIGN KEY (customer_id)
        REFERENCES Customers(customer_id),
    CHECK (total_amount >= 0)
);

SHOW TABLES;
DESCRIBE Orders;

USE EcommerceDB;

CREATE TABLE Order_Items (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id)
        REFERENCES Orders(order_id),
    FOREIGN KEY (product_id)
        REFERENCES Products(product_id),
    CHECK (quantity > 0),
    CHECK (unit_price >= 0)
);

SHOW TABLES;
DESCRIBE Order_Items;
USE EcommerceDB;
CREATE TABLE Order_Status_History (
    history_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    old_status VARCHAR(20),
    new_status VARCHAR(20) NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id)
        REFERENCES Orders(order_id)
);

SHOW TABLES;
DESCRIBE Order_Status_History;
USE EcommerceDB;

INSERT INTO Customers
(customer_name, email, phone, address)
VALUES
('Antara Pawar', 'antara@example.com',
 '9876543210', 'Pune'),
('Surbhi Patil', 'surbhi@example.com',
 '9876501234', 'Mumbai'),
('Rahul Sharma', 'rahul@example.com',
 '9123456780', 'Nashik');
 
INSERT INTO Products
(product_name, description, price)
VALUES
('Laptop', 'Student laptop', 45000.00),
('Mouse', 'Wireless mouse', 700.00),
('Keyboard', 'USB keyboard', 1200.00),
('Headphones', 'Wired headphones', 1500.00);

INSERT INTO Inventory
(product_id, stock_quantity)
VALUES
(1, 10),
(2, 50),
(3, 30),
(4, 20);

SELECT * FROM Customers;
SELECT * FROM Products;
SELECT * FROM Inventory;
USE EcommerceDB;

SELECT p.product_id, p.product_name,
       i.stock_quantity
FROM Products p
JOIN Inventory i
ON p.product_id = i.product_id;

DELIMITER $$

CREATE TRIGGER Check_And_Update_Stock
BEFORE INSERT ON Order_Items
FOR EACH ROW
BEGIN
    UPDATE Inventory
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE product_id = NEW.product_id
      AND stock_quantity >= NEW.quantity;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Insufficient stock or inventory record missing';
    END IF;
END$$

DELIMITER ;

INSERT INTO Orders
(customer_id, total_amount, status)
VALUES (1, 1400.00, 'Pending');

INSERT INTO Order_Items
(order_id, product_id, quantity, unit_price)
VALUES (LAST_INSERT_ID(), 2, 2, 700.00);

SELECT p.product_name,
       i.stock_quantity
FROM Products p
JOIN Inventory i
ON p.product_id = i.product_id
WHERE p.product_id = 2;


USE EcommerceDB;

START TRANSACTION;

INSERT INTO Orders (customer_id, total_amount, status)
VALUES (1, 0, 'Pending');

SET @new_order_id = LAST_INSERT_ID();

INSERT INTO Order_Items
    (order_id, product_id, quantity, unit_price)
SELECT
    @new_order_id,
    p.product_id,
    1,
    p.price
FROM Products p
JOIN Inventory i ON i.product_id = p.product_id
WHERE p.product_id = 3
  AND i.stock_quantity >= 1;

SET @item_count = ROW_COUNT();

UPDATE Orders o
SET total_amount = (
    SELECT COALESCE(
        SUM(oi.quantity * oi.unit_price), 0
    )
    FROM Order_Items oi
    WHERE oi.order_id = o.order_id
)
WHERE o.order_id = @new_order_id;

COMMIT;

SELECT @new_order_id AS new_order_id;


ROLLBACK;

SELECT order_id, customer_id, total_amount, status
FROM Orders
ORDER BY order_id DESC
LIMIT 5;

SELECT p.product_id, p.product_name, i.stock_quantity
FROM Products p
JOIN Inventory i ON p.product_id = i.product_id;

START TRANSACTION;

INSERT INTO Orders (customer_id, total_amount, status)
VALUES (1, 0, 'Pending');

SET @new_order_id = LAST_INSERT_ID();

SELECT price INTO @unit_price
FROM Products
WHERE product_id = 3;

INSERT INTO Order_Items
    (order_id, product_id, quantity, unit_price)
VALUES
    (@new_order_id, 3, 1, @unit_price);
    
UPDATE Orders
SET total_amount = (
    SELECT COALESCE(
        SUM(quantity * unit_price), 0
    )
    FROM Order_Items
    WHERE order_id = @new_order_id
)
WHERE order_id = @new_order_id;

COMMIT;

SELECT * FROM Orders
WHERE order_id = @new_order_id;

SELECT * FROM Order_Items
WHERE order_id = @new_order_id;

SELECT p.product_name, i.stock_quantity
FROM Products p
JOIN Inventory i ON p.product_id = i.product_id
WHERE p.product_id = 3;
START TRANSACTION;

INSERT INTO Orders (customer_id, total_amount, status)
VALUES (1, 0, 'Pending');

SET @new_order_id = LAST_INSERT_ID();
SELECT price INTO @unit_price
FROM Products
WHERE product_id = 3;

INSERT INTO Order_Items
    (order_id, product_id, quantity, unit_price)
VALUES
    (@new_order_id, 3, 1, @unit_price);
    UPDATE Orders
SET total_amount = (
    SELECT COALESCE(SUM(quantity * unit_price), 0)
    FROM Order_Items
    WHERE order_id = @new_order_id
)
WHERE order_id = @new_order_id;
COMMIT;
SELECT * 
FROM Orders
ORDER BY order_id DESC
LIMIT 5;

SELECT *
FROM Order_Items
ORDER BY order_item_id DESC
LIMIT 5;

SELECT p.product_name, i.stock_quantity
FROM Products p
JOIN Inventory i
ON p.product_id = i.product_id;



USE EcommerceDB;
DROP TRIGGER IF EXISTS Track_Order_Status;

DELIMITER $$

CREATE TRIGGER Track_Order_Status
AFTER UPDATE ON Orders
FOR EACH ROW
BEGIN
    -- Record order status changes
    IF OLD.status <> NEW.status THEN

        INSERT INTO Order_Status_History
            (order_id, old_status, new_status)
        VALUES
            (NEW.order_id, OLD.status, NEW.status);

        -- Restore stock when an order is cancelled
        IF OLD.status <> 'Cancelled'
           AND NEW.status = 'Cancelled' THEN

            UPDATE Inventory AS i
            JOIN Order_Items AS oi
                ON i.product_id = oi.product_id
            SET i.stock_quantity =
                i.stock_quantity + oi.quantity
            WHERE oi.order_id = NEW.order_id;

        END IF;

    END IF;
END$$

DELIMITER ;


UPDATE Orders
SET status = 'Shipped'
WHERE order_id = @new_order_id;
SELECT *
FROM Order_Status_History
ORDER BY history_id DESC;


SELECT
    c.customer_name,
    o.order_id,
    o.order_date,
    o.total_amount,
    o.status
FROM Customers AS c
JOIN Orders AS o
    ON c.customer_id = o.customer_id
ORDER BY o.order_date DESC;


SELECT
    p.product_id,
    p.product_name,
    i.stock_quantity
FROM Products AS p
JOIN Inventory AS i
    ON p.product_id = i.product_id
WHERE i.stock_quantity < 10
ORDER BY i.stock_quantity ASC;


SELECT
    c.customer_id,
    c.customer_name,
    SUM(o.total_amount) AS total_sales
FROM Customers AS c
JOIN Orders AS o
    ON c.customer_id = o.customer_id
WHERE o.status <> 'Cancelled'
GROUP BY c.customer_id, c.customer_name
ORDER BY total_sales DESC;

USE EcommerceDB;
SELECT
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.quantity * oi.unit_price) AS total_sales
FROM Products AS p
JOIN Order_Items AS oi
    ON p.product_id = oi.product_id
JOIN Orders AS o
    ON oi.order_id = o.order_id
WHERE o.status <> 'Cancelled'
GROUP BY p.product_id, p.product_name
ORDER BY total_sales DESC;


SELECT
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_quantity_sold
FROM Products AS p
JOIN Order_Items AS oi
    ON p.product_id = oi.product_id
JOIN Orders AS o
    ON oi.order_id = o.order_id
WHERE o.status <> 'Cancelled'
GROUP BY p.product_id, p.product_name
ORDER BY total_quantity_sold DESC
LIMIT 1;


SELECT
    o.order_id,
    c.customer_name,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) AS subtotal,
    o.status
FROM Orders AS o
JOIN Customers AS c
    ON o.customer_id = c.customer_id
JOIN Order_Items AS oi
    ON o.order_id = oi.order_id
JOIN Products AS p
    ON oi.product_id = p.product_id
ORDER BY o.order_id DESC;


SELECT
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS total_orders
FROM Customers AS c
LEFT JOIN Orders AS o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_orders DESC;


CREATE OR REPLACE VIEW Order_Details_View AS
SELECT
    o.order_id,
    c.customer_name,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) AS subtotal,
    o.order_date,
    o.status
FROM Orders AS o
JOIN Customers AS c
    ON o.customer_id = c.customer_id
JOIN Order_Items AS oi
    ON o.order_id = oi.order_id
JOIN Products AS p
    ON oi.product_id = p.product_id;


SELECT * FROM Order_Details_View;



USE EcommerceDB;

DROP PROCEDURE IF EXISTS Update_Order_Status;

DELIMITER $$

CREATE PROCEDURE Update_Order_Status(
    IN p_order_id INT,
    IN p_new_status VARCHAR(20)
)
BEGIN
    UPDATE Orders
    SET status = p_new_status
    WHERE order_id = p_order_id;
END$$

DELIMITER ;

CALL Update_Order_Status(1, 'Processing');


SELECT
    order_id,
    customer_id,
    total_amount,
    status
FROM Orders
WHERE order_id = 1;

SELECT
    order_id,
    old_status,
    new_status,
    changed_at
FROM Order_Status_History
WHERE order_id = 1
ORDER BY history_id DESC;



USE EcommerceDB;

DROP PROCEDURE IF EXISTS Get_Customer_Orders;

DELIMITER $$

CREATE PROCEDURE Get_Customer_Orders(
    IN p_customer_id INT
)
BEGIN
    SELECT
        o.order_id,
        c.customer_name,
        o.order_date,
        o.total_amount,
        o.status
    FROM Orders AS o
    JOIN Customers AS c
        ON o.customer_id = c.customer_id
    WHERE o.customer_id = p_customer_id
    ORDER BY o.order_date DESC;
END$$

DELIMITER ;

CALL Get_Customer_Orders(1);


USE EcommerceDB;

CREATE OR REPLACE VIEW Inventory_Status_View AS
SELECT
    p.product_id,
    p.product_name,
    p.price,
    i.stock_quantity,
    CASE
        WHEN i.stock_quantity = 0 THEN 'Out of Stock'
        WHEN i.stock_quantity < 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM Products AS p
JOIN Inventory AS i
    ON p.product_id = i.product_id;

SELECT * FROM Inventory_Status_View;


SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS sales_month,
    SUM(total_amount) AS monthly_sales,
    COUNT(order_id) AS total_orders
FROM Orders
WHERE status <> 'Cancelled'
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY sales_month DESC;


SELECT
    c.customer_id,
    c.customer_name,
    c.email
FROM Customers AS c
LEFT JOIN Orders AS o
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;


SELECT
    o.order_id,
    c.customer_name,
    o.total_amount,
    o.status
FROM Orders AS o
JOIN Customers AS c
    ON o.customer_id = c.customer_id
WHERE o.status <> 'Cancelled'
ORDER BY o.total_amount DESC
LIMIT 1;


SELECT
    SUM(total_amount) AS total_revenue,
    COUNT(order_id) AS total_orders
FROM Orders
WHERE status <> 'Cancelled';


SELECT
    o.order_id,
    o.status,
    p.product_name,
    oi.quantity,
    i.stock_quantity
FROM Orders AS o
JOIN Order_Items AS oi
    ON o.order_id = oi.order_id
JOIN Products AS p
    ON oi.product_id = p.product_id
JOIN Inventory AS i
    ON p.product_id = i.product_id
WHERE o.status <> 'Cancelled'
ORDER BY o.order_id DESC;



SELECT order_id, status
FROM Orders
WHERE status <> 'Cancelled'
ORDER BY order_id DESC;

SELECT order_id, customer_id, total_amount, status
FROM Orders
ORDER BY order_id DESC;

SELECT order_id, customer_id, total_amount, status
FROM Orders
ORDER BY order_id DESC;

UPDATE Orders
SET status = 'Cancelled'
WHERE order_id = 3
  AND status = 'Pending';
  
  
  
  SELECT
    order_id,
    status
FROM Orders
WHERE order_id = 3;

SELECT
    p.product_name,
    i.stock_quantity
FROM Products AS p
JOIN Inventory AS i
    ON p.product_id = i.product_id
JOIN Order_Items AS oi
    ON p.product_id = oi.product_id
WHERE oi.order_id = 3;

SELECT
    order_id,
    old_status,
    new_status,
    changed_at
FROM Order_Status_History
WHERE order_id = 3
ORDER BY history_id DESC;

SELECT
    p.product_name,
    oi.quantity AS cancelled_quantity,
    i.stock_quantity AS current_stock
FROM Order_Items AS oi
JOIN Products AS p
    ON oi.product_id = p.product_id
JOIN Inventory AS i
    ON p.product_id = i.product_id
WHERE oi.order_id = 3;

USE EcommerceDB;

SHOW TABLES;
USE EcommerceDB;

SHOW TRIGGERS;

USE EcommerceDB;

USE EcommerceDB;

SHOW FULL TABLES
WHERE Table_type = 'VIEW';



USE EcommerceDB;

-- 1. Check total customers
SELECT COUNT(*) AS total_customers
FROM Customers;

-- 2. Check total products
SELECT COUNT(*) AS total_products
FROM Products;

-- 3. Check total orders
SELECT COUNT(*) AS total_orders
FROM Orders;

-- 4. Display current inventory
SELECT
    p.product_name,
    i.stock_quantity
FROM Products AS p
JOIN Inventory AS i
    ON p.product_id = i.product_id;

-- 5. Display order status history
SELECT *
FROM Order_Status_History
ORDER BY history_id DESC;

-- 6. Test the order details view
SELECT * FROM Order_Details_View;

-- 7. Test the inventory status view
SELECT * FROM Inventory_Status_View;
















