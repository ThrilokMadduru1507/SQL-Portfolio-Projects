SELECT COUNT(1) AS TOTAL_ROWS FROM ATHLETES;
-- THERE ARE TOTAL 135571 ATHLETES INFORMATION IN THIS TABLE
SELECT COUNT(1) AS TOTAL_ROWS FROM ATHLETES WHERE HEIGHT IS NULL OR WEIGHT IS NULL;
-- THERE ARE TOTAL 35984 ROWS WHERE ATHLETES HEIGHT OR WEIGHT IS NULL

SELECT COUNT(1) AS TOTAL_ROWS FROM ATHLETE_EVENTS;	
-- THERE ARE TOTAL 271116 RECORDS IN THE ATHLETE_EVENTS TABLE
SELECT COUNT(1) AS ROWS_WITH_NULL FROM ATHLETE_EVENTS WHERE MEDAL IS NULL;
-- THERE ARE 231333 ROWS WHERE THE MEDAL FIELD IS NULL

-- 1 WHICH TEAM HAS WON THE MAXIMUM GOLD MEDALS OVER THE YEARS.

SELECT TOP 1 TEAM, COUNT(DISTINCT EVENT) AS TOTAL_GOLDS FROM ATHLETE_EVENTS 
	JOIN ATHLETES ON ATHLETE_EVENTS.ATHLETE_ID = ATHLETES.ID
	WHERE MEDAL = 'Gold' GROUP BY TEAM ORDER BY TOTAL_GOLDS DESC;

-- 2 FOR EACH TEAM PRINT TOTAL SILVER MEDALS AND YEAR IN WHICH THEY WON MAXIMUM SILVER MEDAL..OUTPUT 3 COLUMNS
-- TEAM,TOTAL_SILVER_MEDALS, YEAR_OF_MAX_SILVER

WITH SILVERS_WON AS (
SELECT TEAM, YEAR, COUNT(DISTINCT EVENT) AS SILVERS_WON, 
	RANK() OVER(PARTITION BY TEAM ORDER BY COUNT(DISTINCT EVENT) DESC) AS SI_RNK 
	FROM ATHLETE_EVENTS 
	JOIN ATHLETES ON ATHLETE_EVENTS.ATHLETE_ID = ATHLETES.ID
	WHERE MEDAL = 'Silver' GROUP BY TEAM,YEAR)

	SELECT TEAM, SUM(SILVERS_WON) AS TOTAL_SILVERS, MAX(CASE WHEN SI_RNK = 1 THEN YEAR END) AS MAX_SIL_WON_IN
	FROM SILVERS_WON GROUP BY TEAM
	ORDER BY TEAM ASC;

-- 3 WHICH PLAYER HAS WON MAXIMUM GOLD MEDALS  AMONGST THE PLAYERS  WHICH HAVE WON ONLY GOLD MEDAL (NEVER WON SILVER OR BRONZE) OVER THE YEARS

WITH ONLY_GOLDS AS
(
	SELECT B.ID AS ID, B.NAME AS NAME
	FROM ATHLETE_EVENTS A JOIN ATHLETES B 
	ON A.ATHLETE_ID = B.ID
	WHERE A.MEDAL = 'Gold'
	AND A.ATHLETE_ID NOT IN (SELECT ATHLETE_ID FROM ATHLETE_EVENTS WHERE MEDAL IN ('Silver','Bronze'))
)
SELECT TOP 1 NAME, COUNT(NAME) AS GOLDS_WON FROM ONLY_GOLDS GROUP BY NAME ORDER BY COUNT(NAME) DESC;


-- 4 IN EACH YEAR WHICH PLAYER HAS WON MAXIMUM GOLD MEDAL . WRITE A QUERY TO PRINT YEAR,PLAYER NAME 
-- AND NO OF GOLDS WON IN THAT YEAR . IN CASE OF A TIE PRINT COMMA SEPARATED PLAYER NAMES.


WITH GOLDS_WON AS (
	SELECT 
		A.NAME AS PLAYER_NAME, B.YEAR AS YEAR_PLAYED, COUNT(DISTINCT EVENT) AS GOLD_WON 
		FROM ATHLETES A JOIN ATHLETE_EVENTS B 
		ON A.ID = B.ATHLETE_ID 
		WHERE MEDAL = 'Gold' 
		GROUP BY A.NAME, B.YEAR
),

MAX_GOLDS_WON AS (
	SELECT
		YEAR_PLAYED,
		PLAYER_NAME,
		GOLD_WON,
		RANK() OVER(PARTITION BY YEAR_PLAYED ORDER BY GOLD_WON DESC) AS PLAY_RANK
		FROM GOLDS_WON
)

SELECT YEAR_PLAYED, GOLD_WON,
	STRING_AGG(PLAYER_NAME, ',  ') AS PLAYERS
	FROM MAX_GOLDS_WON 
	WHERE PLAY_RANK = 1
	GROUP BY YEAR_PLAYED, GOLD_WON
	ORDER BY YEAR_PLAYED ASC;

--5 IN WHICH EVENT AND YEAR INDIA HAS WON ITS FIRST GOLD MEDAL,FIRST SILVER MEDAL AND FIRST BRONZE MEDAL
--PRINT 3 COLUMNS MEDAL,YEAR,SPORT

WITH FIRST_WON_DETAILS AS (
SELECT 
	TEAM, MEDAL, 
	YEAR AS FIRST_WON_ON,
	ROW_NUMBER() OVER(PARTITION BY TEAM, MEDAL ORDER BY YEAR) AS RN
	FROM ATHLETES JOIN ATHLETE_EVENTS 
	ON ID = ATHLETE_ID
	WHERE TEAM = 'India' AND MEDAL IS NOT NULL
	GROUP BY TEAM, MEDAL, YEAR
)

SELECT TEAM, MEDAL, FIRST_WON_ON FROM FIRST_WON_DETAILS WHERE RN = 1;


-- 6 FIND PLAYERS WHO WON GOLD MEDAL IN SUMMER AND WINTER OLYMPICS BOTH.

SELECT NAME FROM ATHLETES A INNER JOIN ATHLETE_EVENTS B ON A.ID = B.ATHLETE_ID
WHERE MEDAL = 'Gold'
GROUP BY NAME
HAVING COUNT(DISTINCT SEASON) = 2;


-- 7 FIND PLAYERS WHO WON GOLD, SILVER AND BRONZE MEDAL IN A SINGLE OLYMPICS. PRINT PLAYER NAME ALONG WITH YEAR.

WITH ALL_MEDALS AS (
SELECT ATHLETE_ID, YEAR, SEASON, 
	COUNT(DISTINCT MEDAL) AS ALL_MEDALS_WON
	FROM ATHLETE_EVENTS 
	WHERE MEDAL IS NOT NULL 
	GROUP BY ATHLETE_ID, YEAR, SEASON 
	HAVING COUNT(DISTINCT MEDAL) = 3)
	
SELECT ATHLETES.NAME, ALL_MEDALS.YEAR
FROM ATHLETES JOIN ALL_MEDALS
ON ATHLETES.ID = ALL_MEDALS.ATHLETE_ID 
ORDER BY NAME;

-- 8 FIND PLAYERS WHO HAVE WON GOLD MEDALS IN CONSECUTIVE 3 SUMMER OLYMPICS IN THE SAME EVENT . CONSIDER ONLY OLYMPICS 2000 ONWARDS. 
-- ASSUME SUMMER OLYMPICS HAPPENS EVERY 4 YEAR STARTING 2000. PRINT PLAYER NAME AND EVENT NAME.

WITH CSO AS (
	SELECT *,
		CASE
		WHEN YEAR > 2000
		THEN
		LAG(MEDAL) OVER(PARTITION BY ATHLETE_ID, ATHLETE_EVENTS.EVENT ORDER BY YEAR) END AS PREVIOUS_MEDAL,
		MEDAL AS CURRENT_MEDAL,
		LEAD(MEDAL) OVER(PARTITION BY ATHLETE_ID, ATHLETE_EVENTS.EVENT ORDER BY YEAR) AS NEXT_MEDAL
		FROM ATHLETE_EVENTS 
		WHERE YEAR >= 2000 
		AND MEDAL = 'Gold' 
		AND SEASON = 'Summer' 
),

CSO_ATHLETES AS (
	SELECT 
		ATHLETE_ID 
		FROM CSO 
		WHERE PREVIOUS_MEDAL = 'Gold' 
		AND CURRENT_MEDAL = 'Gold' 
		AND NEXT_MEDAL = 'Gold'
)

SELECT DISTINCT NAME FROM ATHLETES JOIN CSO_ATHLETES ON ATHLETES.ID = CSO_ATHLETES.ATHLETE_ID;