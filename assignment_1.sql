CREATE SCHEMA project_1;
USE project_1;


-- creation of tables from databases

SHOW VARIABLES LIKE "secure_file_priv";

SHOW VARIABLES LIKE "local_infile";


CREATE TABLE share_renewables (
    id	VARCHAR(512),
    Entity	VARCHAR(512),
    Code	VARCHAR(512),
    Year	INT,
    share_of_renewables	DECIMAL(5,2)
);



CREATE TABLE solar_energy (
    id	VARCHAR(512),
    Entity	VARCHAR(512),
    Code	VARCHAR(512),
    Year	INT,
    Share_of_solar	DECIMAL(5,2)
);


CREATE TABLE wind_energy (
    id	VARCHAR(512),
    Entity	VARCHAR(512),
    Code	VARCHAR(512),
    Year	INT,
    Share_wind	DECIMAL(5,2)
);


CREATE TABLE hydro_energy (
    id	VARCHAR(512),
    Entity	VARCHAR(512),
    Code	VARCHAR(512),
    Year	INT,
    Share_of_Hydro	DECIMAL(5,2)
);


CREATE TABLE gdp_1965 (
    id	VARCHAR(512),
    Entity	VARCHAR(512),
    Code	VARCHAR(512),
    Indicator_Name	VARCHAR(512),
    Indicator_Code	VARCHAR(512),
    gdp_in_1965	VARCHAR(512)
);


CREATE TABLE gdp_2019 (
    id	VARCHAR(512),
    Entity	VARCHAR(512),
    Code	VARCHAR(512),
    Indicator_Name	VARCHAR(512),
    Indicator_Code	VARCHAR(512),
    gdp_in_2019	VARCHAR(512)
);

CREATE TABLE patents_renewable_energies (
    id	VARCHAR(512),
    Entity	VARCHAR(512),
    Code	VARCHAR(512),
    Year	INT,
    total_patents	INT
);

/* To fill in the tables above, you need to run the following SQL files: 
'renewable_energy', 'solar_energy', 'wind_energy', hydro_energy', 'gdp_2019', 'gdp_1965', 'patents_renewable_energy'. */

/* creation of an intermediate table with infomation about renewable energies 
and addition of a column showing which type of renewable energy is most widely used in each country between 1965 and 2021. */

CREATE TABLE all_renewables_table AS
SELECT 
    t1.id,                 
    t1.Year, 
    t1.Entity,
    t1.share_of_renewables, 
    t2.Share_wind, 
    t3.Share_of_solar, 
    t4.Share_of_Hydro,
    CASE 
        WHEN t2.Share_wind >= t3.Share_of_solar AND t2.Share_wind >= t4.Share_of_Hydro THEN 'wind'
        WHEN t3.Share_of_solar >= t2.Share_wind AND t3.Share_of_solar >= t4.Share_of_Hydro THEN 'solar'
        WHEN t4.Share_of_Hydro >= t2.Share_wind AND t4.Share_of_Hydro >= t3.Share_of_solar THEN 'hydro'
        ELSE NULL
    END AS most_used_renewable
FROM 
    share_renewables AS t1
JOIN 
    wind_energy AS t2 ON t1.id = t2.id
JOIN 
    solar_energy AS t3 ON t1.id = t3.id    
JOIN 
    hydro_energy AS t4 ON t1.id = t4.id
;

/* creation of a table to calculate the evolution of gdp for each country beetween 1965 et 2019 */

CREATE TABLE gdp AS
SELECT 
    t1.Entity,
    t1.gdp_in_1965,
    t2.gdp_in_2019,
    CASE 
        WHEN t1.gdp_in_1965 IS NOT NULL AND t2.gdp_in_2019 IS NOT NULL AND t1.gdp_in_1965 <> 0 AND t2.gdp_in_2019 <> 0 
        THEN  ROUND((POWER(t2.gdp_in_2019 / t1.gdp_in_1965, 1.0 / (2021 - 1965)) - 1) * 100,2)
        ELSE NULL 
    END AS evolution_gdp_1965_2019
FROM 
    gdp_1965 AS t1
LEFT JOIN 
    gdp_2019 AS t2 ON t1.Entity = t2.Entity;


/* creation of an intermediate table which brings together the evolution of gdp and the evolution of 
the renewable energy consumption to calculate their ratio */

CREATE TABLE renewables_gdp_evolution AS
SELECT 
    d1.Entity,
    ROUND(d1.share_of_renewables, 2) AS renewable_1965,
    ROUND(d2.share_of_renewables, 2) AS renewable_2019,
    CASE 
        WHEN d1.share_of_renewables IS NOT NULL AND d1.share_of_renewables <> 0 THEN 
            ROUND((POWER(d2.share_of_renewables / d1.share_of_renewables, 1.0 / (2021 - 1965)) - 1) * 100, 2)
        ELSE NULL 
    END AS evolution_renewables_1965_2019,
    g.evolution_gdp_1965_2019,
    CASE 
        WHEN g.evolution_gdp_1965_2019 IS NOT NULL AND g.evolution_gdp_1965_2019 <> 0 THEN 
            ROUND((CASE 
                       WHEN d1.share_of_renewables IS NOT NULL AND d1.share_of_renewables <> 0 THEN 
                           (POWER(d2.share_of_renewables / d1.share_of_renewables, 1.0 / (2021 - 1965)) - 1) * 100
                       ELSE NULL 
                   END) / g.evolution_gdp_1965_2019, 2)
        ELSE NULL 
    END AS ratio_renewables_to_gdp
FROM 
    all_renewables_table d1
JOIN 
    all_renewables_table d2 ON d1.Entity = d2.Entity
LEFT JOIN 
    gdp g ON d1.Entity = g.Entity
WHERE 
    d1.Year = 1965 AND d2.Year = 2019
ORDER BY 
    d1.Entity;

/* creation of the final table which contains all the information we need to respond the following questions : 
	- Is the development of renewable energies similar for each region of the world in terms of speed of development 
      and type of renewable energy used? 
	- Who are the players using the most renewable energy in 2019? 
    - How can we explain this difference in the use of renewable energy between countries? 
	  --> Is there a link with a country's stage of economic development? 
	  --> Is there a link with the number of patents in the country's renewable energy sector? */

CREATE TABLE project_table AS
SELECT 
    t1.id,                 
    t1.Year, 
    t1.Entity,
    t1.share_of_renewables, 
    t1.Share_wind, 
    t1.Share_of_solar, 
    t1.Share_of_Hydro,
    t1.most_used_renewable,
    t2.evolution_renewables_1965_2019,
    t2.evolution_gdp_1965_2019,
    t2.ratio_renewables_to_gdp,
    t3.total_patents
FROM 
    all_renewables_table AS t1
JOIN 
    renewables_gdp_evolution AS t2 ON t1.Entity = t2.Entity 
JOIN
	patents_renewable_energies AS t3 ON t1.Entity = t3.Entity  AND t1.Year = t3.Year
WHERE 
    t1.Year = 2019
    AND t1.Entity NOT LIKE '%Africa%'
    AND t1.Entity NOT LIKE '%Asia%'
    AND t1.Entity NOT LIKE '%Europe%'
    AND t1.Entity NOT LIKE '%European%'
    AND t1.Entity NOT LIKE '%America%'
    AND t1.Entity NOT LIKE '%OECD%'
    AND t1.Entity NOT LIKE '%income%'
    AND t1.Entity NOT LIKE '%CIS%'
ORDER BY 
    CASE WHEN t1.Entity LIKE '%World%' THEN 0 ELSE 1 END,
    t1.share_of_renewables DESC;


SELECT * FROM project_table;