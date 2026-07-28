# 1: Import the data and then remove all the duplicates

# 1.1 Create a duplicate table for cleaning
CREATE OR REPLACE TABLE 
  `sql-demo-projects.sql_portofolio.stage1_auto_insurance_claims_data`
AS SELECT
  * 
FROM
  `sql-demo-projects.sql_portofolio.auto_insurance_claims_data`;

# 1.2 Remove all duplicates
CREATE OR REPLACE TABLE
  `sql-demo-projects.sql_portofolio.stage2_auto_insurance_claims_data`
AS SELECT
  DISTINCT * 
FROM
  `sql-demo-projects.sql_portofolio.stage1_auto_insurance_claims_data`;


# 2: Schema and Structure Clean up.

# 2.1 Standardize column name conventions
CREATE OR REPLACE TABLE 
  `sql-demo-projects.sql_portofolio.stage3_auto_insurance_claims_data`
AS SELECT 
  # primary keys
  policy_number,
  months_as_customer,
  age,
  policy_bind_date,
  policy_state,

  #Split policy_csl into two columns
  CAST(SPLIT(policy_csl, '/')[OFFSET(0)] AS INT64) * 1000 AS csl_per_person,
  CAST(SPLIT(policy_csl, '/')[OFFSET(1)] AS INT64) * 1000 AS csl_per_accident, 
  
  policy_deductable,
  policy_annual_premium,
  umbrella_limit,
  insured_zip,
  insured_sex,
  insured_education_level,
  insured_occupation,
  insured_hobbies,
  insured_relationship,

  # Fix column names right here
  `capital-gains` AS capital_gains,
  `capital-loss` AS capital_loss,

  incident_date,
  incident_type,
  collision_type,
  incident_severity,
  authorities_contacted,
  incident_state,
  incident_city,
  incident_location,
  incident_hour_of_the_day,
  number_of_vehicles_involved,
  property_damage,
  bodily_injuries,
  witnesses,
  police_report_available,
  total_claim_amount,
  injury_claim,
  property_claim,
  vehicle_claim,
  auto_make,
  auto_model,
  auto_year,
  fraud_reported

  # Intentially leaving out _c39 column due to it being phantom
FROM
  `sql-demo-projects.sql_portofolio.stage2_auto_insurance_claims_data`;


# 2.2 Fill in missing values (Replace '?' with NULL values)

# The best method to use here is update statement but since we have the free version we need to use create or replace
CREATE OR REPLACE TABLE 
  `sql-demo-projects.sql_portofolio.stage4_auto_insurance_claims_data`
AS SELECT
  policy_number,
  months_as_customer,
  age,
  policy_bind_date,
  policy_state,
  csl_per_person,
  csl_per_accident, 
  policy_deductable,
  policy_annual_premium,
  umbrella_limit,
  insured_zip,
  insured_sex,
  insured_education_level,
  insured_occupation,
  insured_hobbies,
  insured_relationship,
  capital_gains,
  capital_loss,
  incident_date,
  incident_type,

  # Fill in values when there are ? for the collision type
  CASE 
    WHEN collision_type = '?' THEN NULL 
    ELSE collision_type 
  END AS collision_type,

  incident_severity,
  authorities_contacted,
  incident_state,
  incident_city,
  incident_location,
  incident_hour_of_the_day,
  number_of_vehicles_involved,

  # Fill in values when there are ? for property damage. For the rest of the values convert them to boolean values
  CASE 
    WHEN property_damage = '?' THEN NULL 
    WHEN property_damage = "YES" THEN TRUE
    WHEN property_damage = "NO" THEN FALSE 
  END AS property_damage,

  bodily_injuries,
  witnesses,

  # Fill in values when there are ? for police report available. For the rest of the values convert them to boolean values
  CASE 
    WHEN police_report_available = '?' THEN NULL 
    WHEN police_report_available = "NO" THEN FALSE
    WHEN police_report_available = "YES" THEN TRUE 
  END AS police_report_available,

  total_claim_amount,
  injury_claim,
  property_claim,
  vehicle_claim,
  auto_make,
  auto_model,
  auto_year,
  fraud_reported
FROM
  `sql-demo-projects.sql_portofolio.stage3_auto_insurance_claims_data`;

# 3: Business Logic Filtering for the data. In this stage, we must check whether data is integral according to business logic

# Rotate Through each column to see if there are any weird conditions
SELECT
  * 
FROM
  `sql-demo-projects.sql_portofolio.stage4_auto_insurance_claims_data`
WHERE
  months_as_customer < 0 OR
  age < 0 OR
  NOT REGEXP_CONTAINS(CAST(policy_number AS STRING), r'^[0-9]{6}') AND
  policy_bind_date > incident_date OR
  csl_per_person < 0 OR
  csl_per_accident < 0 OR
  umbrella_limit < 0 OR
  NOT REGEXP_CONTAINS(CAST(insured_zip AS STRING), r'^[0-9]{6}') OR
  incident_hour_of_the_day < 0 OR
  incident_hour_of_the_day > 24 OR
  number_of_vehicles_involved < 0 OR
  bodily_injuries < 0 OR
  witnesses < 0 OR
  total_claim_amount < 0 OR
  injury_claim < 0 OR
  property_claim < 0 OR
  vehicle_claim < 0 OR
  auto_year < 0;

# We found two rows. 
# Policy number 794731 has policy bind date 2015-02-22 but the incident date is 2015-02-02 which is not logically coherent since the customer must be insured before the accident occurs
# The other person has an unmbrella_limit that is less than 0
# Since there are only two rows like this that violate business logic, they will be removed from the dataset


# Create another table to eliminate those two conditions
CREATE OR REPLACE TABLE
  `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
AS SELECT
  * 
FROM
  `sql-demo-projects.sql_portofolio.stage4_auto_insurance_claims_data`
WHERE
  policy_bind_date <= incident_date AND umbrella_limit >= 0;

SELECT * FROM `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`;

# The result is visibly passing all data quality checks. The data is also uploaded to Gemini for further verifications and it appears to be passing.