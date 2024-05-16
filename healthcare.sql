-- To better work with the database, I want to rename the columns with no spaces 
USE healthcare;

-- ALTER TABLE healthcare_dataset
-- CHANGE `Blood Type` blood_type VARCHAR(5),
-- CHANGE `Medical Condition` medical_condition VARCHAR(30),
-- CHANGE `Date of Admission` admit_date VARCHAR(30),
-- CHANGE `Insurance Provider` insurance_provider VARCHAR(30),
-- CHANGE `Billing Amount` billing_amount DOUBLE,
-- CHANGE `Room Number` room_number VARCHAR(30),
-- CHANGE `Admission Type` admit_type VARCHAR(30),
-- CHANGE `Discharge Date` discharge_date VARCHAR(30),
-- CHANGE `Test Results` test_results VARCHAR(30);

-- Updating dates that are currently at strings to dates 

ALTER TABLE healthcare_dataset
MODIFY COLUMN admit_date DATE,
MODIFY COLUMN discharge_date DATE;

-- What is the most common medical condition that patients have? 
SELECT medical_condition, COUNT(*) as medical_condition_count
FROM healthcare_dataset
GROUP BY medical_condition
ORDER BY medical_condition_count DESC;
-- Similar counts of medical conditions across the board

-- What is the condition that typically generates the most lengthy stay in the hospital?
SELECT medical_condition, AVG(DATEDIFF(discharge_date, admit_date)) as avg_length_stay 
FROM healthcare_dataset
GROUP BY medical_condition
ORDER BY avg_length_stay;
-- All conditions have similar time in hospital

-- What is the average age of patients? 

SELECT medical_condition, AVG(Age)
FROM healthcare_dataset
GROUP BY medical_condition;
-- 51

-- Is there an average age that we see a typical medical condition? 

SELECT medical_condition, AVG(Age) as avg_medical_condition_age
FROM healthcare_dataset
GROUP BY medical_condition
ORDER BY avg_medical_condition_age;
-- All have similar average ages of 50-51

-- While this is a synthetic dataset, there doesn't seem to be a widely distributed dataset that is making segmentation difficult
-- Let's check the different ranges of age:

SELECT 
	CASE 
		WHEN Age <20 THEN 'Under 20'
        WHEN Age BETWEEN 20 and 29 THEN '20-29'
        WHEN Age BETWEEN 30 and 39 THEN '30-39'
        WHEN Age BETWEEN 40 and 49 THEN '40-49'
        WHEN Age BETWEEN 50 and 59 THEN '50-59'
        WHEN Age BETWEEN 60 and 69 THEN '60-69'
        WHEN Age BETWEEN 70 and 79 THEN '70-79'
        WHEN Age >= 80 THEN '80+'
        ELSE 'N/A'
	END AS Age_Range,
    COUNT(*) as Count
FROM healthcare_dataset
GROUP BY Age_Range, Age
ORDER BY Age_Range;
-- There are more 20-29 year old patients than there are 40-49 year-old patients; this seems odd as you typically have more
-- health issues as you get older 
-- I want to make the age range a permanet part of the table to see if there is a condition that affects different age groups differently

SET SQL_SAFE_UPDATES = 0; 

-- ALTER TABLE healthcare_dataset
-- ADD COLUMN IF NOT EXISTS Age_Range VARCHAR(10);

UPDATE healthcare_dataset
SET Age_Range = 
    CASE 
        WHEN Age < 20 THEN 'Under 20'
        WHEN Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN Age BETWEEN 40 AND 49 THEN '40-49'
        WHEN Age BETWEEN 50 AND 59 THEN '50-59'
        WHEN Age BETWEEN 60 AND 69 THEN '60-69'
        WHEN Age BETWEEN 70 AND 79 THEN '70-79'
        WHEN Age >= 80 THEN '80+'
        ELSE 'N/A'
    END;

-- What is the most common medical condition for each age group?  
SELECT Age_Range, medical_condition, medical_condition_age
FROM (
    SELECT Age_Range, medical_condition, COUNT(*) as medical_condition_age,
           ROW_NUMBER() OVER (PARTITION BY Age_Range ORDER BY COUNT(*) DESC) as row_num
    FROM healthcare_dataset
    GROUP BY Age_Range, medical_condition
) AS ranked_data
WHERE row_num = 1; # this selects the first row of each age group (due to the parition by, it is in descending order
					# so the first box is going to be the highest

-- Is there any type of gender disparity with the dataset? 

SELECT medical_condition, gender, COUNT(*) AS gender_count 
FROM healthcare_dataset 
GROUP BY medical_condition, gender
ORDER BY medical_condition;
## Roughly the same between 790-850 for all conditions and gender 

# How is the billing amount different for each condition? 
SELECT medical_condition, ROUND(AVG(billing_amount), 2) AS avg_billed
FROM healthcare_dataset 
GROUP BY medical_condition
ORDER BY medical_condition;
# The average for all is about $25K

# Is there a specific doctor that has the higest average billed amount?
SELECT Doctor, ROUND(AVG(billing_amount), 2) AS avg_billed
FROM healthcare_dataset 
GROUP BY Doctor
ORDER BY avg_billed DESC
LIMIT 10;

# Looking at the bottom 10: 
SELECT Doctor, ROUND(AVG(billing_amount), 2) AS avg_billed
FROM healthcare_dataset 
GROUP BY Doctor
ORDER BY avg_billed ASC
LIMIT 10;

# This is interesting; there is a wide disparity in amount billed between doctors; the lowest being $1K and the 
# highest being about $50K 

# Let's look into this a little more: 
SELECT Doctor, medical_condition, admit_type, ROUND(AVG(billing_amount), 2) AS avg_billed,
	ROUND(AVG(DATEDIFF(discharge_date, admit_date)), 0) as avg_length_stay,
    COUNT(Name) AS num_patients_treated
FROM healthcare_dataset 
GROUP BY Doctor, medical_condition, admit_type
ORDER BY avg_billed DESC
LIMIT 10;

# Looking at the bottom 10: 

SELECT Doctor, medical_condition, admit_type, ROUND(AVG(billing_amount), 2) AS avg_billed,
	ROUND(AVG(DATEDIFF(discharge_date, admit_date)), 0) as avg_length_stay,
    COUNT(Name) AS num_patients_treated
FROM healthcare_dataset 
GROUP BY Doctor, medical_condition, admit_type
ORDER BY avg_billed ASC
LIMIT 10;

## The average stay is between 15-16 days; the dataset has most doctors in the dataset treating one patient, with a few having 
# two patients.  There doesn't seem to be a link between the billed amount and the doctor due to the limited amount of data.

SELECT admit_type, ROUND(AVG(billing_amount), 2) as avg_billed
FROM healthcare_dataset
GROUP BY admit_type;
# The differences between how a patient was admitted and their respective average billed doesn't appear to be 
# significantly different


# SUMMARY
## What business case can we get from this dataset? 

## This synthetic dataset was pretty evenly distributed with conditions, age, gendder, and hospital length stays, and average billed.
## With this someone even distribution, it is difficult to identify trends and patterns

## I thought I was found a trend with the the high difference billed in doctor's, but with each doctor having just one patient,
## and sometimes two, it is difficult to delve deeper.

## If this was real data, this is what I'd be looking for from an data analyst perspective (some I tried to get in the code above
## but could not get anything meaninful out of the synthetic data: 

## 1) What conditions generate the longest stay in the hospital
## 2) Are hosptial patients' gender significantly skewed? 
## 3) What is the average age of a patient? 
		## with this, does the hospital have large age gaps (for example, is there a majority of older or younger people over
		## another age group?
## 4) Is there a most common medical condition per age group? 
## 5) What is the average billed amount per doctor based on condition and length of stay? 

## These are just a handful of questions of many we can ask.  Identifying trends can allow the hospital to better staff, better 
## plan bed space, and generally better accomodate a specific demographic that might be more prevalent.
