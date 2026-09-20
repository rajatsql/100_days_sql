==================================================
DAY 7 — QUESTION + YOUR ANSWER + CORRECT ANSWER
==================================================


PATTERN 1 — JOIN + GROUP BY + HAVING
--------------------------------------------------

YOUR ANSWER:

SELECT D.DEPT_ID,
       D.DEPT_NAME,
       COUNT(*) AS EMPLOYEE_COUNT,
       AVG(E.SALARY) AS AVG_SALARY
FROM DEPARTMENT D
JOIN EMPLOYEE E
    ON D.DEPT_ID = E.DEPT_ID
GROUP BY D.DEPT_ID,
         D.DEPT_NAME
HAVING COUNT(*) >= 3
   AND AVG(E.SALARY) > 40000;


RESULT:
✓ CORRECT

No substantive problem here.

You correctly used:

JOIN
GROUP BY
HAVING
COUNT()
AVG()


This is exactly the expected solution.


==================================================
PATTERN 2 — LEFT JOIN + CONDITIONAL AGGREGATION
--------------------------------------------------

YOUR ANSWER:

SELECT E.EMP_ID,
       E.EMP_NAME,
       SUM(CASE WHEN STATUS = 'PRESENT_DAYS'
                THEN 1 ELSE 0 END) AS PRESENT_DAYS,
       SUM(CASE WHEN STATUS = 'ABSENT_DAYS'
                THEN 1 ELSE 0 END) AS ABSENT_DAYS,
       SUM(CASE WHEN STATUS = 'HALF_DAYS'
                THEN 1 ELSE 0 END) AS HALF_DAYS
FROM EMPLOYEE E
LEFT JOIN ATTENDANCE A
    ON E.EMP_ID = A.EMP_ID
   AND TO_CHAR(A.ATT_DATE,'MON-RRRR') = 'SEP-2026'
GROUP BY E.EMP_ID,
         E.EMP_NAME;


RESULT:
✗ INCORRECT


MAIN ERROR:

Your STATUS values are:

'PRESENT'
'ABSENT'
'HALF DAY'


But you wrote:

'PRESENT_DAYS'
'ABSENT_DAYS'
'HALF_DAYS'


Those are output column names, NOT STATUS values.

Correct:

CASE WHEN A.STATUS = 'PRESENT'
CASE WHEN A.STATUS = 'ABSENT'
CASE WHEN A.STATUS = 'HALF DAY'


CORRECT ANSWER:

SELECT E.EMP_ID,
       E.EMP_NAME,
       SUM(CASE WHEN A.STATUS = 'PRESENT'
                THEN 1 ELSE 0 END) AS PRESENT_DAYS,
       SUM(CASE WHEN A.STATUS = 'ABSENT'
                THEN 1 ELSE 0 END) AS ABSENT_DAYS,
       SUM(CASE WHEN A.STATUS = 'HALF DAY'
                THEN 1 ELSE 0 END) AS HALF_DAYS
FROM EMPLOYEE E
LEFT JOIN ATTENDANCE A
    ON E.EMP_ID = A.EMP_ID
   AND A.ATT_DATE >= DATE '2026-09-01'
   AND A.ATT_DATE < DATE '2026-10-01'
GROUP BY E.EMP_ID,
         E.EMP_NAME;


IMPORTANT:

Your JOIN logic was correct.

The September condition was correctly placed in ON.

Because of:

ELSE 0

an employee with no attendance gets:

PRESENT_DAYS = 0
ABSENT_DAYS = 0
HALF_DAYS = 0


So this was a **conceptual pass but execution failure**.


==================================================
PATTERN 3 — LATEST ACTIVE SALARY + JOIN
--------------------------------------------------

YOUR ANSWER:

WITH CTE AS
(
    SELECT ES.EMP_ID,
           ES.SALARY,
           ES.EFFECTIVE_DATE,
           ROW_NUMBER() OVER(
               PARTITION BY ES.EMP_ID
               ORDER BY ES.EFFECTIVE_DATE DESC
           ) AS RN
    FROM EMPLOYEE_SALARY ES
    WHERE STATUS = 'ACTIVE'
),
WITH CTE2 AS
(
    SELECT EMP_ID,
           EMP_NAME,
           SALARY,
           EFFECTIVE_DATE
    FROM CTE
    WHERE RN = 1
)
SELECT E.EMP_ID,
       E.EMP_NAME,
       E.SALARY,
       E.EFFECTIVE_DATE
FROM EMPLOYEE E
LEFT JOIN CTE2 C
    ON E.EMP_ID = C.EMP_ID;


RESULT:
✗ INCORRECT


PROBLEM 1:

You cannot write:

WITH CTE AS (...),
WITH CTE2 AS (...)


Only the first CTE uses WITH.

Correct:

WITH CTE AS (...),
CTE2 AS (...)


PROBLEM 2:

CTE does NOT contain:

EMP_NAME


But CTE2 tries:

SELECT EMP_ID, EMP_NAME...


EMP_NAME isnt available there.


You dont even need CTE2.

The cleaner solution is:


CORRECT ANSWER:

WITH CTE AS
(
    SELECT ES.EMP_ID,
           ES.SALARY,
           ES.EFFECTIVE_DATE,
           ROW_NUMBER() OVER(
               PARTITION BY ES.EMP_ID
               ORDER BY ES.EFFECTIVE_DATE DESC
           ) AS RN
    FROM EMPLOYEE_SALARY ES
    WHERE ES.STATUS = 'ACTIVE'
)
SELECT E.EMP_ID,
       E.EMP_NAME,
       C.SALARY,
       C.EFFECTIVE_DATE
FROM EMPLOYEE E
LEFT JOIN CTE C
    ON E.EMP_ID = C.EMP_ID
   AND C.RN = 1;


Notice something important:

I put:

C.RN = 1

in the `ON` condition.

Because this is a `LEFT JOIN`, that preserves employees who dont have an ACTIVE salary.


Your core logic was good:

ACTIVE
 ↓
ROW_NUMBER
 ↓
latest
 ↓
LEFT JOIN


But your query construction broke it.


==================================================
PATTERN 4 — SALARY INCREASE + PERCENTAGE
--------------------------------------------------

YOUR ANSWER:

WITH CTE AS
(
    SELECT ES.EMP_ID,
           ES.EFFECTIVE_DATE,
           LAG(ES.SALARY) OVER(
               PARTITION BY ES.EMP_ID
               ORDER BY ES.EFFECTIVE_DATE DESC
           ) AS PREVIOUS_SALARY,
           ES.SALARY AS CURRENT_SALARY
    FROM EMPLOYEE_SALARY ES
)
SELECT EMP_ID,
       EFFECTIVE_DATE,
       PREVIOUS_SALARY,
       CURRENT_SALARY
       (CURRENT_SALARY - PREVIOUS_SALARY) AS SALARY_INCREASE
       ((CURRENT_SALARY - PREVIOUS_SALARY)
        / PREVIOUS_SALARY * 100) AS INCREASE_PERCENTAGE
FROM CTE
WHERE CURRENT_SALARY > PREVIOUS_SALARY;


RESULT:
✗ INCORRECT


There are TWO important problems.


PROBLEM 1 — WRONG ORDER

You wrote:

ORDER BY EFFECTIVE_DATE DESC


But "previous salary" means previous chronologically.

You need:

ORDER BY EFFECTIVE_DATE


Example:

2024 → 30000
2025 → 36000
2026 → 33000


With ASC:

2024 → NULL
2025 → 30000
2026 → 36000


Correct.


With DESC:

2026 → NULL
2025 → 33000
2024 → 36000


Thats the opposite direction.


PROBLEM 2 — MISSING COMMAS

You wrote:

CURRENT_SALARY
(CURRENT_SALARY - PREVIOUS_SALARY)


You need:

CURRENT_SALARY,
(CURRENT_SALARY - PREVIOUS_SALARY)


And another comma before the percentage expression.


CORRECT ANSWER:

WITH CTE AS
(
    SELECT ES.EMP_ID,
           ES.EFFECTIVE_DATE,
           LAG(ES.SALARY) OVER(
               PARTITION BY ES.EMP_ID
               ORDER BY ES.EFFECTIVE_DATE
           ) AS PREVIOUS_SALARY,
           ES.SALARY AS CURRENT_SALARY
    FROM EMPLOYEE_SALARY ES
)
SELECT EMP_ID,
       EFFECTIVE_DATE,
       PREVIOUS_SALARY,
       CURRENT_SALARY,
       CURRENT_SALARY - PREVIOUS_SALARY
           AS SALARY_INCREASE,
       (CURRENT_SALARY - PREVIOUS_SALARY)
           / PREVIOUS_SALARY * 100
           AS INCREASE_PERCENTAGE
FROM CTE
WHERE CURRENT_SALARY > PREVIOUS_SALARY;


KEY LESSON:

For historical data:

ORDER BY DATE ASC

usually means:

oldest
 ↓
newest


Therefore:

LAG()
 ↓
previous chronological record


==================================================
PATTERN 5 — DEPARTMENT PERFORMANCE
--------------------------------------------------

YOUR ANSWER:

WITH CTE AS
(
    SELECT A.EMP_ID,
           SUM(CASE WHEN STATUS = 'PRESENT'
                    THEN 1 ELSE 0 END) AS PRESENT_DAYS,
           SUM(CASE WHEN STATUS = 'ABSENT'
                    THEN 1 ELSE 0 END) AS ABSENT_DAYS
    FROM ATTENDANCE A
    GROUP BY A.EMP_ID
    AND TO_CHAR(ATT_DATE,'MON-RRRR') = 'SEP-2026'
)

SELECT D.DEPT_ID,
       D.DEPT_NAME,
       COUNT(*) AS TOTAL_EMPLOYEES,
       PRESENT_DAYS,
       ABSENT_DAYS,
       AVG(SALARY) AS AVG_SALARY
FROM EMPLOYEE E
JOIN DEPARTMENT D
    ON E.DEPT_ID = D.DEPT_ID
LEFT JOIN CTE C
    ON E.EMP_ID = C.EMP_ID
GROUP BY D.DEPT_ID,
         D.DEPT_NAME;


RESULT:
✗ INCORRECT


There are several problems here.


PROBLEM 1 — CONDITION AFTER GROUP BY

You wrote:

GROUP BY A.EMP_ID
AND TO_CHAR(ATT_DATE,'MON-RRRR') = 'SEP-2026'


This is invalid.

The date condition belongs in:

WHERE


Correct:

WHERE A.ATT_DATE >= DATE '2026-09-01'
  AND A.ATT_DATE < DATE '2026-10-01'

GROUP BY A.EMP_ID


PROBLEM 2 — AVG(SALARY) IS WRONG

This is the big conceptual problem.

You join:

EMPLOYEE
+
attendance summary


An employee can have attendance statistics, but the salary should still be counted only once.

Your current structure can work if CTE has exactly one row per employee, which yours does, but you arent explicitly carrying the salary/employee-level aggregation safely.

More importantly, the question specifically warned you about row multiplication.

The safest design is to aggregate attendance separately at the department level, then join it to the employee/department salary aggregation.


A CLEAN CORRECT SOLUTION:

WITH ATT_CTE AS
(
    SELECT E.DEPT_ID,
           SUM(CASE WHEN A.STATUS = 'PRESENT'
                    THEN 1 ELSE 0 END) AS PRESENT_DAYS,
           SUM(CASE WHEN A.STATUS = 'ABSENT'
                    THEN 1 ELSE 0 END) AS ABSENT_DAYS
    FROM EMPLOYEE E
    LEFT JOIN ATTENDANCE A
        ON E.EMP_ID = A.EMP_ID
       AND A.ATT_DATE >= DATE '2026-09-01'
       AND A.ATT_DATE < DATE '2026-10-01'
    GROUP BY E.DEPT_ID
),
EMP_CTE AS
(
    SELECT D.DEPT_ID,
           D.DEPT_NAME,
           COUNT(E.EMP_ID) AS TOTAL_EMPLOYEES,
           AVG(E.SALARY) AS AVG_SALARY
    FROM DEPARTMENT D
    JOIN EMPLOYEE E
        ON D.DEPT_ID = E.DEPT_ID
    GROUP BY D.DEPT_ID,
             D.DEPT_NAME
)
SELECT E.DEPT_ID,
       E.DEPT_NAME,
       E.TOTAL_EMPLOYEES,
       NVL(A.PRESENT_DAYS, 0) AS PRESENT_DAYS,
       NVL(A.ABSENT_DAYS, 0) AS ABSENT_DAYS,
       E.AVG_SALARY
FROM EMP_CTE E
LEFT JOIN ATT_CTE A
    ON E.DEPT_ID = A.DEPT_ID;


WHY THIS IS SAFER:

Employee data:

EMPLOYEE
   ↓
department aggregation
   ↓
one row per department


Attendance data:

ATTENDANCE
   ↓
department aggregation
   ↓
one row per department


Then:

department employee summary
        +
department attendance summary
        ↓
JOIN


No row multiplication.


==================================================
DAY 7 RESULT
==================================================

Pattern 1 → ✓ CORRECT
Pattern 2 → ✗ INCORRECT
Pattern 3 → ✗ INCORRECT
Pattern 4 → ✗ INCORRECT
Pattern 5 → ✗ INCORRECT


SCORE: 45 / 100


==================================================
MOST IMPORTANT DAY 7 LESSON
==================================================

Your problem is NOT that you dont understand SQL.

Your problem is that youre writing queries too quickly.


You repeatedly made errors like:

'PRESENT_DAYS'
instead of
'PRESENT'

GROUP BY ...
AND condition

instead of:

WHERE condition
GROUP BY ...


ORDER BY DATE DESC

instead of:

ORDER BY DATE


WITH CTE AS (...),
WITH CTE2 AS (...)

instead of:

WITH CTE AS (...),
CTE2 AS (...)


Missing commas between SELECT expressions.


These are preventable errors.


==================================================
YOUR PRE-SUBMISSION CHECKLIST
==================================================

Before sending ANY SQL answer, spend 30 seconds checking:

[ ] Every SELECT expression has a comma
    unless it is the last expression.

[ ] Every table has the correct alias.

[ ] STATUS value is the actual data value,
    not the output column name.

[ ] WHERE comes before GROUP BY.

[ ] GROUP BY comes before HAVING.

[ ] Historical LAG() normally uses
    ORDER BY DATE ASC.

[ ] Only the first CTE has WITH.

[ ] LEFT JOIN conditions that must preserve
    unmatched rows belong in ON.

[ ] ROW_NUMBER() filtering is done outside
    the window-function query.

[ ] I have checked whether JOINs multiply rows.


==================================================
DAY 7 — COMPLETED
==================================================
