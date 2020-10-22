USE sakila;

SHOW TABLES;


-- What is the proportion of customers that generally hold more than 1 rental at a time (generally rents a second title before the end of rental of the first)?      
    
WITH rental_enriched
AS
(
SELECT
	r.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    ROUND((TIMESTAMPDIFF(HOUR, (LAG (r.rental_date) OVER (PARTITION BY r.customer_id ORDER BY r.rental_date)), 
r.rental_date))/24, 2) AS days_between_rentals,
    ROUND((TIMESTAMPDIFF(HOUR, r.rental_date, r.return_date))/24, 2) AS rental_period
 
FROM
	rental r
    INNER JOIN customer c ON r.customer_id = c.customer_id
),
rental_summary AS
(
SELECT
	customer_id,
    customer_name,
    email,
    AVG(days_between_rentals) AS avg_days_between_rentals,
    AVG(rental_period) AS avg_days_rental_period,
    COUNT(customer_id) AS no_of_rentals
FROM
	rental_enriched
GROUP BY
	customer_id
)
SELECT
customer_id,
customer_name,
email,
avg_days_between_rentals,
avg_days_rental_period,
(CASE WHEN avg_days_between_rentals < avg_days_rental_period THEN 'Multi rentals' ELSE 'Non-Multi rentals' END) AS customer_rental_type
FROM rental_summary
GROUP BY
customer_id;


