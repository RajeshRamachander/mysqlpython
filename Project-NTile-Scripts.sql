-- cd /Users/ralphonseraj/Desktop
-- mysql -uroot -p --local-infile
-- mysql> create database sakila;
-- mysql> use sakila;
-- SOURCE /Users/ralphonseraj/Desktop/M.Tech-DSML-PES-Univ/Databases And SQL/Assessments/Project/mysqlpython-master/mysqlpython-master/sakila-schema.sql;
-- SOURCE /Users/ralphonseraj/Desktop/M.Tech-DSML-PES-Univ/Databases And SQL/Assessments/Project/mysqlpython-master/mysqlpython-master/sakila-data.sql;

show tables;

-- Which genres are most promising to invest based on current revenue?
 /* 
	1. Sports
	2. Sci-Fi
    3. Animation
    4. Drama
*/

WITH CTE
AS
(
SELECT 
	c.name AS category_name,
    COUNT(r.rental_id) AS rental_count,
    SUM(p.amount) AS earnings
FROM
	film AS f
    LEFT OUTER JOIN film_category AS fc ON f.film_id = fc.film_id
    LEFT OUTER JOIN category AS c ON fc.category_id = c.category_id
    LEFT OUTER JOIN inventory AS i ON f.film_id = i.film_id
    LEFT OUTER JOIN rental AS r ON i.inventory_id = r.inventory_id
    LEFT OUTER JOIN payment AS p ON r.rental_id = p.rental_id
GROUP BY
	c.name
)
SELECT
	category_name,
    earnings,
    NTILE(4) OVER(ORDER BY earnings DESC) AS bucket
FROM
	CTE;

-- Classify actors into buckets of most rented (demand)?

WITH CTE
AS
(
SELECT 
	CONCAT(a.first_name, ' ', a.last_name) AS actor_name,
    COUNT(r.rental_id) AS rental_count
FROM
	actor AS a
    LEFT OUTER JOIN film_actor AS fa ON a.actor_id = fa.film_id
    LEFT OUTER JOIN film AS f ON fa.film_id = f.film_id
    LEFT OUTER JOIN inventory AS i ON f.film_id = i.film_id
    LEFT OUTER JOIN rental AS r ON i.inventory_id = r.inventory_id
GROUP BY
	CONCAT(a.first_name, ' ', a.last_name)
)
SELECT
	actor_name,
    rental_count,
    NTILE(5) OVER(ORDER BY rental_count DESC) AS bucket
FROM
	CTE;

-- Which actors are most promising to invest based on current earnings?
/*
Most promising Actor List - Top list and their earnings in terms of rental amount
'GROUCHO WILLIAMS','1230.75','1'
'RUSSELL BACALL','1134.32','1'
'FRANCES DAY-LEWIS','1111.67','1'
*/

WITH CTE
AS
(
SELECT 
	CONCAT(a.first_name, ' ', a.last_name) AS actor_name,
    SUM(p.amount) AS earnings
FROM
	actor AS a
    LEFT OUTER JOIN film_actor AS fa ON a.actor_id = fa.film_id
    LEFT OUTER JOIN film AS f ON fa.film_id = f.film_id
    LEFT OUTER JOIN inventory AS i ON f.film_id = i.film_id
    LEFT OUTER JOIN rental AS r ON i.inventory_id = r.inventory_id
    LEFT OUTER JOIN payment AS p ON r.rental_id = p.rental_id
GROUP BY
	CONCAT(a.first_name, ' ', a.last_name)
)
SELECT
	actor_name,
    earnings,
    NTILE(5) OVER(ORDER BY earnings DESC) AS bucket
FROM
	CTE;

-- Bucket list of movies based on ratings and best earnings?

WITH CTE
AS
(
SELECT
	f.rating,
	f.title AS film_name,
    SUM(p.amount) AS earnings
FROM
	actor AS a
    LEFT OUTER JOIN film_actor AS fa ON a.actor_id = fa.film_id
    LEFT OUTER JOIN film AS f ON fa.film_id = f.film_id
    LEFT OUTER JOIN inventory AS i ON f.film_id = i.film_id
    LEFT OUTER JOIN rental AS r ON i.inventory_id = r.inventory_id
    LEFT OUTER JOIN payment AS p ON r.rental_id = p.rental_id
GROUP BY
	f.rating,
	f.title
)
SELECT
	rating,
    film_name,
    earnings,
    NTILE(5) OVER(PARTITION BY rating ORDER BY earnings DESC) AS bucket
FROM
	CTE;
