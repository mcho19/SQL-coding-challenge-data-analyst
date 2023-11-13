
1. Data Integrity Checking & Cleanup

    Alphabetically list all of the country codes in the continent_map table that appear more than once. Display any values where
    country_code is null as country_code = "FOO" and make this row appear first in the list, even though it should alphabetically sort to the middle.
    Provide the results of this query as your answer.

    For all countries that have multiple rows in the continent_map table, delete all multiple records leaving only the
    1 record per country. The record that you keep should be the first one when sorted by the continent_code alphabetically ascending.
    Provide the query/ies and explanation of step(s) that you follow to delete these records.

WITH country_foo AS (SELECT
continent_code,
CASE WHEN country_code IS NULL THEN 'FOO' END as country_code
FROM continent_map
WHERE country_code IS NULL
GROUP BY country_code),

duplicate_countries AS (SELECT
continent_code,
country_code
FROM continent_map
GROUP BY country_code
HAVING COUNT(country_code) > 1
ORDER BY country_code ASC)

SELECT
country_code
FROM country_foo
UNION ALL
SELECT
country_code
FROM duplicate_countries

-- UNION put FOO in the middle of this table while UNION ALL moved FOO to the top
-- I know that UNION ALL allows duplicates. I think UNION does a default ORDER BY when run
-- I don't think UNION ALL does this automatic sorting

country_code
FOO
ARM
AZE
CYP
GEO
KAZ
RUS
TUR
UMI

========================================================================================================================

2. List the countries ranked 10-12 in each continent by the percent of year-over-year growth descending from 2011 to 2012.

The percent of growth should be calculated as: ((2012 gdp - 2011 gdp) / 2011 gdp)

The list should include the columns:

    rank
    continent_name
    country_code
    country_name
    growth_percent

-- Issues I've had creating this query
-- Creating new columns but not being able to use them in the original query
-- Is it because in creating a column in the original table, the column hasn't been created yet so it doesn't actually exist?
-- I got around this by creating CTEs, three to be exact.
-- Is it bad to create too many CTEs? Does it matter, efficiency wise?
-- Is the alternative doing sub-queries?

-- Next issue - window functions, specifically using LAG() and ROW_NUMBER()
-- I thought window functions was more complicated but it just turns out you can add them to your SELECT clause
-- The hardest part is getting the syntax of FUNCTION() OVER (PARTITION BY "column" ORDER BY "column" part down
-- I need to wrap my head around the PARTITION... section and really understand what's being used and sorted in regards the window function being used

-- Next issue - certain functions do not exist in sql lite vs mysql
-- I don't think this is a huge deal, I just have to be aware of when functions do not work and find the one that is simliar in the SQL style I'm using
-- i.e. concat() in sql lite does not exist, instead it uses str1 || str2

-- Next issue - sorted numbers are not sorted properly descending - single digits are sorted higher than multi-digit number even though they're higher numerically
-- i.e. 6.12% > 33.83%
-- I need to look at my CTE that computes the percentages and see if that's being sorted properly
-- I fixed this by only sorting the decimal first, then converting it later in the query

-- Next issue - using the ROW_NUMBER() window function
-- I need to get a handle on the PARTION... and ORDER... part of the window function to properly sort by year over year percent DESC and continent name
-- so the countries in the same continent are sorted together, so I can properly rank them by their yoy %

WITH country AS (
SELECT
c.country_code,
c.country_name,
cn.continent_name
FROM countries c
JOIN continent_map cnm ON c.country_code = cnm.country_code
JOIN continents cn ON cnm.continent_code = cn.continent_code),

yoy AS (SELECT
country_code,
year,
gdp_per_capita AS current_year,
LAG(gdp_per_capita) OVER (ORDER BY country_code) as previous_year,
CASE WHEN LAG(country_code,1) OVER (ORDER BY country_code) = country_code THEN gdp_per_capita - LAG(gdp_per_capita)OVER (ORDER BY country_code) ELSE null END as year_subtract_previous
FROM per_capita
WHERE year BETWEEN 2011 AND 2012
ORDER BY country_code ASC, year ASC),

yoy_percent AS (SELECT
--ROW_NUMBER() OVER(PARTITION BY continent_name ORDER BY continent_name DESC) as rank,
-- need to sort the rank by yoy_percent DESC but not sure how to do that
c.continent_name,
c.country_code,
c.country_name,
(yoy.year_subtract_previous / yoy.previous_year) AS year_over_year_percent
--sql lite does not have concat, need to use ||
FROM yoy
JOIN country c on yoy.country_code = c.country_code
WHERE year_over_year_percent IS NOT NULL
ORDER BY c.continent_name ASC),

-- I need to sort by yoy_% DESC by continent to get accurate rank

countries_rank AS (SELECT
ROW_NUMBER() OVER(PARTITION BY yoy_percent.continent_name ORDER BY yoy_percent.year_over_year_percent DESC) as rank,
yoy_percent.*
FROM yoy_percent
ORDER BY yoy_percent.continent_name, yoy_percent.year_over_year_percent DESC)

SELECT
countries_rank.rank as rank,
countries_rank.continent_name,
countries_rank.country_code,
countries_rank.country_name,
(ROUND((countries_rank.year_over_year_percent),2) * 100) || '%' as growth_percent
FROM countries_rank
WHERE rank BETWEEN 10 AND 12
ORDER BY continent_name

Rank continent_name country_code country_name growth_percent
10	Africa	RWA	Rwanda	9.0%
11	Africa	GIN	Guinea	8.0%
12	Africa	NGA	Nigeria	8.0%
10	Asia	UZB	Uzbekistan	11.0%
11	Asia	IRQ	Iraq	10.0%
12	Asia	PHL	Philippines	10.0%
10	Europe	LTU	Lithuania	0.0%
11	Europe	EST	Estonia	0.0%
12	Europe	AZE	Azerbaijan	0.0%
10	North America	GTM	Guatemala	3.0%
11	North America	HND	Honduras	3.0%
12	North America	ATG	Antigua and Barbuda	3.0%
10	Oceania	FJI	Fiji	3.0%
11	Oceania	TUV	Tuvalu	1.0%
12	Oceania	KIR	Kiribati	0.0%
10	South America	ARG	Argentina	6.0%
11	South America	PRY	Paraguay	-4.0%
12	South America	BRA	Brazil	-10.0%

-- Everything below was used to figure out the sorting issue using decimals vs percentages

WITH country AS (
SELECT
c.country_code,
c.country_name,
cn.continent_name
FROM countries c
JOIN continent_map cnm ON c.country_code = cnm.country_code
JOIN continents cn ON cnm.continent_code = cn.continent_code),

yoy AS (SELECT
country_code,
year,
gdp_per_capita AS current_year,
LAG(gdp_per_capita) OVER (ORDER BY country_code) as previous_year,
CASE WHEN LAG(country_code,1) OVER (ORDER BY country_code) = country_code THEN gdp_per_capita - LAG(gdp_per_capita)OVER (ORDER BY country_code) ELSE null END as year_subtract_previous
FROM per_capita
WHERE year BETWEEN 2011 AND 2012
ORDER BY country_code ASC, year ASC)

SELECT
--ROW_NUMBER() OVER(PARTITION BY continent_name ORDER BY continent_name DESC) as rank,
-- need to sort the rank by yoy_percent DESC but not sure how to do that
c.continent_name,
c.country_code,
c.country_name,
ROUND((yoy.year_subtract_previous / yoy.previous_year),2) AS year_over_year_percent,
ROUND((yoy.year_subtract_previous / yoy.previous_year),2) || '%' AS year_over_year_percent_1,
(yoy.year_subtract_previous / yoy.previous_year) AS yoy_percent_unrounded
--sql lite does not have concat, need to use ||
FROM yoy
JOIN country c on yoy.country_code = c.country_code
WHERE year_over_year_percent IS NOT NULL
ORDER BY c.continent_name ASC, year_over_year_percent_1 DESC

========================================================================================================================

3. For the year 2012, create a 3 column, 1 row report showing the percent share of gdp_per_capita for the following regions:

(i) Asia, (ii) Europe, (iii) the Rest of the World. Your result should look something like
Asia 	Europe 	Rest of World
25.0% 	25.0% 	50.0%

-- Upon creating aggregates, Europe had NULL so I went back to check if Europe had any gdp_per_capita in 2012.
-- Since it did, I am trying to remove any NULL values and see if that affects things

-- I forgot to add sum() so it was only showing the gdp_per_capita of the first row

-- maybe this is a sqlite peculiarity but at the bottom of this table, it shows continent_name on the bottom of the table. I don't think I'm entering a blank row.

-- how many arguments can SUM() have?
-- I used "+" instead

-- rest of world had to be typed 'Rest of World' to not trigger an error

WITH world_gdp AS (SELECT
cn.continent_name,
-- ROUND(SUM(p.gdp_per_capita),2) as total_sum_gdp,
CASE WHEN continent_name = 'Africa' THEN SUM(p.gdp_per_capita) ELSE 0 END as af_gdp,
CASE WHEN continent_name = 'Asia' THEN SUM(p.gdp_per_capita) ELSE 0 END as as_gdp,
CASE WHEN continent_name = 'Europe' THEN SUM(p.gdp_per_capita) ELSE 0 END as eu_gdp,
CASE WHEN continent_name = 'North America' THEN SUM(p.gdp_per_capita) ELSE 0 END as na_gdp,
CASE WHEN continent_name = 'Oceania' THEN SUM(p.gdp_per_capita) ELSE 0 END as oc_gdp,
CASE WHEN continent_name = 'South America' THEN SUM(p.gdp_per_capita) ELSE 0 END as sa_gdp
FROM per_capita p
JOIN continent_map c ON p.country_code = c.country_code
JOIN continents cn ON c.continent_code = cn.continent_code
GROUP BY cn.continent_name),

totals AS (SELECT
SUM(world_gdp.af_gdp + world_gdp.as_gdp+world_gdp.eu_gdp+world_gdp.na_gdp+world_gdp.oc_gdp+world_gdp.sa_gdp) as world_total_gdp,
SUM(world_gdp.as_gdp+world_gdp.oc_gdp) as asia_total_gdp,
SUM(world_gdp.eu_gdp) as europe_total_gdp,
SUM(world_gdp.af_gdp +world_gdp.na_gdp++world_gdp.sa_gdp) as rest_of_world_total_gdp
FROM world_gdp)

SELECT
(ROUND((totals.asia_total_gdp / totals.world_total_gdp),2)*100) ||'%' AS Asia,
(ROUND((totals.europe_total_gdp / totals.world_total_gdp),2)*100)||'%' AS Eruope,
(ROUND((totals.rest_of_world_total_gdp / totals.world_total_gdp),2)*100) ||'%' AS 'Rest of World'
FROM totals

Asia    Europe  Rest of World
25.0%	53.0%	22.0%

========================================================================================================================

4a. What is the count of countries and sum of their related gdp_per_capita values for the year 2007 where the string 'an' (case insensitive) appears anywhere in the country name?

4b. Repeat question 4a, but this time make the query case sensitive.

-- case insensitive
PRAGMA case_sensitive_like=OFF;
SELECT
COUNT(c.country_name) as an_countries_count,
CASE WHEN p.gdp_per_capita IS NOT NULL THEN ('$'||ROUND(SUM(p.gdp_per_capita),2)) ELSE 0 END as total_gdp
FROM per_capita p
JOIN countries c ON p.country_code = p.country_code
WHERE c.country_name LIKE '%an%'
AND year = 2007

an_countries_count total_gdp
18249	$260470356.13

-- to make it case sensitive for sqlite, change PRAGMA case_sensitive_like=ON;
PRAGMA case_sensitive_like=ON;
SELECT
COUNT(c.country_name) as an_countries_count,
CASE WHEN p.gdp_per_capita IS NOT NULL THEN ('$'||ROUND(SUM(p.gdp_per_capita),2)) ELSE 0 END as total_gdp
FROM per_capita p
JOIN countries c ON p.country_code = p.country_code
WHERE c.country_name LIKE '%an%'
AND year = 2007

an_countries_count total_gdp
17787	$253876169.9

-- I believe PRAGMA is a sqlite DB check. I believe LIKE for mysql or etc. is case sensitive

========================================================================================================================

5. Find the sum of gpd_per_capita by year and the count of countries for each year that have non-null gdp_per_capita
where (i) the year is before 2012 and (ii) the country has a null gdp_per_capita in 2012. Your result should have the columns:

    year
    country_count
    total

-- Create a CTE with only countries that have NULL for gdp in 2012
-- then left join the primary table of per_capita with the CTE table
-- LEFT JOIN because I only want country_codes where there was a NULL for year 2012

WITH country_null AS (SELECT
country_code
FROM per_capita
WHERE year = 2012
AND gdp_per_capita IS NULL)

SELECT
year,
COUNT(p.country_code) as country_count,
'$'||ROUND(SUM(gdp_per_capita),2) as total_gdp
FROM country_null c
LEFT JOIN per_capita p ON c.country_code = p.country_code
WHERE year < 2012
GROUP BY year

year country_count total_gdp
2004	15	$491203.19
2005	15	$510734.98
2006	15	$553689.64
2007	15	$654508.77
2008	15	$574016.21
2009	15	$473103.33
2010	15	$179750.83
2011	15	$199152.68

========================================================================================================================

6. All in a single query, execute all of the steps below and provide the results as your final answer:

a. create a single list of all per_capita records for year 2009 that includes columns:

    continent_name
    country_code
    country_name
    gdp_per_capita

b. order this list by:

    continent_name ascending
    characters 2 through 4 (inclusive) of the country_name descending

c. create a running total of gdp_per_capita by continent_name

d. return only the first record from the ordered list for which each continent's
running total of gdp_per_capita meets or exceeds $70,000.00 with the following columns:

    continent_name
    country_code
    country_name
    gdp_per_capita
    running_total

 -- I'm assuming by a "single list", they mean a table
-- to have a running total, I believe I need a window function of SUM() where it sorts by continent_name
-- Issue - running total isn't summing properly, instead it is just giving the sum of all the rows in a specific continent
-- I need to figure out how to sort it so it sums in the way I want it to
-- I think this is a deeper drive into sorting for window functions and what partition by does and order by inside a window function does

-- one solution is to create a CTE for each continent that's sorted and ranked
-- combine all those CTEs together with a UNION
-- There's no sorting in the UNION though, unless I make it it's own CTE and create a new table from that

-- For sqlite, when using UNION and LIMIT, you can use parenthesis for as a subquery with a LIMIT then add UNION afterwards
-- i.e (SELECT * FROM data LIMIT 1) UNION (SELECT...

WITH names AS (SELECT
c.country_code,
c.country_name,
cont.continent_name
FROM countries c
JOIN continent_map m ON c.country_code = m.country_code
JOIN continents cont ON m.continent_code = cont.continent_code),

africa AS (SELECT
n.continent_name,
n.country_code,
n.country_name,
gdp_per_capita,
--ROW_NUMBER() OVER (PARTITION BY n.continent_name) as row_number,
SUM(gdp_per_capita) OVER (ORDER BY SUBSTR(n.country_name,2,2) DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_total
FROM per_capita p
JOIN names n ON p.country_code = n.country_code
WHERE year = 2009
AND n.continent_name = 'Africa'
AND gdp_per_capita IS NOT NULL
--ORDER BY continent_name ASC
ORDER BY n.continent_name ASC, SUBSTR(n.country_name,2,2) DESC),

south_america as (SELECT
n.continent_name,
n.country_code,
n.country_name,
gdp_per_capita,
--ROW_NUMBER() OVER (PARTITION BY n.continent_name) as row_number,
SUM(gdp_per_capita) OVER (ORDER BY SUBSTR(n.country_name,2,2) DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_total
FROM per_capita p
JOIN names n ON p.country_code = n.country_code
WHERE year = 2009
AND n.continent_name = 'South America'
AND gdp_per_capita IS NOT NULL
--ORDER BY continent_name ASC
ORDER BY n.continent_name ASC, SUBSTR(n.country_name,2,2) DESC),

oceania AS (SELECT
n.continent_name,
n.country_code,
n.country_name,
gdp_per_capita,
--ROW_NUMBER() OVER (PARTITION BY n.continent_name) as row_number,
SUM(gdp_per_capita) OVER (ORDER BY SUBSTR(n.country_name,2,2) DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_total
FROM per_capita p
JOIN names n ON p.country_code = n.country_code
WHERE year = 2009
AND n.continent_name = 'Oceania'
AND gdp_per_capita IS NOT NULL
--ORDER BY continent_name ASC
ORDER BY n.continent_name ASC, SUBSTR(n.country_name,2,2) DESC),

north_america AS (SELECT
n.continent_name,
n.country_code,
n.country_name,
gdp_per_capita,
--ROW_NUMBER() OVER (PARTITION BY n.continent_name) as row_number,
SUM(gdp_per_capita) OVER (ORDER BY SUBSTR(n.country_name,2,2) DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_total
FROM per_capita p
JOIN names n ON p.country_code = n.country_code
WHERE year = 2009
AND n.continent_name = 'North America'
AND gdp_per_capita IS NOT NULL
--ORDER BY continent_name ASC
ORDER BY n.continent_name ASC, SUBSTR(n.country_name,2,2) DESC),

europe AS (SELECT
n.continent_name,
n.country_code,
n.country_name,
gdp_per_capita,
--ROW_NUMBER() OVER (PARTITION BY n.continent_name) as row_number,
SUM(gdp_per_capita) OVER (ORDER BY SUBSTR(n.country_name,2,2) DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_total
FROM per_capita p
JOIN names n ON p.country_code = n.country_code
WHERE year = 2009
AND n.continent_name = 'Oceania'
AND gdp_per_capita IS NOT NULL
--ORDER BY continent_name ASC
ORDER BY n.continent_name ASC, SUBSTR(n.country_name,2,2) DESC),

asia as (SELECT
n.continent_name,
n.country_code,
n.country_name,
gdp_per_capita,
--ROW_NUMBER() OVER (PARTITION BY n.continent_name) as row_number,
SUM(gdp_per_capita) OVER (ORDER BY SUBSTR(n.country_name,2,2) DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_total
FROM per_capita p
JOIN names n ON p.country_code = n.country_code
WHERE year = 2009
AND n.continent_name = 'Oceania'
AND gdp_per_capita IS NOT NULL
--ORDER BY continent_name ASC
ORDER BY n.continent_name ASC, SUBSTR(n.country_name,2,2) DESC),


-- SELECT south_america.continent_name, south_america.country_code, south_america.country_name, '$'||ROUND(gdp_per_capita,2) as gdp_per_capita, '$'||ROUND(running_total,2) AS running_total FROM south_america WHERE running_total > 70000 LIMIT 1

sventy_thou AS
(SELECT * FROM (SELECT south_america.continent_name, south_america.country_code, south_america.country_name, '$'||ROUND(gdp_per_capita,2) as gdp_per_capita, '$'||ROUND(running_total,2) AS running_total FROM south_america WHERE running_total >= 70000 LIMIT 1)
UNION
SELECT * FROM  (SELECT oceania.continent_name, oceania.country_code, oceania.country_name, '$'||ROUND(gdp_per_capita,2) as gdp_per_capita, '$'||ROUND(running_total,2) AS running_total FROM oceania WHERE running_total >= 70000 LIMIT 1)
UNION
SELECT * FROM  (SELECT north_america.continent_name, north_america.country_code, north_america.country_name, '$'||ROUND(gdp_per_capita,2) as gdp_per_capita, '$'||ROUND(running_total,2) AS running_total FROM north_america WHERE running_total >= 70000 LIMIT 1)
UNION
SELECT * FROM  (SELECT europe.continent_name, europe.country_code, europe.country_name, '$'||ROUND(gdp_per_capita,2) as gdp_per_capita, '$'||ROUND(running_total,2) AS running_total FROM europe WHERE running_total >= 70000 LIMIT 1)
UNION
SELECT * FROM  (SELECT asia.continent_name, asia.country_code, asia.country_name, '$'||ROUND(gdp_per_capita,2) as gdp_per_capita, '$'||ROUND(running_total,2) AS running_total FROM asia WHERE running_total >= 70000 LIMIT 1)
UNION
SELECT * FROM  (SELECT africa.continent_name, africa.country_code, africa.country_name, '$'||ROUND(gdp_per_capita,2) as gdp_per_capita, '$'||ROUND(running_total,2) AS running_total FROM africa WHERE running_total >= 70000 LIMIT 1)
)

SELECT *
FROM sventy_thou
ORDER BY sventy_thou.continent_name ASC

continent_name country_code country_name gdp_per_capita running_total
Africa	LBY	Libya	$10455.57	$70529.44
North America	ABW	Aruba	$24639.94	$84504.67
Oceania	NZL	New Zealand	$27474.33	$84623.92
South America	ECU	Ecuador	$4236.78	$72315.82


========================================================================================================================

7. Find the country with the highest average gdp_per_capita for each continent for all years. Now compare your list to the following data set.
Please describe any and all mistakes that you can find with the data set below. Include any code that you use to help detect these mistakes.

rank 	continent_name 	country_code 	country_name 	avg_gdp_per_capita
1 	Africa 	SYC 	Seychelles 	$11,348.66
1 	Asia 	KWT 	Kuwait 	$43,192.49
1 	Europe 	MCO 	Monaco 	$152,936.10
1 	North America 	BMU 	Bermuda 	$83,788.48
1 	Oceania 	AUS 	Australia 	$47,070.39
1 	South America 	CHL 	Chile 	$10,781.71

WITH names AS (SELECT
c.country_code,
c.country_name,
cont.continent_name
FROM countries c
JOIN continent_map m ON c.country_code = m.country_code
JOIN continents cont ON m.continent_code = cont.continent_code),

avg_gdp AS (SELECT
-- g.year,
n.country_name,
n.country_code,
n.continent_name,
-- g.gdp_per_capita
AVG(g.gdp_per_capita) as average_gdp
FROM per_capita g
JOIN names n ON n.country_code = g.country_code
-- WHERE gdp_per_capita IS NOT NULL
GROUP BY n.country_name, n.continent_name
ORDER BY n.continent_name),


ranking AS (SELECT
*,
'$'||ROUND(average_gdp,2) as average_gdp_rounded,
ROW_NUMBER() OVER (PARTITION BY a.continent_name ORDER BY a.average_gdp DESC) as row_number
FROM avg_gdp a
ORDER BY a.continent_name, a.average_gdp DESC)

SELECT row_number as rank, continent_name,country_code, country_name, average_gdp_rounded as average_gdp
FROM ranking
WHERE row_number = 1

-- issues with the table from the questions vs my answer
-- Africa's highest GDP belongs to Equatorial Guinea, not Seychelles
-- Asia's highest GDP belongs to Qatar, not Kuwait
-- Austraila's GDP average is wrong compared to my answer

rank	continent_name	country_code	country_name	average_gdp
1	Africa	GNQ	Equatorial Guinea	$17955.72
1	Asia	QAT	Qatar	$70567.96
1	Europe	MCO	Monaco	$151421.89
1	North America	BMU	Bermuda	$84634.83
1	Oceania	AUS	Australia	$46147.45
1	South America	CHL	Chile	$10781.71

-- Africa's highest GDP belongs to Equatorial Guinea, not Seychelles

WITH names AS (SELECT
c.country_code,
c.country_name,
cont.continent_name
FROM countries c
JOIN continent_map m ON c.country_code = m.country_code
JOIN continents cont ON m.continent_code = cont.continent_code)

SELECT
g.year,
n.country_name,
n.country_code,
n.continent_name,
g.gdp_per_capita,
AVG(g.gdp_per_capita) OVER (ORDER BY year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as rolling_average_gdp,
AVG(g.gdp_per_capita) OVER (ORDER BY year DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as rev_rolling_average_gdp
FROM per_capita g
JOIN names n ON n.country_code = g.country_code
WHERE n.country_name = 'Australia'
-- WHERE gdp_per_capita IS NOT NULL
-- GROUP BY n.country_name, n.continent_name
ORDER BY n.continent_name

-- Austraila's GDP average is wrong compared to my answer
-- The average for Australia was not calculated properly but as you can see from the rolling average, the average cannot be obtained
-- The error could be additional data was used in the incorrect averaging

year  country_name country_code continent_name gdp_per_capita rolling_average_gdp rev_rolling_average_gdp
2004	Australia	AUS	Oceania	30464.00376	30464.00376	46147.45221
2005	Australia	AUS	Oceania	34011.73864	32237.8712	48107.88326625
2006	Australia	AUS	Oceania	36113.0024	33529.5816	50121.6182128571
2007	Australia	AUS	Oceania	40996.31791	35396.2656775	52456.387515
2008	Australia	AUS	Oceania	49672.74801	38251.562144	54748.401436
2009	Australia	AUS	Oceania	42721.88494	38996.6159433333	56017.3147925
2010	Australia	AUS	Oceania	51824.79842	40829.21344	60449.1247433333
2011	Australia	AUS	Oceania	62080.98242	43485.6845625	64761.287905
2012	Australia	AUS	Oceania	67441.59339	46147.45221	67441.59339

-- Africa's highest GDP belongs to Equatorial Guinea, not Seychelles

WITH names AS (SELECT
c.country_code,
c.country_name,
cont.continent_name
FROM countries c
JOIN continent_map m ON c.country_code = m.country_code
JOIN continents cont ON m.continent_code = cont.continent_code),

avg_gdp AS (SELECT
-- g.year,
n.country_name,
n.country_code,
n.continent_name,
-- g.gdp_per_capita,
AVG(g.gdp_per_capita) as average_gdp
FROM per_capita g
JOIN names n ON n.country_code = g.country_code
WHERE n.continent_name= 'Africa'
-- WHERE gdp_per_capita IS NOT NULL
GROUP BY n.country_name, n.continent_name
ORDER BY n.continent_name)

SELECT *, ROW_NUMBER() OVER (ORDER BY average_gdp DESC) as ranking
FROM avg_gdp
LIMIT 5 -- don't care about the others below 5, just want to see what's first

-- Africa's highest GDP belongs to Equatorial Guinea, not Seychelles
-- Based on the average_gpd and ranking, Equatorial Guinea has the highest average_gdp, not Seychelles

country_name country_code continent_name average_gpd ranking
Equatorial Guinea	GNQ	Africa	17955.7223095556	1
Seychelles	SYC	Africa	11348.6605223333	2
Libya	LBY	Africa	10431.246815	3
Gabon	GAB	Africa	8578.41426955556	4
Mauritius	MUS	Africa	6752.34828688889	5

-- Asia's highest GDP belongs to Qatar, not Kuwait

WITH names AS (SELECT
c.country_code,
c.country_name,
cont.continent_name
FROM countries c
JOIN continent_map m ON c.country_code = m.country_code
JOIN continents cont ON m.continent_code = cont.continent_code),

avg_gdp AS (SELECT
-- g.year,
n.country_name,
n.country_code,
n.continent_name,
-- g.gdp_per_capita,
AVG(g.gdp_per_capita) as average_gdp
FROM per_capita g
JOIN names n ON n.country_code = g.country_code
WHERE n.continent_name= 'Asia'
-- WHERE gdp_per_capita IS NOT NULL
GROUP BY n.country_name, n.continent_name
ORDER BY n.continent_name)

SELECT *, ROW_NUMBER() OVER (ORDER BY average_gdp DESC) as ranking
FROM avg_gdp
LIMIT 5

-- Asia's highest GDP belongs to Qatar, not Kuwait
-- Based on the ranking and average GDP, Qatar is the highest ranked, not Kuwait, which is not even first but third

country_name country_code continent_name average_gdp ranking
Qatar	QAT	Asia	70567.9622377778	1
Macao SAR, China	MAC	Asia	43879.92658	2
Kuwait	KWT	Asia	43192.48873	3
United Arab Emirates	ARE	Asia	40910.4731711111	4
Singapore	SGP	Asia	39386.3909588889	5