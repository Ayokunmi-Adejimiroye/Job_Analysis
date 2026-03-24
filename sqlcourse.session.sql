-- Create company_dim table with primary key
CREATE TABLE public.company_dim
(
    company_id INT PRIMARY KEY,
    name TEXT,
    link TEXT,
    link_google TEXT,
    thumbnail TEXT
);

-- Create skills_dim table with primary key
CREATE TABLE public.skills_dim
(
    skill_id INT PRIMARY KEY,
    skills TEXT,
    type TEXT
);

-- Create job_postings_fact table with primary key
CREATE TABLE public.job_postings_fact
(
    job_id INT PRIMARY KEY,
    company_id INT,
    job_title_short VARCHAR(255),
    job_title TEXT,
    job_location TEXT,
    job_via TEXT,
    job_schedule_type TEXT,
    job_work_from_home BOOLEAN,
    search_location TEXT,
    job_posted_date TIMESTAMP,
    job_no_degree_mention BOOLEAN,
    job_health_insurance BOOLEAN,
    job_country TEXT,
    salary_rate TEXT,
    salary_year_avg NUMERIC,
    salary_hour_avg NUMERIC,
    FOREIGN KEY (company_id) REFERENCES public.company_dim (company_id)
);

-- Create skills_job_dim table with a composite primary key and foreign keys
CREATE TABLE public.skills_job_dim
(
    job_id INT,
    skill_id INT,
    PRIMARY KEY (job_id, skill_id),
    FOREIGN KEY (job_id) REFERENCES public.job_postings_fact (job_id),
    FOREIGN KEY (skill_id) REFERENCES public.skills_dim (skill_id)
);

-- Set ownership of the tables to the postgres user
ALTER TABLE public.company_dim OWNER to postgres;
ALTER TABLE public.skills_dim OWNER to postgres;
ALTER TABLE public.job_postings_fact OWNER to postgres;
ALTER TABLE public.skills_job_dim OWNER to postgres;

-- Create indexes on foreign key columns for better performance
CREATE INDEX idx_company_id ON public.job_postings_fact (company_id);
CREATE INDEX idx_skill_id ON public.skills_job_dim (skill_id);
CREATE INDEX idx_job_id ON public.skills_job_dim (job_id);

\copy company_dim FROM 'C:\Users\ayoad\OneDrive\Documents\SQL\Job_Ananlysis\csv_files\company_dim.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

\copy skills_dim FROM 'C:\Users\ayoad\OneDrive\Documents\SQL\Job_Ananlysis\csv_files\skills_dim.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

\copy job_postings_fact FROM 'C:\Users\ayoad\OneDrive\Documents\SQL\Job_Ananlysis\csv_files\job_postings_fact.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

\copy skills_job_dim FROM 'C:\Users\ayoad\OneDrive\Documents\SQL\Job_Ananlysis\csv_files\skills_job_dim.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

SELECT Count (*)
FROM job_postings_fact;

SELECT Count (*)
FROM skills_job_dim;

SELECT 
job_id, 
job_posted_date::DATE as Date
FROM job_postings_fact;

SELECT
    count (job_id) as job_total,
    EXTRACT (MONTH FROM job_posted_date) as job_month
FROM
    job_postings_fact
GROUP BY job_month
ORDER BY job_total;

CREATE TABLE january_job AS 
    SELECT *
    FROM 
        job_postings_fact
    WHERE 
        EXTRACT (MONTH FROM job_posted_date) = 1;


CREATE TABLE february_job AS 
    SELECT *
    FROM 
        job_postings_fact
    WHERE 
        EXTRACT (MONTH FROM job_posted_date) = 2;


CREATE TABLE march_job AS 
    SELECT *
    FROM 
        job_postings_fact
    WHERE 
        EXTRACT (MONTH FROM job_posted_date) = 3;


SELECT *
FROM march_job;

/* Find the average salary both yearly (salary_year_avg) and hourly (salary_hour_avg) 
for job postings using the job_postings_fact table that were posted after June 1, 2023. 
Group the results by job schedule type. Order by the job_schedule_type in ascending order.*/

SELECT
    job_schedule_type,
    AVG (salary_year_avg) as yearly_salary,
    AVG (salary_hour_avg) as hourly_salary
FROM job_postings_fact
WHERE job_posted_date > '2023-06-01'
GROUP BY job_schedule_type
ORDER BY job_schedule_type;

/* Count the number of job postings for each month, adjusting the job_posted_date to 
be in 'America/New_York' time zone before extracting the month. 
Assume the job_posted_date is stored in UTC. Group by and order by the month.*/

SELECT 
    count (job_id) total_post,
    EXTRACT (MONTH FROM (job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'America/New_York')) as job_month
FROM job_postings_fact
GROUP BY job_month
Order BY job_month;

/* Find companies (include company name) that have posted jobs offering health insurance, 
where these postings were made in the second quarter of 2023. Use date extraction to filter by quarter. 
And order by the job postings count from highest to lowest.*/

SELECT *
from job_postings_fact
Limit 5;

SELECT
    COUNT (job_postings_fact.*) as total_job,
    company_dim.name as company_name
from job_postings_fact
LEFT JOIN company_dim
ON company_dim.company_id = job_postings_fact.company_id
WHERE (EXTRACT (quarter from job_postings_fact.job_posted_date)) = 2
AND job_postings_fact.job_health_insurance = TRUE
GROUP BY company_name
HAVING count (job_postings_fact.*) >= 1
ORDER BY total_job DESC;

SELECT 
	job_id,
	job_location,
  CASE
	  WHEN job_location = 'Anywhere' THEN 'Remote'
    WHEN job_location = 'Boston, MA' THEN 'Local'
	  ELSE 'Onsite'
  END AS location_category
FROM job_postings_fact;

/* From the job_postings_fact table, categorize the salaries from job postings 
that are data analyst jobs, and that have yearly salary information. 
Put salary into 3 different categories:
If the salary_year_avg is greater than or equal to $100,000, then return ‘high salary’.
If the salary_year_avg is greater than or equal to $60,000 but less than $100,000, 
then return ‘Standard salary.’
If the salary_year_avg is below $60,000 return ‘Low salary’.
Also, order from the highest to the lowest salaries.*/

SELECT
    job_id,
    salary_year_avg,
    CASE
        WHEN salary_year_avg >= 100000 THEN 'high salary'
        WHEN salary_year_avg >= 60000 THEN 'standard salary'
        ELSE 'low salary'
    END AS salary_category
FROM job_postings_fact
WHERE job_title_short = 'Data Analyst'
AND salary_year_avg IS NOT NULL
ORDER BY salary_year_avg DESC;

/* Count the number of unique companies that offer work from home (WFH) versus those 
requiring work to be on-site. Use the job_postings_fact table to count and compare the distinct 
companies based on their WFH policy (job_work_from_home).*/
SELECT
    count (distinct company_id),
    job_work_from_home
FROM job_postings_fact
GROUP BY job_work_from_home;

SELECT 
    COUNT(DISTINCT CASE WHEN job_work_from_home = TRUE THEN company_id END) AS wfh_companies,
    COUNT(DISTINCT CASE WHEN job_work_from_home = FALSE THEN company_id END) AS non_wfh_companies
FROM job_postings_fact;

SELECT
    CASE
        WHEN job_work_from_home = TRUE THEN 'Remote'
        WHEN job_work_from_home = FALSE THEN 'Onsite'
END AS work_mode,
    COUNT (DISTINCT company_id)
FROM job_postings_fact
GROUP BY job_work_from_home;

SELECT
    job_id,
    salary_year_avg,
    CASE 
        WHEN job_title ILIKE '%Senior%' THEN 'Senior'
        WHEN job_title ILIKE '%Lead%' or job_title ILIKE '%Manager%' THEN 'Lead/Manager'
        WHEN job_title ILIKE '%Junior%' or job_title ILIKE '%Entry%' Then 'Junior/Entry'
         ELSE 'Not Specified'
    END AS experience_level,
    CASE
        WHEN job_work_from_home = TRUE THEN 'Yes'
        ELSE 'No'
    END AS remote_option
FROM job_postings_fact
WHERE salary_year_avg IS NOT NULL
ORDER BY job_id;

/* **Question:** 

- Find the count of the number of remote job postings per skill
    - Display the top 5 skills in descending order by their demand in remote jobs
    - Include skill ID, name, and count of postings requiring the skill
    - Why? Identify the top 5 skills in demand for remote jobs */

SELECT
    skills_dim.skill_id,
    skills_dim.skills,
    COUNT (job_postings_fact.job_id) as job_count
FROM job_postings_fact
LEFT JOIN skills_job_dim
ON skills_job_dim.job_id = job_postings_fact.job_id
LEFT JOIN skills_dim
ON skills_job_dim.skill_id = skills_dim.skill_id
WHERE job_postings_fact.job_work_from_home = TRUE
AND job_postings_fact.job_title_short = 'Data Analyst'
AND skills_dim.skill_id IS NOT NULL
GROUP BY skills_dim.skill_id
ORDER BY job_count DESC;

-- Get the number of job postings per skill for remote jobs
WITH remote_job_skills AS (
  SELECT 
		skill_id, 
		COUNT(*) as skill_count
  FROM 
		skills_job_dim AS skills_to_job
	-- only get the relevant job postings
  INNER JOIN job_postings_fact AS job_postings ON job_postings.job_id = skills_to_job.job_id
  WHERE 
		job_postings.job_work_from_home = True
		-- If you only want to search for data analyst jobs (like Luke does in the video)
		--job_postings.job_title_short = 'Data Analyst'
  GROUP BY 
		skill_id
)

-- Return the skill id, name, and count of how many times its asked for
SELECT 
	skills.skill_id, 
	skills as skill_name, 
	skill_count
FROM remote_job_skills
-- Get the skill name
INNER JOIN skills_dim AS skills ON skills.skill_id = remote_job_skills.skill_id
ORDER BY 
	skill_count DESC
LIMIT 5;

/* Identify the top 5 skills that are most frequently mentioned in job postings. 
Use a subquery to find the skill IDs with the highest counts in the skills_job_dim table 
and then join this result with the skills_dim table to get the skill names.*/

SELECT
    skills_dim.skills,
    skill_frequency.skill_id,
    skill_frequency.total_job
FROM
(SELECT 
    skill_id,
    count (job_id) as total_job
FROM skills_job_dim
GROUP BY skill_id) as skill_frequency
INNER JOIN skills_dim
ON skill_frequency.skill_id = skills_dim.skill_id
ORDER BY skill_frequency.total_job DESC
LIMIT 5;

/* Determine the size category ('Small', 'Medium', or 'Large') for each company by first identifying
the number of job postings they have. Use a subquery to calculate the total job postings per company. 
A company is considered 'Small' if it has less than 10 job postings, 'Medium' 
if the number of job postings is between 10 and 50, and 'Large' if it has more than 50 job postings. 
Implement a subquery to aggregate job counts per company before classifying them based on size.*/

SELECT
    company_id,
    total_post,
    company_name,
    CASE
        WHEN total_post < 10 THEN 'Small'
        WHEN total_post BETWEEN 10 and 50 THEN 'Medium'
        WHEN total_post > 50 THEN 'Large'
    END AS company_size
FROM (SELECT 
    job_postings_fact.company_id,
    company_dim.name as company_name,
    count (job_postings_fact.job_id)as total_post
FROM
    job_postings_fact
INNER JOIN company_dim
ON company_dim.company_id = job_postings_fact.company_id
GROUP BY job_postings_fact.company_id,
        company_dim.name
ORDER By job_postings_fact.company_id) as company_total_post;

/* Your goal is to find the names of companies that have an average salary greater
than the overall average salary across all job postings.
You'll need to use two tables: company_dim (for company names) and 
job_postings_fact (for salary data). The solution requires using subqueries.*/



SELECT 
    company_dim.name as company_name,
    AVG(job_postings_fact.salary_year_avg) as average_salary
FROM
    company_dim
INNER JOIN job_postings_fact
on job_postings_fact.company_id = company_dim.company_id
WHERE job_postings_fact.salary_year_avg IS NOT NULL
GROUP BY company_dim.name
HAVING avg(job_postings_fact.salary_year_avg) > (SELECT AVG(salary_year_avg)
FROM job_postings_fact);

/*Identify companies with the most diverse (unique) job titles. 
Use a CTE to count the number of unique job titles per company,
then select companies with the highest diversity in job titles.*/

WITH unique_companies AS
    (SELECT 
        COUNT (DISTINCT job_postings_fact.job_title) as distinct_title,
        company_dim.name
    FROM job_postings_fact
    INNER JOIN company_dim
    ON company_dim.company_id = job_postings_fact.company_id
    GROUP BY company_dim.name
    ORDER BY distinct_title DESC)
SELECT *
FROM unique_companies
LIMIT 10;

/* Explore job postings by listing job id, job titles, company names, and 
their average salary rates, while categorizing these salaries relative to the average in their 
respective countries. Include the month of the job posted date. Use CTEs, conditional logic, 
and date functions, to compare individual salaries with national average */

SELECT DISTINCT job_country
from job_postings_fact;

WITH country_avg AS 
(SELECT
    AVG (salary_year_avg) as salary_average,
    job_country
FROM job_postings_fact
GROUP BY job_country)
SELECT 
    job_postings_fact.job_id,
    job_postings_fact.job_title,
    company_dim.name,
    job_postings_fact.salary_year_avg,
    CASE
        WHEN job_postings_fact.salary_year_avg > country_avg.salary_average THEN 'Above Average'
        WHEN job_postings_fact.salary_year_avg < country_avg.salary_average THEN 'Below Average'
     END AS country_comparison,
     job_postings_fact.job_country,
     EXTRACT (MONTH FROM job_postings_fact.job_posted_date) AS month_posted
FROM job_postings_fact
INNER JOIN company_dim
ON job_postings_fact.company_id = company_dim.company_id
INNER JOIN country_avg
ON job_postings_fact.job_country = country_avg.job_country
ORDER BY month_posted DESC;
