use NiharikaHealthcareProject;


select * from encounters;
select * from organizationsselect * from payersselect * from procedures;
-- 1. Inconsistent gender values
SELECT DISTINCT gender FROM patients;

-- 2. Clean gender values
UPDATE patients
SET gender = CASE
    WHEN gender IN ('M', 'Male') THEN 'Male'
    WHEN gender IN ('F', 'Female') THEN 'Female'
    ELSE 'Unknown'
END;




--1 Evaluating Financial Risk by Encounter Outcome
SELECT 
    e.REASONCODE,
	e.REASONDESCRIPTION,
    p.GENDER,
    p.RACE,
	P.ETHNICITY,
    COUNT(*) AS TotalEncounters,
   ROUND(SUM(e.TOTAL_CLAIM_COST - e.PAYER_COVERAGE),2) AS TotalUncoveredCost
FROM 
    encounters e
JOIN 
    patients p ON e.PATIENT = p.id
where
     e.REASONCODE is not null
GROUP BY 
    e.REASONCODE,e.REASONDESCRIPTION,
    p.GENDER,
    p.RACE,
    p.ETHNICITY
ORDER BY 
    TotalUncoveredCost DESC;

--- 2 Identifying Patients with Frequent High-Cost Encounters
SELECT    p.Id AS patient_id,    p.FIRST,    p.LAST,    p.GENDER,    p.RACE,    p.ETHNICITY,    YEAR(e.START) AS visit_year,      COUNT(*) AS encounter_count,    ROUND(SUM(e.TOTAL_CLAIM_COST),2) AS total_expensive_costFROM    encounters eJOIN    patients p ON e.PATIENT = p.IdWHERE    e.TOTAL_CLAIM_COST > 10000GROUP BY    p.Id, p.FIRST, p.LAST, p.GENDER, p.RACE, p.ETHNICITY,  YEAR(e.START)HAVING    COUNT(*) > 3ORDER BY    total_expensive_cost DESC;


--- 3 Identifying Risk Factors Based on Demographics and Encounter Reasons-- STEP 1: Find the top 3 most frequent ReasonCodesWITH top_3_reasons AS (    SELECT TOP 3        REASONCODE    FROM        encounters    WHERE        REASONCODE IS NOT NULL    GROUP BY        REASONCODE    ORDER BY        COUNT(*) DESC)--select * from top_3_reasons;---select * from top_3_reasons--to view the top 3 reasoncodes irrespective of patient demographics----- STEP 2: Get patient demographic and cost details for those top 3 codes--SELECT    e.REASONCODE,    e.REASONDESCRIPTION,    p.GENDER,    p.RACE,    p.ETHNICITY,    COUNT(e.id) AS total_encounters,  -----it shows the number of rows according to group by /for that group----    ROUND(SUM(e.TOTAL_CLAIM_COST),2) AS total_cost,    ROUND(AVG(e.TOTAL_CLAIM_COST),2) AS avg_costFROM    encounters eJOIN    patients p ON e.PATIENT = p.Id
WHERE    e.REASONCODE IN (SELECT REASONCODE FROM top_3_reasons)    AND e.TOTAL_CLAIM_COST > 10000                                       --Only consider high-cost encountersGROUP BY    e.REASONCODE, e.REASONDESCRIPTION, p.GENDER, p.RACE, p.ETHNICITYORDER BY    e.REASONCODE,    total_cost DESC;


---4 Assessing Payer Contributions for Different Procedure TypesWITH procedure_base_costs AS (  SELECT ENCOUNTER, SUM(BASE_COST) AS total_base_cost  FROM procedures  GROUP BY ENCOUNTER)SELECT  e.Id AS encounter_id,  pa.NAME AS payer_name,  pbc.total_base_cost,  e.TOTAL_CLAIM_COST,  e.PAYER_COVERAGE,  (e.TOTAL_CLAIM_COST - e.PAYER_COVERAGE) AS uncovered_cost,  ROUND(    (CAST(e.PAYER_COVERAGE AS FLOAT) / NULLIF(pbc.total_base_cost, 0)) * 100, 2  ) AS coverage_percent_of_base_costFROM encounters eJOIN procedure_base_costs pbc ON e.Id = pbc.ENCOUNTERJOIN payers pa ON e.PAYER = pa.IdWHERE e.TOTAL_CLAIM_COST IS NOT NULL  AND e.PAYER_COVERAGE IS NOT NULL  AND pbc.total_base_cost > 0;
--- 5 Identifying Patients with Multiple Procedures Across EncountersSELECT  PATIENT,  REASONCODE,  REASONDESCRIPTION,  COUNT(DISTINCT ENCOUNTER) AS encounter_countFROM proceduresWHERE REASONCODE IS NOT NULLGROUP BY PATIENT, REASONCODE, REASONDESCRIPTIONHAVING COUNT(DISTINCT ENCOUNTER) > 1ORDER BY encounter_count DESC;

----6 Analyzing Patient Encounter Duration for Different Classes -- Step 1: Calculate duration for each encounterWITH encounter_durations AS (  SELECT    Id AS encounter_id,    ORGANIZATION,    ENCOUNTERCLASS,    START,    STOP,   ROUND(DATEDIFF(DAY, START, STOP), 2) AS duration_days  FROM encounters  WHERE START IS NOT NULL AND STOP IS NOT NULL),-- Step 2: Calculate average duration per organization + encounter classclass_avg AS (  SELECT    ORGANIZATION,    ENCOUNTERCLASS,    ROUND(AVG(duration_days), 2) AS avg_duration_days  FROM encounter_durations  GROUP BY ORGANIZATION, ENCOUNTERCLASS)-- Step 3: Final output with everything in one tableSELECT  ed.encounter_id,  ed.ORGANIZATION,  ed.ENCOUNTERCLASS,  ROUND(ed.duration_days, 2) AS duration_days,  ca.avg_duration_days,
CASE     WHEN ed.duration_days > 1 THEN 'Yes'    ELSE 'No'  END AS exceeds_24hrsFROM encounter_durations edJOIN class_avg ca  ON ed.ORGANIZATION = ca.ORGANIZATION AND ed.ENCOUNTERCLASS = ca.ENCOUNTERCLASSORDER BY ed.duration_days DESC;select max(salary) as second_hiegh_salaryfrom emloyeewhere salary > (select(max(salary) from emloyee);