# Auto Insurance Claims Analysis

Author: Samuel Wu 

Date: 7/28/2026


## Project Description

In this project. We are analyzing a dataest regarding auto insurnace claims from Kaggle (https://www.kaggle.com/datasets/buntyshah/auto-insurance-claims-data). The analysis include the following five main stages. All code in this project is completely hand-written

### Cleaning Stages:

* Importing the data and initial process
    * Import the data
    * Remove all duplicates
* Schema and structure cleanup
    * Standardize column name conventions
    * Fill in missing values
* Business Logic Filtering
    * Individual column inspection
    * Create a finalized clean table

### Analysis Stages:

* Portofolio & Underwritting performance
    * Loss Ratio: Total Claims  / Total Premiums
    * Claim Severity 
* Risk Stratification
    * Group vehicles by age categories to observe how cars' value affect claim cost
    * Group vehicles by brand categories to see how cars' value affects claim cost
    * Group by occupation
    * Group by education
* Financial Breakdown & Policy Structure Impact
    * Percentage distribution of claim costs across vehicle claim, injury claim, property claim
    * Deductible Impact and Moral Hazard.
* Fraud Risk & Anomaly Profiling
    * Fraud rate by incident severity
    * Police report & Authority Contact Correlation
* Operational & Incident Pattern Analysis



## Folder Structure

```
AUTO_INSURNACE_RATE_ANALYSIS_AQL
|
|-data/
|   |-insurance_claims.csv
|-sql/
|   |-stage1_data_cleaning.sql
|   |-stage2_data_cleaning.sql
|-LICENSE
|-README.md   
```

## Code and Comment Structure

The notebook is formatted as the following for each section:

```
Title -> Code -> Comment
```
Each section begins with a title declaring what is going to happen and then the code will be written. The comment will comment on the display of the output.

## How to use these code

The code is ran in Big Query. User needs to log in and create an account at 

https://www.kaggle.com/datasets/buntyshah/auto-insurance-claims-data

After creating an account. Click the top left navigational panel to navigate to Big Query. After this navigation. On the top left near the Google Cloud Project picker. Go ahead and initiate a new project. For this case I have named it SQL Demo Project.

You may copy in these two files into Google Cloud to run them. Before running any code you may want to upload the data from the data folder to a dataset in Google Cloud.

After that you may go ahead and start to run the code. Before doing so, you will need to change the subscript of data source, in particular:

```
sql-demo-projects.sql_portofolio.auto_insurance_claims_data
```

Or any source information after the FROM clause. This is important so that your data can be extracted correctly and formatted correctly.

Every time when you would like to run a particular query, go ahead and highlight that query by your cursor and click the run button, you will see the results for that particular query.


