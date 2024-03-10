CREATE DATABASE hr;
USE hr;

--  Inspecting and cleaning data

 SELECT * 
 FROM hr_data

SELECT termdate
FROM hr_data
ORDER BY termdate DESC;

UPDATE hr_data  -- convert termdate to correct format
SET termdate = FORMAT(CONVERT(DATETIME, LEFT(termdate, 19), 120), 'yyyy-MM-dd')

-- Add a new column new_termdate 
ALTER TABLE hr_data
ADD new_termdate DATE;


UPDATE hr_data
SET new_termdate = 
  CASE  
    WHEN termdate IS NOT NULL AND TRY_CAST(termdate AS DATETIME) IS NOT NULL 
    THEN CAST(termdate AS DATETIME)
    ELSE NULL 
  END;


-- convert termdate to DATE and copy the column to new_termdate
 SELECT 
    termdate,
    CASE  
        WHEN termdate IS NOT NULL AND TRY_CAST(termdate AS DATETIME) IS NOT NULL 
        THEN CAST(termdate AS DATETIME)
        ELSE NULL 
    END AS new_termdate
FROM hr_data;
-- From now on, we will use the new_termdat instead as it has the correct date format


ALTER TABLE hr_data -- dropping unused column
DROP COLUMN termdate;

--Create an "age" column and get age of the emplpoyees
AlTER TABLE hr_data
ADD age nvarchar(50)

UPDATE hr_data
SET age = DATEDIFF(YEAR, birthdate, GETDATE());

SELECT age
FROM hr_data;





--DATA querying 
-- 1. Age distribution in the company?
SELECT 
	MIN(age) AS youngest,
	MAX(age) AS oldest
FROM hr_data
	-- age group
SELECT age_group,
COUNT(*) AS count
FROM
(SELECT 
	CASE
		WHEN age >=21 AND age <= 30 THEN '21 to 30'
		WHEN age >=31 AND age <= 40 THEN '31  to 40'
		WHEN age >=41 AND age <= 50 THEN '41 to 50'
		ELSE '50+'
		END AS age_group
FROM hr_data
WHERE new_termdate IS NULL) AS subquery
GROUP BY age_group
ORDER BY age_group

-- 2. age group by gender
SELECT age_group,
gender,
COUNT(*) AS count
FROM
(SELECT 
	gender,
	CASE
		WHEN age >=21 AND age <= 30 THEN '21 to 30'
		WHEN age >=31 AND age <= 40 THEN '31  to 40'
		WHEN age >=41 AND age <= 50 THEN '41 to 50'
		ELSE '50+'
		END AS age_group
FROM hr_data
WHERE new_termdate IS NULL) AS subquery
GROUP BY age_group, gender
ORDER BY age_group, gender

-- 3. What is the gender breakdown?
SELECT 
	gender,
	COUNT(gender) AS count
	FROM hr_data
	WHERE new_termdate IS NULL
	GROUP BY gender
	ORDER BY gender



--4. Race Distribution
SELECT 
	race,
	count(*) AS count
FROM hr_data
WHERE new_termdate IS NULL
GROUP BY race
ORDER BY count DESC


--5. average lenght of employment
SELECT	
	AVG(DATEDIFF(year, hire_date, new_termdate)) AS tenure
FROM hr_data
WHERE new_termdate IS NOT NULL AND new_termdate <= GETDATE()


-- 6. Which department has the highest turnover rate
SELECT -- get turnover rate
 department,
 total_count,
 terminated_count,
 ROUND((CAST(terminated_count AS FLOAT) / total_count),2) * 100 AS turnover_rate -- CAST to float to prevent integer division
 FROM
	(SELECT -- get total count 
	 department,
     COUNT(*) AS total_count,
     SUM(CASE 
	    WHEN new_termdate IS NOT NULL AND new_termdate <=GETDATE() THEN 1 ELSE 0
	    END) AS terminated_count 
	FROM hr_data
	GROUP BY department
	) AS subquery
ORDER BY turnover_rate DESC

-- 7. Tenure distribution for each department
SELECT	
 department,
 AVG(DATEDIFF(year, hire_date, new_termdate)) AS tenure
FROM hr_data
WHERE new_termdate IS NOT NULL AND new_termdate <= GETDATE()
GROUP BY department
ORDER BY tenure DESC



-- 8. Remote employees in each department
SELECT 
 location, 
 count(*) as count
FROM hr_data
WHERE new_termdate IS NULL
GROUP BY location


--9. Employee states
SELECT 
 location_state,
 COUNT(*) AS count
 FROM hr_data
 WHERE new_termdate IS NULL
 GROUP BY location_state
 ORDER BY count DESC 


 --10. Job titile distribution 
 SELECT jobtitle,
 COUNT(*) as count
 FROM hr_data
 WHERE new_termdate IS NULL
 GROUP BY jobtitle
 ORDER BY count DESC


 -- 11. How have employee hire counts varied over time
    -- calculate hires
	--calculate terminations
	--(hires-termination) / hire percent change
SELECT
 hire_year,
 hires,
 terminations,
 (hires - terminations) AS net_change,
 ROUND(CAST((hires - terminations) AS FLOAT) / hires,2) *100 as percent_hire_change
 FROM 
	(SELECT 
	 YEAR(hire_date) AS hire_year,
	 COUNT(*) AS hires,
	 SUM (CASE
			WHEN new_termdate IS NOT NULL AND  new_termdate <= GETDATE() THEN 1 ELSE 0
			END ) AS terminations
	FROM hr_data
	GROUP BY YEAR(hire_date)
	) AS subquery
ORDER BY percent_hire_change ASC 


-- 12. department hires by years

SELECT
  hire_year,
  SUM(hires) AS hires,
  department
FROM 
  (SELECT 
     department,
     YEAR(hire_date) AS hire_year,
     COUNT(*) AS hires
   FROM hr_data
   GROUP BY department, YEAR(hire_date)
  ) AS subquery
GROUP BY department, hire_year
ORDER BY hire_year ASC

