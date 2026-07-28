# Display the current dataset before we dive in
SELECT 
  *
FROM 
  `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data` 
LIMIT 1000;

# This SQL is where we will dive in and make useful analysis regarding this project

# 1: Portofolio & Under-writing performance

/*
Overall & Segment Loss Ratio
1.1 Calculate the loss ratio (total claims / total premiums) aggregated by State, Driver Age Group, Demographic cohorts and Vehicle Make
1.2 Claim Severity: Calculate the average dollar payout per claim across different incident types
1.3 Pure Premium (Loss Cost): Mutiply frequency by severity to determine the expected loss cost per policy group
*/

# 1.1 Loss Ratio: Total Claims / Total Premiums
# Definition: Loss Ratio is the proportion of collected premium that is consumed by policyholders claim. Basically how much money that is earned got consuemd by accidents
# Total claims is the money that is consumed by accidents
# Total premiums is the money that is paid by the policyholders

# a. This is the total loss ratio aggregated together
SELECT
  SUM(total_claim_amount) AS total_claim_amount,
  SUM(policy_annual_premium) AS policy_annual_premium_sum,
  ROUND(SUM(total_claim_amount) / SUM(policy_annual_premium), 2) * 100 AS total_loss_ratio
FROM
  `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`;

# From the result we can see that the total loss ratio is around 4196%. This is due to data limitation, selection bias. Since the claim rate in this dataset is 100%, every single policyholder has been through some some accidents. In a real world scenario. This enormous total loss ratio would be offsetted by people who never filed a claim throughtout the entire year. In this case, we are going to treat this number as a performance baseline and evaluate this against other loss ratio to see relatively better performance or worse performance

# b. This is the loss ratio aggregated based on each state
SELECT
  policy_state,
  SUM(total_claim_amount) AS total_claim_amount,
  SUM(policy_annual_premium) AS policy_annual_premium_sum,
  ROUND(SUM(total_claim_amount) / SUM(policy_annual_premium), 2) * 100 AS state_loss_ratio,
  CASE
    WHEN ROUND(SUM(total_claim_amount) / SUM(policy_annual_premium), 2) * 100 < 4196 THEN TRUE
    ELSE FALSE
  END AS better_than_national_average
FROM
  `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
GROUP BY
  policy_state
ORDER BY
  state_loss_ratio DESC;

# The result of this query shows that there are only three states in this entire dataset. This is another concerning limitation that we have with our data, since this data does not represent the national loss ratio well. 
# Among these three states, IN has the highest loss ratio, followed by IL and lastly OH. Among these three states, IN and IL performs worse than the three-state-averages

# c.Discover if there are claims that are made outside of these states
SELECT
  incident_state,
  COUNT(incident_state) AS claims_count,
  ROUND(COUNT(incident_state) / (SELECT COUNT(incident_state) FROM `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`), 2) * 100 AS occurence_share
FROM
  `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
GROUP BY 
  incident_state
ORDER BY
  incident_state ASC;

# Result shows that there are seven states that incidents have been reported.
# What is interesting is that there are no incidents reported from IN or IL, and also OH has only 2% of the total claims. This is impossible in the real world, which means that there is a great possibility that the data is fabricated or pre-filtered already before uploading online.
# Evidence: According to Progressive Insurance, 52% of accidents happenw within 5 miles to home or less. 77% percent of accidents occur within 15 miles or less.
# The dataset might be focusing on policyholders from three states (IN, IL, OH) that have claims outside of their residential states.

WITH out_of_state AS (
  SELECT
    "out_of_state" AS state_status,
    COUNT(incident_state) AS number_of_occurence,
    ROUND(SUM(total_claim_amount) / SUM(policy_annual_premium), 2) * 100 AS loss_ratio
  FROM
    `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
  WHERE
  policy_state != incident_state
), in_state AS (
  SELECT
    "in_state" AS state_status,
    COUNT(incident_state) AS number_of_occurence,
    ROUND(SUM(total_claim_amount) / SUM(policy_annual_premium), 2) * 100 AS loss_ratio
  FROM
    `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
  WHERE
    policy_state = incident_state
)

SELECT * FROM out_of_state
UNION ALL
SELECT * FROM in_state;

# From this result, we can see that the majority of claims are actually filed out of the policyholders' states. Out of state claims have lower loss ratio and in state claims have a higher loss ratio.

# d. Run over loss ratio performance group by Driver Age Group
WITH age_group AS (
  SELECT
    policy_number,
    age,
    CASE 
      WHEN age <= 19 THEN "Teens"
      WHEN age >= 20 AND age <= 24 THEN "Young Adults"
      WHEN age >= 25 AND age <= 39 THEN "Experienced Drivers"
      WHEN age >= 40 AND age <= 64 THEN "Middle-Aged"
      WHEN age >= 65 THEN "Seniors"
    END AS age_category,
    total_claim_amount,
    policy_annual_premium
  FROM
    `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
)

SELECT
  age_category,
  SUM(total_claim_amount) AS total_claim_amount,
  SUM(policy_annual_premium) AS total_annual_premium,
  ROUND(SUM(total_claim_amount) / SUM(policy_annual_premium), 2) * 100 AS loss_ratio,
  ROUND(COUNT(age_category) / (SELECT COUNT(age_category) FROM age_group), 2) AS age_percentage
FROM
  age_group
GROUP BY
  age_category;

# From this query, we can see that there are very few teens from this dataset and the rounding has equivocated them to 0. Young adults (20 - 24) also take a small share of the whole data. The loss ratio is higher than teens and experienced drivers. However this might also be caused by data limitation. Experienced Drivers takes the majority of the shares in this dataset. Their loss ratio is lower than young adults. Middle aged people compose around 44% of this dataset and their loss ratio, surprisingly, is the highest loss ratio in this dataset. Notice that there is not a single person who is senior in this dataset. This is another limitation to be noticed.
# According to Progressive past statistics, people who are teens have the highest premium, followed by young adults, and then experienced drivers. Seniors have higher premiums than experienced drivers due to age.

# e. Calculate the loss ratio by demographics information (in this dataset, the only demographic information is gender)
SELECT
  insured_sex,
  SUM(total_claim_amount) AS total_claim_amount,
  SUM(policy_annual_premium) AS total_annual_premium,
  ROUND((SUM(total_claim_amount) / SUM(policy_annual_premium)) * 100, 2) AS loss_ratio,
  ROUND((COUNT(insured_sex) / (SELECT COUNT(insured_sex) FROM `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`)) * 100, 2) AS gender_percentage
FROM
  `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
GROUP BY
  insured_sex;

# From this analysis, there are around 54% of female in the group and around 46% of male in the group. Among the limited data, male drivers have a lower loss ratio (4103.75%) than female drivers (4275.67%).

# f. Calculate the loss ratio by veichle makes
SELECT
  auto_make,
  SUM(total_claim_amount) AS total_claim_amount,
  SUM(policy_annual_premium) AS total_annual_premium,
  ROUND((SUM(total_claim_amount) / SUM(policy_annual_premium)) * 100, 2) AS loss_ratio,
  ROUND((COUNT(auto_make) / (SELECT COUNT(auto_make) FROM `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`)) * 100, 2) AS auto_make_percentage
FROM
  `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
GROUP BY
  auto_make
ORDER BY
  loss_ratio DESC;

# From this query, we discovered that there are similar amount of veichle for each veichle_make, with each veichle between 6% and 8% of representation. In total, there are 14 veichle makes in this dataset. From the result, the top three auto make with the highest loss ratio is Ford (4525%), followed by BMW (4494.65%), and then by Dodge (4461.78%)
  


# 1.2 Claim Severity. In this following section, we will be focusing on calculating claim severity. This is defined as the average dollar payout per claim across different incident types.


# a. Investigate what kind of incidents are there.
SELECT
  incident_type,
  SUM(total_claim_amount) AS total_claim_amount,
  ROUND(AVG(total_claim_amount), 2) AS average_claim_amount,
  ROUND(COUNT(incident_type) / (SELECT COUNT(incident_type) FROM `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`), 2) AS percentage_shares
FROM
  `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
GROUP BY
  incident_type
ORDER BY
  average_claim_amount DESC;

# Through this query, we discovered that there are four incident types recorded in this dataset. They are single vehicle collision, multi vehicle collision, Vehicle Theft, and Parked Car. Among these collision types, Single Veichle Collion and Multi Veichle Collision make up the majority of the observations. 
# Among these incident types, single collision has the highest total_claim_amount, followed by mutlti-veichle collisions, vehicle theft and parked car. Since vehicle theft car and parked car only share 9% and 8% of the total observations respectively. It is considered weighted less or represented less among the whole dataset.
# It is very interesting to note that single vehicle collison has higher total claim amount than multi vehicle collision in this dataset. By common understanding, multi vehicle collision will have more total claim amount than single vehicle collision. This needs further investigation as we move on.

# b. For each kind of incident, what kind of severity are there
WITH CTE AS (
  SELECT
    incident_type,
    incident_severity,
    SUM(total_claim_amount) OVER (PARTITION BY incident_type, incident_severity) AS total_claim_amount,
    AVG(total_claim_amount) OVER (PARTITION BY incident_type, incident_severity) AS average_claim_amount,
    COUNT(incident_severity) OVER (PARTITION BY incident_type, incident_severity) AS incident_occurence_per_severity,
    COUNT(incident_severity) OVER (PARTITION BY incident_type) AS total_occurence
  FROM
    `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
  ORDER BY
    incident_type ASC, incident_severity ASC
)

SELECT
  incident_type,
  incident_severity,
  total_claim_amount,
  average_claim_amount,
  incident_occurence_per_severity,
  total_occurence,
  ROUND(incident_occurence_per_severity / total_occurence, 2) AS likelihood
FROM
  CTE
GROUP BY
  incident_type, 
  incident_severity, 
  total_claim_amount, 
  average_claim_amount, 
  incident_occurence_per_severity, 
  total_occurence
ORDER BY 
  incident_type ASC, incident_severity ASC;

# From this query, we have discovered that for muti-veichle collision and single vehicle collision. The amount of collision for each incident severity is quite similar (around 1/3 for each incident severity). This could mean a couple of reasons.
# 1. Single collision causes the driver to absorb all the damage which means that the claim cost is going to be higher
# 2. Single collision eases the way to fraud insurance comapny, but further validation is needed.

# c. lastly we are going to find pure premium (severeity * frequency)
WITH CTE AS (
  SELECT
    incident_severity,
    SUM(total_claim_amount) AS total_claim_amount,
    COUNT(incident_severity) AS frequency
  FROM
    `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
  GROUP BY
    incident_severity
)

SELECT
  incident_severity,
  total_claim_amount,
  frequency,
  total_claim_amount * frequency AS expected_value
FROM
  CTE
ORDER BY
  expected_value DESC;

# From this query, we have discovered that minor damaage actually has the greatest expected value across the whole dataset. This is due to its high frequency of happening and it is logiclly coherent as most accidents are minor accidents. Total loss has the second highest expected value, followed by major damage and lastly trivial damage. Total Loss also accumulates great expected value due to the fact that the car is unusable and it's frequency is higher than major damage. 

# 2. Risk Stratification

# 2.1 Group vehicles by age categories to see how veichle value affects claim cost
WITH CTE AS (
  SELECT
    auto_year,
    CASE
      WHEN 2026 - auto_year <= 5 THEN "New"
      WHEN 2026 - auto_year >= 6 AND 2026 - auto_year <= 12 THEN "Mid"
      WHEN 2026 - auto_year >= 13 THEN "Old"
    END AS year_range,
    total_claim_amount,
  FROM
    `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
)

SELECT
  year_range,
  SUM(total_claim_amount) AS total_claim_amount,
  ROUND(AVG(total_claim_amount), 2) AS average_claim_amount,
  COUNT(year_range) AS occurence_count,
  ROUND(COUNT(year_range) / (SELECT COUNT(year_range) FROM `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`), 2) AS occurence_percentage
FROM
  CTE
GROUP BY
  year_range
ORDER BY
  total_claim_amount DESC;

# From this query, we have learned that 91% of the observations from this dataset are old cars. meaning cars that are older than 13 years, meanwhile the rest of the cars are all middle-aged cars, representing 9% of the total observations. This means that the data can be disapportionately represented. It can be inferred with data limitations, that older cars are more likely to get into accidents, and also their claim amount on average is also higher.

# 2.2 Group vehicles by brand categories to see how vehicle value affects claim cost

SELECT
  auto_make,
  SUM(total_claim_amount) AS total_claim_amount,
  ROUND(AVG(total_claim_amount), 2) AS average_claim_amount,
  COUNT(auto_make) AS occurrence_count,
  ROUND(COUNT(auto_make) / (SELECT COUNT(auto_make) FROM `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`), 2) AS percentage_share
FROM
  `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
GROUP BY
  auto_make
ORDER BY
  average_claim_amount DESC;

# From this query, we have discovered that Ford and Dodge, American auto-makeers, are taking the leaderboard on having the highest claim amount. Meanwhile luxurious German brands such as BMW, Audi are also on the board. Unsurprisingly, Toyota is at the bottom of total claim amount, once again verified its reliability and cheap cost to repair.

# 2.3 Occupation Stratification

SELECT
  insured_occupation,
  SUM(total_claim_amount) AS total_claim_amount,
  ROUND(AVG(total_claim_amount), 2) AS average_claim_amount,
  COUNT(insured_occupation) AS occurrence_count,
  ROUND(COUNT(insured_occupation) / (SELECT COUNT(insured_occupation) FROM `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`), 2) AS percentage_share
FROM
  `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
GROUP BY
  insured_occupation
ORDER BY
  average_claim_amount DESC;
  
# From this query, we discovered that there are 14 unique occupation listed in this dataset. Among these occupation listed. On average, handlers-cleaners have the highest average claim amount (6165833), followed by transport moving (56522.78), and then by exec-managerial (56396.58). Meanwhile, the occupation with the least amount of average claims are adm-clerical (46638.15) and then sales (48977.24).

# 2.4 Education Risk Stratification

SELECT
  insured_education_level,
  SUM(total_claim_amount) AS total_claim_amount,
  ROUND(AVG(total_claim_amount), 2) AS average_claim_amount,
  COUNT(insured_education_level) AS occurrence_count,
  ROUND(COUNT(insured_education_level) / (SELECT COUNT(insured_education_level) FROM `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`), 2) AS percentage_share
FROM
  `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
GROUP BY
  insured_education_level
ORDER BY
  average_claim_amount DESC;

# From this dataset, there aren't really a distinctive pattern among the occupation levels in contrast with average claim amount. As PhD in the dataset has the highest average claim amount and highschool level education are in the middle, and associate are ranked at the bottom. There isn't any apparent correlation and causation in this grouping method.

# 3. Financial Breakdown & Policy Structure Impact

# 3.1 Percentage distribution of claim costs across vehicle claim, injury claim, property claim
SELECT
  incident_type,
  SUM(injury_claim) AS total_injury_claim,
  ROUND(AVG(injury_claim), 2) AS average_injury_claim,
  ROUND(SUM(injury_claim) / (SELECT SUM(total_claim_amount) FROM `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`), 2) AS injury_percentage_share,
  SUM(property_claim) AS total_property_claim,
  ROUND(AVG(property_claim), 2) AS average_property_claim,
  ROUND(SUM(property_claim) / (SELECT SUM(total_claim_amount) FROM `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`), 2) AS property_percentage_share,
  SUM(vehicle_claim) AS total_vehicle_claim,
  ROUND(AVG(vehicle_claim), 2) AS average_vehicle_claim,
  ROUND(SUM(vehicle_claim) / (SELECT SUM(total_claim_amount) FROM `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`), 2) AS vehicle_percentage_share,
FROM
  `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
GROUP BY
  incident_type
ORDER BY
  average_vehicle_claim DESC;

# From this query, we have discovered that single vehicle collision and multi-vehicle collision are on the top leaderboard for total claim in all terms of total injury claim, property claim and also vehicle claim. Among these two type of incidents. injury claims make up only 7% of the total claim amount, meanwhile property also shares around 7% of the toal claim amount. Vehicle percentage shares about 35% of the total claim. These three in total account for about 39% of the toal claim, which means that there are still 61% of claim amount that are not included in this dataset.

# 3.2 Deductible Impact and Moral Hazard. Trying to analyze whether people with different deductible will have different claims.
WITH CTE AS (
  SELECT
    policy_deductable,
    COUNT(policy_deductable) OVER (PARTITION BY policy_deductable)AS policy_count,
    AVG(total_claim_amount) OVER (PARTITION BY policy_deductable) AS claim_severity_average,
    PERCENTILE_CONT(total_claim_amount, 0.5) OVER (PARTITION BY policy_deductable) AS claim_severity_median,
    COUNTIF(fraud_reported = TRUE) OVER (PARTITION BY policy_deductable) AS fraud_count,
    COUNT(fraud_reported) OVER (PARTITION BY policy_deductable) AS honest_and_fraud_count
  FROM
    `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
), CTE2 AS (
  SELECT
    policy_deductable,
    policy_count,
    claim_severity_average,
    claim_severity_median,
    fraud_count,
    honest_and_fraud_count,
    ROUND((fraud_count / honest_and_fraud_count) * 100, 2) AS fraud_rate
  FROM
    CTE
)

SELECT
  policy_deductable,
  policy_count,
  claim_severity_average,
  claim_severity_median,
  fraud_count,
  honest_and_fraud_count,
  fraud_rate
FROM
  CTE2
GROUP BY
  policy_deductable,
  policy_count,
  claim_severity_average,
  claim_severity_median,
  fraud_count,
  honest_and_fraud_count,
  fraud_rate;

# From this query, we can see symmetric information. When the policy deductable is 500 dollars, meaning that once claims amount pass 500 dollars, the insurance will cover it. This means that people who might drive around less carefully because they know that their insurance is good enough to cover their damages. Therefore the fraud rate is around 25.51%. In comparision, policy_deductable in the middle is around 1000 dollars. Customers at this range are more careful with their driving habits and not deflate or inflate their damage cost which means that there is less fraud (22.57%), and then there is policy deductable around 2000. Which means that customers sometimes might purposely inflate their damages to big numbers so that insurnace will cover their claims. Therefore the pattern makes sense that deductable around 1000 dollars group has the least fraud rate in comparison to the other two groups.

# 3.3 High exposure / Umbrella Coverage Analysis
WITH CTE AS (
  SELECT
    CASE 
      WHEN umbrella_limit > 0 THEN TRUE 
      ELSE FALSE
    END AS umbrella_limit_condition,
    total_claim_amount,
    fraud_reported
  FROM
    `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
), CTE2 AS (
  SELECT 
    umbrella_limit_condition,
    COUNT(umbrella_limit_condition) OVER (PARTITION BY umbrella_limit_condition)AS frequency,
    AVG(total_claim_amount) OVER (PARTITION BY umbrella_limit_condition) AS claim_severity_average,
    PERCENTILE_CONT(total_claim_amount, 0.5) OVER (PARTITION BY umbrella_limit_condition) AS claim_severity_median,
    COUNTIF(fraud_reported = TRUE) OVER (PARTITION BY umbrella_limit_condition) AS fraud_count,
    COUNT(fraud_reported) OVER (PARTITION BY umbrella_limit_condition) AS honest_and_fraud_count
  FROM
    CTE
), CTE3 AS (
  SELECT 
    umbrella_limit_condition,
    frequency,
    claim_severity_average,
    claim_severity_median,
    fraud_count,
    honest_and_fraud_count,
    ROUND((fraud_count / honest_and_fraud_count) * 100, 2) AS fraud_rate
  FROM
    CTE2
)

SELECT
  umbrella_limit_condition,
  frequency,
  ROUND(claim_severity_average, 2) AS claim_severity,
  claim_severity_median,
  fraud_count,
  honest_and_fraud_count,
  fraud_rate
FROM
  CTE3
GROUP BY
    umbrella_limit_condition, 
    frequency, 
    claim_severity_average, 
    claim_severity_median,
    fraud_count,
    honest_and_fraud_count,
    fraud_rate
ORDER BY
  claim_severity_average DESC;

# From this query we have discovered that in this dataset, about 797 policyholders purchased umbrella limit meanwhile 201 policyholders didn't. Under such data asymmetry and relevevant limitations, policyholders who are with umbrella limit on average are 6% more likely to commit fraud than people who are without umbrella limit. This might be due to the fact that they want to max out the benefits that they have in their insurance to reach the umbrella limit in order for the insurance company to cover everything.

# 4. Fraud Risk & Anomaly Profiling

# 4.1 Fraud rate by incident severity
SELECT
  incident_severity,
  COUNT(incident_severity) AS frequency,
  ROUND((COUNT(incident_severity) / (SELECT COUNT(incident_severity) FROM `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`)), 2) AS percentage,
  SUM(total_claim_amount) AS total_claim_amount,
  ROUND(COUNTIF(fraud_reported = TRUE) / COUNT(fraud_reported), 2) AS fraud_percentage
FROM
  `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
GROUP BY
  incident_severity
ORDER BY
  fraud_percentage DESC;

# From this query, it is shown that major damage has the highest fraud percentage. It accounts for approximately 28% of the claims and its on par with total loss and 7% less frequent than minor damage, so there isn't a severe class imbalance. However the fraud percentage shows that there is a high likelihood of fraud if a person is involved in a major damage accidents. This might alarm the insurance companies to inspect with greater scrutiny when a claim falls under the category as major damage.

# 4.2 Police Report & Authority Contact Correlation

SELECT
  police_report_available,
  SUM(total_claim_amount) AS total_claim_amount,
  ROUND(COUNT(police_report_available) / (SELECT COUNT(police_report_available) FROM `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`), 2) AS percentage, 
  ROUND(COUNTIF(fraud_reported = TRUE) / COUNT(fraud_reported), 2) AS fraud_percentage
FROM
  `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
GROUP BY
  police_report_available
HAVING  
  police_report_available IS NOT NULL
ORDER BY
  fraud_percentage DESC;

# From this query, we can discover that accidents without a police report will have a slightly raised percentage of chance, about 2%, to be classified as a fraud. This is noticeable but not significant. It could possibly indicate that accidents without police report might have a higher chance to have tendencies to have fraud occur.

# Financial Impact of Fraud
SELECT
  fraud_reported,
  SUM(total_claim_amount) AS total_claim_amount,
  ROUND(AVG(total_claim_amount), 2) AS avg_claim_amount,
  COUNT(fraud_reported) AS frequency,
  ROUND(COUNT(fraud_reported) / (SELECT COUNT(fraud_reported) FROM `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`), 2) AS percentage
FROM
  `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
GROUP BY
  fraud_reported
ORDER BY
  avg_claim_amount DESC;

# From this query, it's confirmed that for those claims labeled with TRUE for fraud reported, the average claim amount is around 10000 dollars higher than those honest claim report. It is quite surprising that fraud report made up approximately a quarter of the total data. This means that fraud has a negative impact for the insurance company and this impact should be strived to be eliminated.

# 5. Operational & Incident Pattern Analysis

# 5.1 Analysis on hour of the day and incident severity
SELECT
  incident_hour_of_the_day,
  incident_severity,
  COUNT(incident_severity) AS frequency,
  SUM(total_claim_amount) AS total_claim_amount,
  ROUND(AVG(total_claim_amount), 2) AS avg_claim_amount
FROM
  `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
GROUP BY
  incident_hour_of_the_day, incident_severity
ORDER BY
  frequency DESC;

# From this query, it can be discovered that a lots of accidents happen in the afternoon or early morning hours. Top one on the leaderboard it total loss accidents at 17. I think this is the frequent time that people travel to home from work. Due to fatigue or high traffic flows lots of accidents end in total loss. The seond and third observation on the leaderboard also happens in hour 0 and hour 4 which is early morning. This is possibly due to the fact that there are people who are driving for long periods of time and tired to keep driving. Also driving at late night means low visibility. For the rest of the hours which accidents frequently occur, they mostly accumulate in early morning and late night. Therefore, the insurnace company should pay extra attention to people who frequently drive late night or early morning or during high peak traffic hours.

# 5.2 Witness Impact on Claim Severity
WITH CTE AS (
  SELECT
    CASE WHEN witnesses > 0 THEN TRUE ELSE FALSE END AS witnesses_present,
    witnesses,
    fraud_reported,
    total_claim_amount
  FROM
    `sql-demo-projects.sql_portofolio.stage5_auto_insurance_claims_data`
), CTE2 AS (
  SELECT
  witnesses_present,
  fraud_reported,
  COUNT(total_claim_amount) AS frequency,
  SUM(total_claim_amount) AS total_claim_amount,
  AVG(total_claim_amount) AS avg_claim_amount
FROM
  CTE
GROUP BY
  witnesses_present, fraud_reported
), CTE3 AS (
  SELECT
    witnesses_present,
    fraud_reported,
    frequency,
    SUM(frequency) OVER (PARTITION BY witnesses_present) AS sum_frequency_category
  FROM
    CTE2
)

SELECT
  witnesses_present,
    fraud_reported,
    frequency,
    sum_frequency_category,
    ROUND(frequency / sum_frequency_category, 2) AS percentage
FROM
  CTE3;

# From this query, we discovered that whether witness are present or not present, more people are being honest than lying. In the case where there are not witnesses, 80% of people choose to not commit fraud meanwhile for the cases where there are witnesses, only 74% of people choose to be honest. This means that whether witnesses are present or not does not significantly impact the degree which people will not decide to commit fraud. 