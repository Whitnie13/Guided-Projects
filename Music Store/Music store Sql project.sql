-- 1. Who is the senior most employee based on job title?
SELECT * FROM employee
ORDER BY levels DESC 
LIMIT 1;

-- 2. Which countries have the most invoices?
SELECT COUNT(*) AS c, billing_country 
FROM invoice
GROUP BY 2
ORDER BY 1 DESC;

-- 3. What are top 3 values of total invoice?
SELECT * FROM invoice
ORDER BY total DESC
LIMIT 3;

/* 4. Which city has the best customers? write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */
SELECT SUM(totaL) AS invoice_total, billing_city
FROM invoice
GROUP BY 2
ORDER BY 1 DESC;

/* 5. Who is the best customer? The customer who has spent the most money will be declared the best customer.  
Write a query that returns the person who has spent the most money */
SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) AS invoice_total
FROM customer c
JOIN invoice i 
ON i.customer_id = c.customer_id
GROUP BY 1
ORDER BY 4 DESC
LIMIT 1;

/* 6. Write a query to return the email, first name, last name, & genre of all Rock Music listeners.
Return your list ordered alphabetically by email starting with A */
SELECT DISTINCT c.email,c.first_name, c.last_name 
FROM customer c
JOIN invoice i ON i.customer_id = c.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
WHERE track_id IN (
	SELECT track_id FROM track t
	JOIN genre g ON t.genre_id = g.genre_id 
	WHERE g.name LIKE 'Rock'
)
ORDER BY c.email;
-- Use this one answer 
SELECT DISTINCT c.email,c.first_name, c.last_name ,g.name AS genre
FROM customer c
JOIN invoice i ON i.customer_id = c.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN genre g ON g.genre_id = t.genre_id
WHERE g.name LIKE 'Rock'
ORDER BY c.email;

-- 7.Write a query that returns the artist name and total track count of the top 10 rock bands 
SELECT ar.artist_id, ar.name, COUNT (ar.artist_id) AS number_of_songs 
FROM track t
JOIN album al ON al.album_id = t.album_id
JOIN artist ar ON ar.artist_id = al.artist_id
JOIN genre g ON g.genre_id = t.genre_id
WHERE g.name LIKE 'Rock'
GROUP BY 1
ORDER BY 3
LIMIT 10;

/* 8.Return all the track names that have a song length longer than the average song length. 
Return the name and milliseconds for each track. Order by the song length with the longest songs listed first */
SELECT name, milliseconds 
FROM track
WHERE milliseconds > (
      SELECT AVG(milliseconds) AS avg_track_length
	  FROM track 
)
ORDER BY 2 DESC;
-- alternative
SELECT name, milliseconds 
FROM track
WHERE milliseconds > 393599
ORDER BY 2 DESC;

/* 9.Find how much amount spent by each customer on artists? 
Write a query to return customer name, artist name and total spent */
-- Using CTE
WITH best_selling_artist AS (
   SELECT a.artist_id, a.name, SUM(il.unit_price * il.quantity) AS total_sales 
	FROM invoice_line il
	JOIN track t ON t.track_id = il.track_id
	JOIN album al ON al.album_id = t.album_id
	JOIN artist a  ON a.artist_id = al.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c. customer_id, c.first_name, c.last_name, b.name AS artist, SUM(il.unit_price * il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id 
JOIN track t ON t.track_id = il.track_id
JOIN album al ON al.album_id = t.album_id 
JOIN best_selling_artist b ON b.artist_id = al.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

/* 10. Write a query that returns each country along with the top genre. 
For countries where the highest number of purchases is shared return all genres */
WITH popular_genre AS (
     SELECT COUNT(il.quantity) AS purchases, c.country,g.name, g.genre_id, 
	 ROW_NUMBER() OVER (PARTITION BY c.country ORDER BY COUNT(il.quantity) DESC) AS row_num
	 FROM invoice_line il
	 JOIN invoice i ON i.invoice_id = il.invoice_id
	 JOIN customer c ON c.customer_id = i.customer_id
	 JOIN track t ON t.track_id = il.track_id
	 JOIN genre g ON g.genre_id = t.genre_id
	 GROUP BY 2,3,4
	 ORDER BY 2, 1 DESC
)  
SELECT * FROM popular_genre 
WHERE row_num <= 1;

/* Method 2: : Using Recursive */

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;


/* 11. Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Method 1: using CTE */

WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS Row_num 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE Row_num <= 1;

/* Method 2: Using Recursive */
WITH RECURSIVE 
	customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;