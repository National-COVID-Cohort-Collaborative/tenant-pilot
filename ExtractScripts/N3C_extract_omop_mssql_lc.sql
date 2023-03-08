/**
OMOP v5.3.1 extraction code for N3C Clinical Pilot
Author: Kristin Kostka, Robert Miller, Emily Pfaff

HOW TO RUN:
If you are not using the R or Python exporters, you will need to find and replace @cdmDatabaseSchema and @resultsDatabaseSchema with your local OMOP schema details

USER NOTES:
This extract pulls the following OMOP tables: person, observation_period, visit_occurrence, condition_occurrence, drug_exposure, procedure_occurrence, measurement, observation, location, care_site, provider, death, drug_era, condition_era
As an OMOP site, you are expected to be populating derived tables (observation_period, drug_era, condition_era)
Please refer to the OMOP site instructions for assistance on how to generate these tables.


SCRIPT ASSUMPTIONS:
1. You have already built the n3c_clinical_cohort table (with that name) prior to running this extract
2. You are extracting data with a lookback period to 1-1-2018
3. You have existing tables for each of these extracted tables. If you do not, at a minimum, you MUST create a shell table so it can extract an empty table. Failure to create shells for missing table will result in ingestion problems.
**/

--MANIFEST TABLE: CHANGE PER YOUR SITE'S SPECS
--OUTPUT_FILE: MANIFEST.csv
select
   '@siteAbbrev' as SITE_ABBREV,
   '@siteName'    AS SITE_NAME,
   '@contactName' as CONTACT_NAME,
   '@contactEmail' as CONTACT_EMAIL,
   '@cdmName' as CDM_NAME,
   '@cdmVersion' as CDM_VERSION,
   (SELECT TOP 1 vocabulary_version FROM @resultsDatabaseSchema.n3c_pre_cohort) AS VOCABULARY_VERSION,
   null as N3C_PHENOTYPE_YN,
   null as N3C_PHENOTYPE_VERSION,
   '@shiftDateYN' as SHIFT_DATE_YN,
   '@maxNumShiftDays' as MAX_NUM_SHIFT_DAYS,
   CAST(GETDATE() as datetime) as RUN_DATE,
   CAST( DATEADD(day, -@dataLatencyNumDays, GETDATE()) as datetime) as UPDATE_DATE,	--change integer based on your site's data latency
   CAST( DATEADD(day, @daysBetweenSubmissions, GETDATE()) as datetime) as NEXT_SUBMISSION_DATE;

--person
--OUTPUT_FILE: person.csv
SELECT
   p.person_ID,
   GENDER_CONCEPT_ID,
   ISNULL(YEAR_OF_BIRTH, DATEPART(year, birth_datetime )) as YEAR_OF_BIRTH,
   ISNULL(MONTH_OF_BIRTH, DATEPART(month, birth_datetime)) as MONTH_OF_BIRTH,
   RACE_CONCEPT_ID,
   ETHNICITY_CONCEPT_ID,
   location_ID,
   provider_ID,
   care_site_ID,
   NULL as person_SOURCE_VALUE,
   GENDER_SOURCE_VALUE,
   RACE_SOURCE_VALUE,
   RACE_SOURCE_CONCEPT_ID,
   ETHNICITY_SOURCE_VALUE,
   ETHNICITY_SOURCE_CONCEPT_ID
  FROM @cdmDatabaseSchema.person p
  JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
    ON p.person_ID = n.person_ID;

--observation_period
--OUTPUT_FILE: observation_period.csv
SELECT
   observation_period_ID,
   p.person_ID,
   CAST(observation_period_START_DATE as datetime) as observation_period_START_DATE,
   CAST(observation_period_END_DATE as datetime) as observation_period_END_DATE,
   PERIOD_TYPE_CONCEPT_ID
 FROM @cdmDatabaseSchema.observation_period p
 JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
   ON p.person_ID = n.person_ID
   AND (
   observation_period_START_DATE >= DATEFROMPARTS(2018,01,01)
      OR
   observation_period_END_DATE >= DATEFROMPARTS(2018,01,01)
   );

--visit_occurrence
--OUTPUT_FILE: visit_occurrence.csv
SELECT
   visit_occurrence_ID,
   n.person_ID,
   VISIT_CONCEPT_ID,
   CAST(VISIT_START_DATE as datetime) as VISIT_START_DATE,
   CAST(VISIT_START_DATETIME as datetime) as VISIT_START_DATETIME,
   CAST(VISIT_END_DATE as datetime) as VISIT_END_DATE,
   CAST(VISIT_END_DATETIME as datetime) as VISIT_END_DATETIME,
   VISIT_TYPE_CONCEPT_ID,
   provider_ID,
   care_site_ID,
   VISIT_SOURCE_VALUE,
   VISIT_SOURCE_CONCEPT_ID,
   ADMITTING_SOURCE_CONCEPT_ID,
   ADMITTING_SOURCE_VALUE,
   DISCHARGE_TO_CONCEPT_ID,
   DISCHARGE_TO_SOURCE_VALUE,
   PRECEDING_visit_occurrence_ID
FROM @cdmDatabaseSchema.visit_occurrence v
JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
  ON v.person_ID = n.person_ID
WHERE v.VISIT_START_DATE >= DATEFROMPARTS(2018,01,01);

--condition_occurrence
--OUTPUT_FILE: condition_occurrence.csv
SELECT
   condition_occurrence_ID,
   n.person_ID,
   CONDITION_CONCEPT_ID,
   CAST(CONDITION_START_DATE as datetime) as CONDITION_START_DATE,
   CAST(CONDITION_START_DATETIME as datetime) as CONDITION_START_DATETIME,
   CAST(CONDITION_END_DATE as datetime) as CONDITION_END_DATE,
   CAST(CONDITION_END_DATETIME as datetime) as CONDITION_END_DATETIME,
   CONDITION_TYPE_CONCEPT_ID,
   CONDITION_STATUS_CONCEPT_ID,
   NULL as STOP_REASON,
   visit_occurrence_ID,
   NULL as VISIT_DETAIL_ID,
   CONDITION_SOURCE_VALUE,
   CONDITION_SOURCE_CONCEPT_ID,
   NULL as CONDITION_STATUS_SOURCE_VALUE
FROM @cdmDatabaseSchema.condition_occurrence co
JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
  ON CO.person_id = n.person_id
WHERE co.CONDITION_START_DATE >= DATEFROMPARTS(2018,01,01);

--drug_exposure
--OUTPUT_FILE: drug_exposure.csv
SELECT
   drug_exposure_ID,
   n.person_ID,
   DRUG_CONCEPT_ID,
   CAST(drug_exposure_START_DATE as datetime) as drug_exposure_START_DATE,
   CAST(drug_exposure_START_DATETIME as datetime) as drug_exposure_START_DATETIME,
   CAST(drug_exposure_END_DATE as datetime) as drug_exposure_END_DATE,
   CAST(drug_exposure_END_DATETIME as datetime) as drug_exposure_END_DATETIME,
   DRUG_TYPE_CONCEPT_ID,
   NULL as STOP_REASON,
   REFILLS,
   QUANTITY,
   DAYS_SUPPLY,
   NULL as SIG,
   ROUTE_CONCEPT_ID,
   LOT_NUMBER,
   provider_ID,
   visit_occurrence_ID,
   null as VISIT_DETAIL_ID,
   DRUG_SOURCE_VALUE,
   DRUG_SOURCE_CONCEPT_ID,
   ROUTE_SOURCE_VALUE,
   DOSE_UNIT_SOURCE_VALUE
FROM @cdmDatabaseSchema.drug_exposure de
JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
  ON de.person_ID = n.person_ID
WHERE de.drug_exposure_START_DATE >= DATEFROMPARTS(2018,01,01);

--DEVICE_EXPOSURE
--OUTPUT_FILE: DEVICE_EXPOSURE.csv
SELECT
   DEVICE_EXPOSURE_ID,
   n.person_ID,
   DEVICE_CONCEPT_ID,
   CAST(DEVICE_EXPOSURE_START_DATE as datetime) as DEVICE_EXPOSURE_START_DATE,
   CAST(DEVICE_EXPOSURE_START_DATETIME as datetime) as DEVICE_EXPOSURE_START_DATETIME,
   CAST(DEVICE_EXPOSURE_END_DATE as datetime) as DEVICE_EXPOSURE_END_DATE,
   CAST(DEVICE_EXPOSURE_END_DATETIME as datetime) as DEVICE_EXPOSURE_END_DATETIME,
   DEVICE_TYPE_CONCEPT_ID,
   NULL as UNIQUE_DEVICE_ID,
   QUANTITY,
   provider_ID,
   visit_occurrence_ID,
   NULL as VISIT_DETAIL_ID,
   DEVICE_SOURCE_VALUE,
   DEVICE_SOURCE_CONCEPT_ID
FROM @cdmDatabaseSchema.DEVICE_EXPOSURE de
JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
  ON de.person_ID = n.person_ID
WHERE de.DEVICE_EXPOSURE_START_DATE >= DATEFROMPARTS(2018,01,01);

--procedure_occurrence
--OUTPUT_FILE: procedure_occurrence.csv
SELECT
   procedure_occurrence_ID,
   n.person_ID,
   PROCEDURE_CONCEPT_ID,
   CAST(PROCEDURE_DATE as datetime) as PROCEDURE_DATE,
   CAST(PROCEDURE_DATETIME as datetime) as PROCEDURE_DATETIME,
   PROCEDURE_TYPE_CONCEPT_ID,
   MODIFIER_CONCEPT_ID,
   QUANTITY,
   provider_ID,
   visit_occurrence_ID,
   NULL as VISIT_DETAIL_ID,
   PROCEDURE_SOURCE_VALUE,
   PROCEDURE_SOURCE_CONCEPT_ID,
   NULL as MODIFIER_SOURCE_VALUE
FROM @cdmDatabaseSchema.procedure_occurrence po
JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
  ON PO.person_ID = N.person_ID
WHERE po.PROCEDURE_DATE >= DATEFROMPARTS(2018,01,01);

--measurement
--OUTPUT_FILE: measurement.csv
SELECT
   measurement_ID,
   n.person_ID,
   measurement_CONCEPT_ID,
   CAST(measurement_DATE as datetime) as measurement_DATE,
   CAST(measurement_DATETIME as datetime) as measurement_DATETIME,
   NULL as measurement_TIME,
   measurement_TYPE_CONCEPT_ID,
   OPERATOR_CONCEPT_ID,
   VALUE_AS_NUMBER,
   VALUE_AS_CONCEPT_ID,
   UNIT_CONCEPT_ID,
   RANGE_LOW,
   RANGE_HIGH,
   provider_ID,
   visit_occurrence_ID,
   NULL as VISIT_DETAIL_ID,
   measurement_SOURCE_VALUE,
   measurement_SOURCE_CONCEPT_ID,
   NULL as UNIT_SOURCE_VALUE,
   NULL as VALUE_SOURCE_VALUE
FROM @cdmDatabaseSchema.measurement m
JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
  ON M.person_ID = N.person_ID
WHERE m.measurement_DATE >= DATEFROMPARTS(2018,01,01);

--observation
--OUTPUT_FILE: observation.csv
SELECT
   observation_ID,
   n.person_ID,
   observation_CONCEPT_ID,
   CAST(observation_DATE as datetime) as observation_DATE,
   CAST(observation_DATETIME as datetime) as observation_DATETIME,
   observation_TYPE_CONCEPT_ID,
   VALUE_AS_NUMBER,
   VALUE_AS_STRING,
   VALUE_AS_CONCEPT_ID,
   QUALIFIER_CONCEPT_ID,
   UNIT_CONCEPT_ID,
   provider_ID,
   visit_occurrence_ID,
   NULL as VISIT_DETAIL_ID,
   observation_SOURCE_VALUE,
   observation_SOURCE_CONCEPT_ID,
   NULL as UNIT_SOURCE_VALUE,
   NULL as QUALIFIER_SOURCE_VALUE
FROM @cdmDatabaseSchema.observation o
JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
  ON O.person_ID = N.person_ID
WHERE o.observation_DATE >= DATEFROMPARTS(2018,01,01);

--death
--OUTPUT_FILE: death.csv
SELECT
   n.person_ID,
    CAST(death_DATE as datetime) as death_DATE,
	CAST(death_DATETIME as datetime) as death_DATETIME,
	death_TYPE_CONCEPT_ID,
	CAUSE_CONCEPT_ID,
	NULL as CAUSE_SOURCE_VALUE,
	CAUSE_SOURCE_CONCEPT_ID
FROM @cdmDatabaseSchema.death d
JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
ON D.person_ID = N.person_ID
WHERE d.death_DATE >= DATEFROMPARTS(2018,01,01);

--location
--OUTPUT_FILE: location.csv
SELECT
   l.location_ID,
   null as ADDRESS_1, -- to avoid identifying information
   null as ADDRESS_2, -- to avoid identifying information
   CITY,
   STATE,
   ZIP,
   COUNTY,
   NULL as location_SOURCE_VALUE
FROM @cdmDatabaseSchema.location l
JOIN (
        SELECT DISTINCT p.location_ID
        FROM @cdmDatabaseSchema.person p
        JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
          ON p.person_id = n.person_id
      ) a
  ON l.location_id = a.location_id
;

--care_site
--OUTPUT_FILE: care_site.csv
SELECT
   cs.care_site_ID,
   care_site_NAME,
   PLACE_OF_SERVICE_CONCEPT_ID,
   NULL as location_ID,
   NULL as care_site_SOURCE_VALUE,
   NULL as PLACE_OF_SERVICE_SOURCE_VALUE
FROM @cdmDatabaseSchema.care_site cs
JOIN (
        SELECT DISTINCT care_site_ID
        FROM @cdmDatabaseSchema.visit_occurrence vo
        JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
          ON vo.person_id = n.person_id
      ) a
  ON cs.care_site_ID = a.care_site_ID
;

--provider
--OUTPUT_FILE: provider.csv
SELECT
   pr.provider_ID,
   null as provider_NAME, -- to avoid accidentally identifying sites
   null as NPI, -- to avoid accidentally identifying sites
   null as DEA, -- to avoid accidentally identifying sites
   SPECIALTY_CONCEPT_ID,
   care_site_ID,
   null as YEAR_OF_BIRTH,
   GENDER_CONCEPT_ID,
   null as provider_SOURCE_VALUE, -- to avoid accidentally identifying sites
   SPECIALTY_SOURCE_VALUE,
   SPECIALTY_SOURCE_CONCEPT_ID,
   GENDER_SOURCE_VALUE,
   GENDER_SOURCE_CONCEPT_ID
FROM @cdmDatabaseSchema.provider pr
JOIN (
       SELECT DISTINCT provider_ID
       FROM @cdmDatabaseSchema.visit_occurrence vo
       JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
          ON vo.person_ID = n.person_ID
       UNION
       SELECT DISTINCT provider_ID
       FROM @cdmDatabaseSchema.drug_exposure de
       JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
          ON de.person_ID = n.person_ID
       UNION
       SELECT DISTINCT provider_ID
       FROM @cdmDatabaseSchema.measurement m
       JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
          ON m.person_ID = n.person_ID
       UNION
       SELECT DISTINCT provider_ID
       FROM @cdmDatabaseSchema.procedure_occurrence po
       JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
          ON po.person_ID = n.person_ID
       UNION
       SELECT DISTINCT provider_ID
       FROM @cdmDatabaseSchema.observation o
       JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
          ON o.person_ID = n.person_ID
     ) a
 ON pr.provider_ID = a.provider_ID
;

--drug_era
--OUTPUT_FILE: drug_era.csv
SELECT
   drug_era_ID,
   n.person_ID,
   DRUG_CONCEPT_ID,
   CAST(drug_era_START_DATE as datetime) as drug_era_START_DATE,
   CAST(drug_era_END_DATE as datetime) as drug_era_END_DATE,
   drug_exposure_COUNT,
   GAP_DAYS
FROM @cdmDatabaseSchema.drug_era dre
JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
  ON DRE.person_ID = N.person_ID
WHERE drug_era_START_DATE >= DATEFROMPARTS(2018,01,01);

--condition_era
--OUTPUT_FILE: condition_era.csv
SELECT
   condition_era_ID,
   n.person_ID,
   CONDITION_CONCEPT_ID,
   CAST(condition_era_START_DATE as datetime) as condition_era_START_DATE,
   CAST(condition_era_END_DATE as datetime) as condition_era_END_DATE,
   condition_occurrence_COUNT
FROM @cdmDatabaseSchema.condition_era ce JOIN @resultsDatabaseSchema.n3c_clinical_cohort n ON CE.person_ID = N.person_ID
WHERE condition_era_START_DATE >= DATEFROMPARTS(2018,01,01);

--DATA_COUNTS TABLE
--OUTPUT_FILE: DATA_COUNTS.csv
SELECT * from
(select
   'person' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.person p JOIN @resultsDatabaseSchema.n3c_clinical_cohort n ON p.person_ID = n.person_ID) as ROW_COUNT

UNION

select
   'observation_period' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.observation_period op JOIN @resultsDatabaseSchema.n3c_clinical_cohort n ON op.person_ID = n.person_ID AND (observation_period_START_DATE >= DATEFROMPARTS(2018,01,01) OR observation_period_END_DATE >= DATEFROMPARTS(2018,01,01)) ) as ROW_COUNT

UNION

select
   'visit_occurrence' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.visit_occurrence vo JOIN @resultsDatabaseSchema.n3c_clinical_cohort n ON vo.person_ID = n.person_ID AND VISIT_START_DATE >= DATEFROMPARTS(2018,01,01)) as ROW_COUNT

UNION

select
   'condition_occurrence' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.condition_occurrence co JOIN @resultsDatabaseSchema.n3c_clinical_cohort n ON co.person_ID = n.person_ID AND CONDITION_START_DATE >= DATEFROMPARTS(2018,01,01)) as ROW_COUNT

UNION

select
   'drug_exposure' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.drug_exposure de JOIN @resultsDatabaseSchema.n3c_clinical_cohort n ON de.person_ID = n.person_ID AND drug_exposure_START_DATE >= DATEFROMPARTS(2018,01,01)) as ROW_COUNT

UNION

select
   'DEVICE_EXPOSURE' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.DEVICE_EXPOSURE de JOIN @resultsDatabaseSchema.n3c_clinical_cohort n ON de.person_ID = n.person_ID AND DEVICE_EXPOSURE_START_DATE >= DATEFROMPARTS(2018,01,01)) as ROW_COUNT

UNION

select
   'procedure_occurrence' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.procedure_occurrence po JOIN @resultsDatabaseSchema.n3c_clinical_cohort n ON po.person_ID = n.person_ID AND PROCEDURE_DATE >= DATEFROMPARTS(2018,01,01)) as ROW_COUNT

UNION

select
   'measurement' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.measurement m JOIN @resultsDatabaseSchema.n3c_clinical_cohort n ON m.person_ID = n.person_ID AND measurement_DATE >= DATEFROMPARTS(2018,01,01)) as ROW_COUNT

UNION

select
   'observation' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.observation o JOIN @resultsDatabaseSchema.n3c_clinical_cohort n ON o.person_ID = n.person_ID AND observation_DATE >= DATEFROMPARTS(2018,01,01)) as ROW_COUNT

UNION

SELECT
   'death' as TABLE_NAME,
  (select count(*) from @cdmDatabaseSchema.death d JOIN @resultsDatabaseSchema.n3c_clinical_cohort n ON d.person_ID = n.person_ID AND death_DATE >= DATEFROMPARTS(2018,01,01)) as ROW_COUNT

UNION

select
   'location' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.location l
   JOIN (
        SELECT DISTINCT p.location_ID
        FROM @cdmDatabaseSchema.person p
        JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
          ON p.person_id = n.person_id
      ) a
  ON l.location_id = a.location_id) as ROW_COUNT

UNION

select
   'care_site' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.care_site cs
	JOIN (
        SELECT DISTINCT care_site_ID
        FROM @cdmDatabaseSchema.visit_occurrence vo
        JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
          ON vo.person_id = n.person_id
      ) a
  ON cs.care_site_ID = a.care_site_ID) as ROW_COUNT

UNION

 select
   'provider' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.provider pr
	JOIN (
       SELECT DISTINCT provider_ID
       FROM @cdmDatabaseSchema.visit_occurrence vo
       JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
          ON vo.person_ID = n.person_ID
       UNION
       SELECT DISTINCT provider_ID
       FROM @cdmDatabaseSchema.drug_exposure de
       JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
          ON de.person_ID = n.person_ID
       UNION
       SELECT DISTINCT provider_ID
       FROM @cdmDatabaseSchema.measurement m
       JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
          ON m.person_ID = n.person_ID
       UNION
       SELECT DISTINCT provider_ID
       FROM @cdmDatabaseSchema.procedure_occurrence po
       JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
          ON po.person_ID = n.person_ID
       UNION
       SELECT DISTINCT provider_ID
       FROM @cdmDatabaseSchema.observation o
       JOIN @resultsDatabaseSchema.n3c_clinical_cohort n
          ON o.person_ID = n.person_ID
     ) a
 ON pr.provider_ID = a.provider_ID) as ROW_COUNT

UNION

select
   'drug_era' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.drug_era de JOIN @resultsDatabaseSchema.n3c_clinical_cohort n ON de.person_ID = n.person_ID AND drug_era_START_DATE >= DATEFROMPARTS(2018,01,01)) as ROW_COUNT

UNION

select
   'condition_era' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.condition_era JOIN @resultsDatabaseSchema.n3c_clinical_cohort ON condition_era.person_ID = n3c_clinical_cohort.person_ID AND condition_era_START_DATE >= DATEFROMPARTS(2018,01,01)) as ROW_COUNT
) s;

