-- Use the Sakila database
USE sakila;

-- Challenge 1: Ranking Films
-- 1. Rank films by their length, excluding null or zero values
SELECT title, length,
       RANK() OVER (ORDER BY length DESC) AS rank_position
FROM film
WHERE length IS NOT NULL AND length > 0;

-- 2. Rank films by length within their rating category, excluding null or zero values
SELECT title, length, rating,
       RANK() OVER (PARTITION BY rating ORDER BY length DESC) AS rank_position
FROM film
WHERE length IS NOT NULL AND length > 0;

-- 3. Identify the actor/actress who has acted in the most films
WITH actor_film_count AS (
    SELECT actor_id, COUNT(film_id) AS total_films
    FROM film_actor
    GROUP BY actor_id
), 
most_prolific_actor AS (
    SELECT actor_id FROM actor_film_count
    ORDER BY total_films DESC
    LIMIT 1
)
SELECT a.actor_id, a.first_name, a.last_name, afc.total_films
FROM actor a
JOIN actor_film_count afc ON a.actor_id = afc.actor_id
WHERE a.actor_id = (SELECT actor_id FROM most_prolific_actor);

-- Challenge 2: Customer Activity and Retention Analysis
-- 1. Retrieve the number of monthly active customers
WITH monthly_customers AS (
    SELECT DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
           COUNT(DISTINCT customer_id) AS active_customers
    FROM rental
    GROUP BY rental_month
)
SELECT * FROM monthly_customers;

-- 2. Retrieve the number of active users in the previous month
WITH monthly_customers AS (
    SELECT DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
           COUNT(DISTINCT customer_id) AS active_customers
    FROM rental
    GROUP BY rental_month
)
SELECT mc1.rental_month, mc1.active_customers,
       LAG(mc1.active_customers) OVER (ORDER BY mc1.rental_month) AS previous_month_customers
FROM monthly_customers mc1;

-- 3. Calculate the percentage change in active customers between current and previous month
WITH monthly_customers AS (
    SELECT DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
           COUNT(DISTINCT customer_id) AS active_customers
    FROM rental
    GROUP BY rental_month
)
SELECT mc1.rental_month, mc1.active_customers,
       LAG(mc1.active_customers) OVER (ORDER BY mc1.rental_month) AS previous_month_customers,
       ROUND((mc1.active_customers - LAG(mc1.active_customers) OVER (ORDER BY mc1.rental_month)) / NULLIF(LAG(mc1.active_customers) OVER (ORDER BY mc1.rental_month), 0) * 100, 2) AS percentage_change
FROM monthly_customers mc1;

-- 4. Calculate the number of retained customers every month
WITH current_month AS (
    SELECT DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
           customer_id
    FROM rental
    GROUP BY rental_month, customer_id
),
previous_month AS (
    SELECT customer_id,
           DATE_FORMAT(rental_date, '%Y-%m') AS rental_month
    FROM rental
    GROUP BY rental_month, customer_id
)
SELECT cm.rental_month, COUNT(DISTINCT cm.customer_id) AS retained_customers
FROM current_month cm
JOIN previous_month pm ON cm.customer_id = pm.customer_id AND DATE_SUB(cm.rental_month, INTERVAL 1 MONTH) = pm.rental_month
GROUP BY cm.rental_month;
