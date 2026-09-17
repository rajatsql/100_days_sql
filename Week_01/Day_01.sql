==================================================
NON-NEGOTIABLE TASK 1 — SQL/PLSQL
QUESTION + MY ANSWER CHECK
==================================================


PATTERN 1 — GROUP BY + HAVING
--------------------------------------------------

QUESTION:
Find departments having more than 5 employees and
where the average salary is greater than 30,000.

YOUR ANSWER:

SELECT DEPT_ID,
       COUNT(*),
       AVG(SALARY)
FROM EMPLOYEE
GROUP BY DEPT_ID
HAVING COUNT(*) > 5
   AND AVG(SALARY) > 30000;


RESULT:
✓ CORRECT

CORRECT ANSWER:

SELECT DEPT_ID,
       COUNT(*),
       AVG(SALARY)
FROM EMPLOYEE
GROUP BY DEPT_ID
HAVING COUNT(*) > 5
   AND AVG(SALARY) > 30000;


KEY CONCEPT:
GROUP BY → Creates groups
HAVING    → Filters groups after aggregation


==================================================
PATTERN 2 — JOIN
--------------------------------------------------

QUESTION:
Display EMP_ID, EMP_NAME, DEPT_NAME and SALARY
for every employee.

Tables:
EMPLOYEE  (EMP_ID, EMP_NAME, DEPT_ID, SALARY)
DEPARTMENT (DEPT_ID, DEPT_NAME)


YOUR ANSWER:

SELECT E.EMP_NAME,
       D.DEPT_NAME,
       E.SALARY
FROM EMPLOYEE E
LEFT JOIN DEPARTMENT D
       ON E.DEPT_ID = D.DEPT_ID;


RESULT:
⚠ PARTIALLY CORRECT

PROBLEM:
EMP_ID is missing from the SELECT list.


CORRECT ANSWER:

SELECT E.EMP_ID,
       E.EMP_NAME,
       D.DEPT_NAME,
       E.SALARY
FROM EMPLOYEE E
LEFT JOIN DEPARTMENT D
       ON E.DEPT_ID = D.DEPT_ID;


KEY CONCEPT:
LEFT JOIN keeps every employee from EMPLOYEE,
even when no matching department exists.


==================================================
PATTERN 3 — CORRELATED SUBQUERY
--------------------------------------------------

QUESTION:
Find employees whose salary is greater than the
average salary of their own department.


YOUR ANSWER:

SELECT E.EMP_NAME,
       E.SALARY
FROM EMPLOYEE E1
WHERE E.SALARY >
(
    SELECT AVG(SALARY)
    FROM EMPLOYEE E1
    WHERE E1.DEPT_ID = E2.DEPT_ID
);


RESULT:
✗ INCORRECT


PROBLEMS:

1. E is used but E was never defined.

2. E2 is used but E2 was never defined.

3. E1 is declared twice.


CORRECT ANSWER:

SELECT E.EMP_NAME,
       E.SALARY
FROM EMPLOYEE E
WHERE E.SALARY >
(
    SELECT AVG(E1.SALARY)
    FROM EMPLOYEE E1
    WHERE E1.DEPT_ID = E.DEPT_ID
);


KEY CONCEPT:

E  → Current employee from outer query
E1 → Employees in that employees department

Correlation:
E1.DEPT_ID = E.DEPT_ID


==================================================
PATTERN 4 — CASE WHEN
--------------------------------------------------

QUESTION:
Classify employees based on worked hours:

>= 9 hours → OT
>= 8 hours → FULL DAY
>= 4 hours → HALF DAY
< 4 hours  → ABSENT


YOUR ANSWER:

WITH CTE AS(
SELECT EMP_ID,
       ATT_DATE,
       ((OUT_TIME - IN_TIME)) AS HR
FROM ATTENDANCE)

SELECT EMP_ID,
       ATT_DATE
       (CASE
           WHEN HR >= 9 THEN 'OT'
           WHEN HR >= 8 AND HR < 9 THEN 'FULL DAY'
           WHEN HR >= 4 AND HR < 8 THEN 'HALF DAY'
           WHEN HR < 4 THEN 'ABSENT'
       END) AS STATUS
FROM CTE;


RESULT:
✗ INCORRECT


PROBLEMS:

1. Missing comma after ATT_DATE.

2. For Oracle DATE values, OUT_TIME - IN_TIME
   returns DAYS, not HOURS.

3. CASE can be simplified.


CORRECT ANSWER:

WITH CTE AS
(
    SELECT EMP_ID,
           ATT_DATE,
           (OUT_TIME - IN_TIME) * 24 AS HR
    FROM ATTENDANCE
)
SELECT EMP_ID,
       ATT_DATE,
       CASE
           WHEN HR >= 9 THEN 'OT'
           WHEN HR >= 8 THEN 'FULL DAY'
           WHEN HR >= 4 THEN 'HALF DAY'
           ELSE 'ABSENT'
       END AS STATUS
FROM CTE;


KEY CONCEPT:

Oracle DATE:

OUT_TIME - IN_TIME
        ↓
Difference in DAYS

(OUT_TIME - IN_TIME) * 24
        ↓
Difference in HOURS


==================================================
PATTERN 5 — WINDOW FUNCTION
--------------------------------------------------

QUESTION:
For every employee, return:

EMP_NAME
DEPT_ID
SALARY
DEPT_AVG_SALARY
SALARY_RANK

DEPT_AVG_SALARY = Average salary of the department

SALARY_RANK = Employees salary ranking within
              the department


YOUR ANSWER:

SELECT EMP_NAME,
       DEPT_ID,
       SALARY,
       AVG(SALARY) OVER(
           PARTITION BY DEPT_ID
           ORDER BY SALARY
       ) DEPT_AVG_SALARY,
       RENK() OVER(
           PARTITION BY DEPT_ID
           ORDER BY SALARY
       ) SALARY_RANK
FROM EMPLOYEE;


RESULT:
✗ INCORRECT


PROBLEMS:

1. RENK() → RANK()

2. AVG() should not have ORDER BY SALARY because
   we need the complete department average.

3. RANK should use ORDER BY SALARY DESC so that
   highest salary gets Rank 1.


CORRECT ANSWER:

SELECT EMP_NAME,
       DEPT_ID,
       SALARY,

       AVG(SALARY) OVER(
           PARTITION BY DEPT_ID
       ) AS DEPT_AVG_SALARY,

       RANK() OVER(
           PARTITION BY DEPT_ID
           ORDER BY SALARY DESC
       ) AS SALARY_RANK

FROM EMPLOYEE;


KEY CONCEPT:

AVG() OVER(PARTITION BY DEPT_ID)
    → Complete department average

RANK() OVER(
    PARTITION BY DEPT_ID
    ORDER BY SALARY DESC
)
    → Salary ranking inside each department


==================================================
TASK 1 RESULT
==================================================

PATTERN 1 → ✓ CORRECT
PATTERN 2 → ⚠ PARTIALLY CORRECT
PATTERN 3 → ✗ INCORRECT
PATTERN 4 → ✗ INCORRECT
PATTERN 5 → ✗ INCORRECT


SCORE: 34/50
PERCENTAGE: 68%


WEAK AREAS TO REVISE:

1. SQL aliases
2. Correlated subqueries
3. Oracle DATE calculations
4. Window functions
5. RANK vs ORDER BY
6. PARTITION BY vs ORDER BY


==================================================
TRACKING RULE FOR FUTURE TASKS
==================================================

If YOUR ANSWER = CORRECT ANSWER:

    → Show QUESTION
    → Show ONE ANSWER
    → Mark ✓ CORRECT
    → No duplicate answer


If YOUR ANSWER ≠ CORRECT:

    → Show QUESTION
    → Show YOUR ANSWER
    → Show RESULT
    → Show PROBLEM
    → Show CORRECT ANSWER
    → Show KEY CONCEPT


This format will be used for the next tasks.
==================================================
