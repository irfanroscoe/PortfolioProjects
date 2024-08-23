SELECT *
FROM employee
JOIN performancerating
ON employee.EmployeeID = performancerating.EmployeeID; 

-- average staisfaction by department
SELECT employee.Department, 
       AVG(performancerating.EnvironmentSatisfaction) AS AvgEnvironmentSatisfaction, 
       AVG(performancerating.JobSatisfaction) AS AvgJobSatisfaction, 
       AVG(performancerating.RelationshipSatisfaction) AS AvgRelationshipSatisfaction
FROM employee
JOIN performancerating ON employee.EmployeeID = performancerating.EmployeeID
GROUP BY employee.Department;

-- impact of training on performance
SELECT employee.EmployeeID, 
       AVG(performancerating.TrainingOpportunitiesTaken) AS AvgTrainingTaken, 
       AVG(performancerating.SelfRating) AS AvgSelfRating, 
       AVG(performancerating.ManagerRating) AS AvgManagerRating
FROM employee
JOIN performancerating ON employee.EmployeeID = performancerating.EmployeeID
GROUP BY employee.EmployeeID;

-- employees with most review
SELECT employee.EmployeeID, employee.FirstName, employee.LastName, COUNT(performancerating.PerformanceID) AS ReviewCount
FROM employee
JOIN performancerating ON employee.EmployeeID = performancerating.EmployeeID
GROUP BY employee.EmployeeID, employee.FirstName, employee.LastName
ORDER BY ReviewCount DESC;

-- top performers by department
SELECT Department, FirstName, LastName, AvgRating
FROM (
    SELECT employee.Department, employee.FirstName, employee.LastName, 
           (AVG(performancerating.ManagerRating) + AVG(performancerating.SelfRating)) / 2 AS AvgRating,
           RANK() OVER (PARTITION BY employee.Department ORDER BY (AVG(performancerating.ManagerRating) + AVG(performancerating.SelfRating)) / 2 DESC) AS perfrank
    FROM employee
    JOIN performancerating ON employee.EmployeeID = performancerating.EmployeeID
    GROUP BY employee.Department, employee.FirstName, employee.LastName
) AS DeptRankings
WHERE perfrank = 1;

-- employee attrition analysis
SELECT employee.EmployeeID, employee.FirstName, employee.LastName,
       CASE 
           WHEN employee.Attrition = 'Yes' THEN 'Left the Company'
           WHEN employee.Attrition = 'No' THEN 'Still Employed'
           ELSE 'Unknown'
       END AS AttritionStatus,
       AVG(performancerating.EnvironmentSatisfaction) AS AvgEnvironmentSatisfaction,
       AVG(performancerating.JobSatisfaction) AS AvgJobSatisfaction,
       AVG(performancerating.RelationshipSatisfaction) AS AvgRelationshipSatisfaction
FROM employee
JOIN performancerating ON employee.EmployeeID = performancerating.EmployeeID
GROUP BY employee.EmployeeID, employee.FirstName, employee.LastName, employee.Attrition;

-- correlation between training and performance
WITH TrainingData AS (
    SELECT employee.EmployeeID, employee.FirstName, employee.LastName,
           SUM(performancerating.TrainingOpportunitiesTaken) AS TotalTrainingTaken,
           AVG(performancerating.SelfRating) AS AvgSelfRating,
           AVG(performancerating.ManagerRating) AS AvgManagerRating
    FROM employee
    JOIN performancerating ON employee.EmployeeID = performancerating.EmployeeID
    GROUP BY employee.EmployeeID, employee.FirstName, employee.LastName
),
PerformanceData AS (
    SELECT EmployeeID, 
           (AvgSelfRating + AvgManagerRating) / 2 AS AvgPerformanceRating
    FROM TrainingData
)
SELECT TrainingData.EmployeeID, TrainingData.FirstName, TrainingData.LastName, TrainingData.TotalTrainingTaken, 
       PerformanceData.AvgPerformanceRating,
       CASE
           WHEN TrainingData.TotalTrainingTaken > 5 AND PerformanceData.AvgPerformanceRating > 4 THEN 'High Performer with High Training'
           WHEN TrainingData.TotalTrainingTaken <= 5 AND PerformanceData.AvgPerformanceRating > 4 THEN 'High Performer with Low Training'
           ELSE 'Other'
       END AS PerformanceCategory
FROM TrainingData
JOIN PerformanceData ON TrainingData.EmployeeID = PerformanceData.EmployeeID;

-- employees with most consisten performance rating
SELECT e.EmployeeID, e.FirstName, e.LastName, 
       ROUND(STDDEV(p.ManagerRating), 2) AS ManagerRatingVariance,
       ROUND(STDDEV(p.SelfRating), 2) AS SelfRatingVariance
FROM employee e
JOIN performancerating p ON e.EmployeeID = p.EmployeeID
GROUP BY e.EmployeeID, e.FirstName, e.LastName
HAVING ROUND(STDDEV(p.ManagerRating), 2) < 1 AND ROUND(STDDEV(p.SelfRating), 2) < 1
ORDER BY ManagerRatingVariance, SelfRatingVariance;

-- longest tenure employees with high performance ratings
SELECT e.EmployeeID, e.FirstName, e.LastName, e.YearsAtCompany, 
       AVG(p.SelfRating) AS AvgSelfRating, 
       AVG(p.ManagerRating) AS AvgManagerRating
FROM employee e
JOIN performancerating p ON e.EmployeeID = p.EmployeeID
GROUP BY e.EmployeeID, e.FirstName, e.LastName, e.YearsAtCompany
HAVING e.YearsAtCompany >= 10 AND (AVG(p.SelfRating) + AVG(p.ManagerRating)) / 2 > 4
ORDER BY e.YearsAtCompany DESC, AvgSelfRating DESC, AvgManagerRating DESC;

-- gender and performance analysis
SELECT e.Gender, 
       AVG(p.EnvironmentSatisfaction) AS AvgEnvironmentSatisfaction,
       AVG(p.JobSatisfaction) AS AvgJobSatisfaction,
       AVG(p.RelationshipSatisfaction) AS AvgRelationshipSatisfaction,
       AVG(p.SelfRating) AS AvgSelfRating,
       AVG(p.ManagerRating) AS AvgManagerRating
FROM employee e
JOIN performancerating p ON e.EmployeeID = p.EmployeeID
GROUP BY e.Gender
ORDER BY e.Gender;

-- impact of distance from home on job satisfaction
SELECT e.`DistanceFromHome (KM)`, 
       ROUND(AVG(p.JobSatisfaction), 2) AS AvgJobSatisfaction,
       ROUND(AVG(p.EnvironmentSatisfaction), 2) AS AvgEnvironmentSatisfaction,
       ROUND(AVG(p.RelationshipSatisfaction), 2) AS AvgRelationshipSatisfaction
FROM employee e
JOIN performancerating p ON e.EmployeeID = p.EmployeeID
GROUP BY e.`DistanceFromHome (KM)`
ORDER BY e.`DistanceFromHome (KM)`;

-- department training effectiveness
SELECT e.Department, 
       AVG(p.TrainingOpportunitiesTaken) AS AvgTrainingTaken,
       ROUND(AVG(p.SelfRating), 2) AS AvgSelfRating,
       ROUND(AVG(p.ManagerRating), 2) AS AvgManagerRating
FROM employee e
JOIN performancerating p ON e.EmployeeID = p.EmployeeID
GROUP BY e.Department
ORDER BY AvgTrainingTaken DESC;

-- impact of working overtime on performance ratings
SELECT e.OverTime, 
       AVG(p.JobSatisfaction) AS AvgJobSatisfaction,
       AVG(p.WorkLifeBalance) AS AvgWorkLifeBalance,
       AVG(p.SelfRating) AS AvgSelfRating,
       AVG(p.ManagerRating) AS AvgManagerRating
FROM employee e
JOIN performancerating p ON e.EmployeeID = p.EmployeeID
GROUP BY e.OverTime
ORDER BY e.OverTime;

-- identifying high performers with low job satisfaction
SELECT e.EmployeeID, e.FirstName, e.LastName, 
       AVG(p.JobSatisfaction) AS AvgJobSatisfaction,
       AVG(p.ManagerRating) AS AvgManagerRating,
       AVG(p.SelfRating) AS AvgSelfRating
FROM employee e
JOIN performancerating p ON e.EmployeeID = p.EmployeeID
GROUP BY e.EmployeeID, e.FirstName, e.LastName
HAVING AVG(p.ManagerRating) > 4.5 AND AVG(p.JobSatisfaction) < 3
ORDER BY AvgManagerRating DESC, AvgJobSatisfaction ASC;










 

