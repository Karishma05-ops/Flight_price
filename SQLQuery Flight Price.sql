select * from [dbo].[df_Flights]



----BUSINESS INSIGHTS------

---Q1 Identify Peak Travel Routes (High-Demand Routes)------
SELECT TOP 5 Source, Destination, COUNT(*) AS total_flights
FROM [dbo].[df_Flights]
GROUP BY Source, Destination
ORDER BY total_flights DESC;



--Q2  Find Cheapest Airline for Each Route-----
--- Problem: Airline pricing comparison for specific source-destination routes--
SELECT Source, Destination, Airline, MIN(Price) AS min_price
FROM [dbo].[df_Flights]
GROUP BY Source, Destination, Airline;



---Q3. Detect Price Outliers ---
---Problem: Detect extremely overpriced flights that might need a price correction or are business class.---
WITH RankedFlights AS (
    SELECT *, 
           RANK() OVER (PARTITION BY Source, Destination ORDER BY Price DESC) AS price_rank
    FROM [dbo].[df_Flights]
)
SELECT *
FROM RankedFlights
WHERE price_rank <= 2;



---Q4. Monthly Price Trend----- 
---Problem: Understand seasonality in flight pricing to adjust marketing/promotions.---
SELECT Month, 
       ROUND(AVG(Price), 2) AS avg_price,
       (SELECT ROUND(AVG(Price), 2) FROM [dbo].[df_Flights]) AS overall_avg_price
FROM [dbo].[df_Flights]
GROUP BY Month
ORDER BY Month;




---Q5. Most Common Airlines per Route (Correlated Subquery)---
---Problem: Find dominant airlines on key routes (useful for competition analysis)---
SELECT Source, Destination, Airline, flight_count
FROM (
    SELECT Source, Destination, Airline, COUNT(*) AS flight_count,
           RANK() OVER (PARTITION BY Source, Destination ORDER BY COUNT(*) DESC) AS rnk
    FROM [dbo].[df_Flights]
    GROUP BY Source, Destination, Airline
) AS ranked
WHERE rnk = 1;



---Q6 Delay Inference Based on Duration Outliers (Window Function)----
----Problem: Spot flights that might have experienced longer-than-expected travel time.----
WITH Duration_Clean AS (
    SELECT *,
        -- Extracting hours
        CASE 
            WHEN CHARINDEX('h', Duration) > 0 THEN 
                CAST(SUBSTRING(Duration, 1, CHARINDEX('h', Duration) - 1) AS INT) * 60 
            ELSE 
                0 
        END +
        -- Extracting minutes
        CASE 
            WHEN CHARINDEX('m', Duration) > 0 THEN 
                CAST(SUBSTRING(Duration, CHARINDEX('h', Duration) + 1, CHARINDEX('m', Duration) - CHARINDEX('h', Duration) - 1) AS INT) 
            ELSE 
                0 
        END AS Duration_Minutes
    FROM [dbo].[df_Flights]
    WHERE Duration IS NOT NULL
)
SELECT TOP 10 
       Source,
       Destination,
       AVG(Duration_Minutes) OVER (PARTITION BY Source, Destination) AS avg_route_duration,
       Duration_Minutes - AVG(Duration_Minutes) OVER (PARTITION BY Source, Destination) AS delay_estimation
FROM Duration_Clean
ORDER BY delay_estimation DESC;





---Q7 . Best Performing Airlines by Revenue per Route----
---Identify which airlines generate the highest revenue (Price × Number of Flights) on each route.---
SELECT TOP 10 
       Source, 
       Destination, 
       Airline,
       COUNT(*) AS flight_count,
       SUM(Price) AS total_revenue
FROM [dbo].[df_Flights]
GROUP BY Source, Destination, Airline
ORDER BY total_revenue DESC;




---Q8 Market Share by Airline per Route----
---- Evaluate which airline dominates specific routes by % of flights.----


WITH AirlineCounts AS (
    SELECT Source, Destination, Airline, COUNT(*) AS airline_flights
    FROM [dbo].[df_Flights]
    GROUP BY Source, Destination, Airline
),
TotalRouteCounts AS (
    SELECT Source, Destination, COUNT(*) AS total_flights
    FROM [dbo].[df_Flights]
    GROUP BY Source, Destination
)
SELECT a.Source, a.Destination, a.Airline,
       a.airline_flights,
       t.total_flights,
       ROUND((a.airline_flights * 100.0 / t.total_flights), 2) AS market_share_pct
FROM AirlineCounts a
JOIN TotalRouteCounts t ON a.Source = t.Source AND a.Destination = t.Destination
ORDER BY market_share_pct DESC;




---Q9 Day of Week with Highest Bookings----
---- Identify the busiest travel days by computing which weekday has the most flights.---

SELECT DATENAME(WEEKDAY, CAST(CONCAT(Year, '-', Month, '-', Date) AS DATE)) AS Weekday,
       COUNT(*) AS flight_count
FROM [dbo].[df_Flights]
GROUP BY DATENAME(WEEKDAY, CAST(CONCAT(Year, '-', Month, '-', Date) AS DATE))
ORDER BY flight_count DESC;



---Q10. Hourly Demand Trend (Flight Volume by Hour of Day)---
---Find which departure hours have peak demand (operational use).---

SELECT Departure_hour, COUNT(*) AS total_flights
FROM [dbo].[df_Flights]
GROUP BY Departure_hour
ORDER BY total_flights DESC;






