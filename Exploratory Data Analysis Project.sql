-- Exploratory Data Analysis 

SELECT * 
FROM layoffs_staging2;

CREATE TABLE `layoffs_staging3` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` text,
  `percentage_laid_off` text,
  `date` date,
  `stage` text,
  `country` text,
  `funds_raised_millions` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging3
SELECT *
FROM layoffs_staging2;

SELECT * 
FROM layoffs_staging3;

UPDATE layoffs_staging3
SET total_laid_off = NULL
WHERE BINARY total_laid_off = 'None';

ALTER TABLE layoffs_staging3
MODIFY total_laid_off INT;

UPDATE layoffs_staging3
SET funds_raised_millions = NULL
WHERE BINARY funds_raised_millions = 'None';

ALTER TABLE layoffs_staging3
MODIFY funds_raised_millions INT;

UPDATE layoffs_staging3
SET percentage_laid_off = NULL
WHERE BINARY percentage_laid_off = 'None';


SELECT * 
FROM layoffs_staging3;

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging3;

SELECT * 
FROM layoffs_staging3
WHERE percentage_laid_off = 1 
ORDER BY funds_raised_millions DESC;

SELECT company, SUM(total_laid_off)  -- Big Companies with most lay offs (Google, Amazon, Meta)
FROM layoffs_staging3
GROUP BY company 
ORDER BY 2 DESC;

SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging3;

SELECT industry, SUM(total_laid_off)  -- Consumer and Retail on top 
FROM layoffs_staging3
GROUP BY industry 
ORDER BY 2 DESC;

SELECT country, SUM(total_laid_off)  -- United States has the most by far layoffs
FROM layoffs_staging3
GROUP BY country 
ORDER BY 2 DESC;

SELECT YEAR(`date`), SUM(total_laid_off)  -- in only three months of data 2023 is almost the same as 2022
FROM layoffs_staging3
GROUP BY YEAR(`date`)
ORDER BY 1 DESC; 

SELECT stage, SUM(total_laid_off)  
FROM layoffs_staging3
GROUP BY stage
ORDER BY 2 DESC; 


SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off)
FROM layoffs_staging3
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
;
-- COVID lockdowns happened in March 2020 so in 2020 the most layoffs were in April
-- January 2021 had the most layoffs in the begining of the year 
-- In Novemeber 2022 was the month with most layoffs 
-- January 2023 had the most layoffs but this data has the full set months of data of 2023

-- Rolling total of layoffs
WITH Rolling_total AS
(
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS total_off
FROM layoffs_staging3
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
)
SELECT `MONTH`, total_off
,SUM(total_off) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_total;
-- at the end total 383,159 people laid off
-- 2021 was a good year compared to other years in lay offs, the months 10, 11, 12 and january 2023 were really bad in layoffs 


SELECT company, SUM(total_laid_off)  
FROM layoffs_staging3
GROUP BY company 
ORDER BY 2 DESC;

SELECT company, YEAR(`date`), SUM(total_laid_off)  
FROM layoffs_staging3
GROUP BY company, YEAR(`date`)
ORDER BY company ASC
;
-- can see companys that did multiple layoffs through the years 

SELECT company, YEAR(`date`), SUM(total_laid_off)  
FROM layoffs_staging3
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC
;

-- create a CTE to get the top 5 companies in rank for each year of layoffs
-- 2 CTEs 
WITH Company_Year(company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)  
FROM layoffs_staging3
GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS 
(
SELECT *,
DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL

)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5
;

-- The top 5 industries that had the most total laid off per year 
WITH Industry_Year(industry, years, total_laid_off) AS
(
SELECT industry, YEAR(`date`), SUM(total_laid_off)  
FROM layoffs_staging3
GROUP BY industry, YEAR(`date`)
), Industry_Year_Rank AS 
(
SELECT *,
DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Industry_Year
WHERE years IS NOT NULL

)
SELECT *
FROM Industry_Year_Rank
WHERE Ranking <= 5
;
-- reatil and consumer appears to be the most consistent appears in the top 5 in 2020,2022,and 2023

-- Finding the location with the most lay offs in each year 
SELECT location,industry, SUM(total_laid_off) 
FROM layoffs_staging3
GROUP BY location, industry
ORDER BY 3 DESC;


WITH Location_Year(location, years, total_laid_off) AS
(
SELECT location, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging3
GROUP BY location, YEAR(`date`)
), Location_Year_Rank AS 
(
SELECT *,
DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Location_Year
WHERE years IS NOT NULL

)
SELECT *
FROM Location_Year_Rank
WHERE Ranking <= 5
;
-- San Fransico is ranked number one in layoffs each year and New York is ranked in the top five from 2020-2023


-- create a CTE with stats 
-- generates the slope and the intercept 
WITH Stats AS (
    SELECT 
        COUNT(*) AS n,
        SUM(funds_raised_millions) AS sum_x,
        SUM(percentage_laid_off) AS sum_y,
        SUM(funds_raised_millions * percentage_laid_off) AS sum_xy,
        SUM(funds_raised_millions * funds_raised_millions) AS sum_xx,
        SUM(percentage_laid_off * percentage_laid_off) AS sum_yy
    FROM layoffs_staging3
    WHERE funds_raised_millions IS NOT NULL AND percentage_laid_off IS NOT NULL
)
SELECT 
    (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x) AS slope,
    (sum_y - ((n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x)) * sum_x) / n AS intercept
FROM stats
;


-- generates the correlation coefficicient 
WITH stats AS (
    SELECT 
        COUNT(*) AS n,
        SUM(funds_raised_millions) AS sum_x,
        SUM(percentage_laid_off) AS sum_y,
        SUM(funds_raised_millions * percentage_laid_off) AS sum_xy,
        SUM(funds_raised_millions * funds_raised_millions) AS sum_xx,
        SUM(percentage_laid_off * percentage_laid_off) AS sum_yy
    FROM layoffs_staging3
    WHERE funds_raised_millions IS NOT NULL AND percentage_laid_off IS NOT NULL
)
SELECT 
    (n * sum_xy - sum_x * sum_y) / 
    SQRT((n * sum_xx - sum_x * sum_x) * (n * sum_yy - sum_y * sum_y)) AS correlation_coefficient
FROM stats;

-- Conclusions 
-- The slope of -0.00000341 informs us that for each additional one million dollars raised, the percent laid off decreases very slightly
-- by about 0.00000341%
-- very small slope meaning at least for this data, that fundraising has very little consequence on the number of layoffs being done.
-- The intercept is 0.2541 meaning if no money is raised, the model predicts a layoff of around 25.41% of employees of companies.
-- A very weak correlation with a small slope suggests that other causes may be affecting the layoffs rather than the amount of funds being raised by companies.




