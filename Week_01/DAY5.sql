==================================================
NON-NEGOTIABLE TASK 5 — SQL/PLSQL
QUESTION + ANSWER CHECK
==================================================


PATTERN 1 — NOT EXISTS
--------------------------------------------------

QUESTION:
Find employees who have never had an ABSENT attendance
record.

YOUR ANSWER:

SELECT E.EMP_ID,
       E.EMP_NAME
FROM EMPLOYEE E
WHERE NOT EXISTS
(
    SELECT 1
    FROM ATTENDANCE A
    WHERE E.EMP_ID = A.EMP_ID
      AND STATUS = 'ABSENT'
);


RESULT:
✓ CORRECT


KEY CONCEPT:

NOT EXISTS
    ↓
Checks that NO matching row exists.

Correlation:

E.EMP_ID = A.EMP_ID

Condition:

STATUS = 'ABSENT'


Meaning:

"For this employee, there must not be an attendance
record whose status is ABSENT."


==================================================
PATTERN 2 — DENSE_RANK()
--------------------------------------------------

QUESTION:
Find employees receiving the second-highest DISTINCT
salary in each department.

YOUR ANSWER:

SELECT E.EMP_ID,
       E.EMP_NAME,
       E.DEPT_ID,
       E.SALARY
FROM
(
    SELECT E.EMP_ID,
           E.EMP_NAME,
           E.DEPT_ID,
           E.SALARY,
           DENSE_RANK() OVER(
               PARTITION BY E.DEPT_ID
               ORDER BY E.SALARY DESC
           ) AS RNK
    FROM EMPLOYEE E
)
WHERE RNK = 2;


RESULT:
✓ CORRECT


KEY CONCEPT:

DENSE_RANK()
+
PARTITION BY DEPT_ID
+
ORDER BY SALARY DESC
+
RNK = 2

This correctly returns ALL employees tied at the
second-highest distinct salary.


==================================================
PATTERN 3 — CTE + JOIN + AGGREGATION
--------------------------------------------------

QUESTION:
Find attendance percentage for every employee for
September 2026.

Employees with NO attendance record must also appear.


YOUR ANSWER:

WITH CTE AS
(
    SELECT EMP_ID,
           SUM(CASE WHEN STATUS = 'PRESENT'
                    THEN 1 ELSE 0 END) AS PRESENT_DAYS,
           SUM(CASE WHEN STATUS = 'HALF DAY'
                    THEN 1 ELSE 0 END) AS HALF_DAYS,
           SUM(CASE WHEN STATUS = 'ABSENT'
                    THEN 1 ELSE 0 END) AS ABSENT_DAYS,
           COUNT(*) AS TOT_ATT
    FROM ATTENDANCE
    WHERE TO_CHAR(ATT_DATE,'MM-RRRR') = '09-2026'
    GROUP BY EMP_ID
)
SELECT E.EMP_ID,
       E.EMP_NAME,
       C.PRESENT_DAYS
       C.HALF_DAYS,
       C.ABSENT_DAYS,
       (C.PRESENT_DAYS + C.HALF_DAYS * 0.5)
       / C.TOT_ATT * 100 AS ATTENDANCE_PERCENTAGE
FROM EMPLOYEE E
INNER JOIN CTE C
    ON E.EMP_ID = C.EMP_ID;


RESULT:
✗ INCORRECT


PROBLEMS:

1. You used INNER JOIN.

The requirement says:

"An employee with no attendance record in
September should still appear."

INNER JOIN removes those employees.

You need:

LEFT JOIN


2. Missing comma:

C.PRESENT_DAYS
C.HALF_DAYS

should be:

C.PRESENT_DAYS,
C.HALF_DAYS


3. You didnt handle NULL values for employees
with no attendance record.

For those employees:

C.PRESENT_DAYS = NULL
C.HALF_DAYS = NULL
C.TOT_ATT = NULL


You need NVL/COALESCE.


4. Date filtering with TO_CHAR()

This works logically for month/year matching, but it is
not the best Oracle approach because it applies a
function to ATT_DATE.

Better:

ATT_DATE >= DATE '2026-09-01'
AND ATT_DATE < DATE '2026-10-01'


CORRECT ANSWER:

WITH CTE AS
(
    SELECT EMP_ID,
           SUM(CASE WHEN STATUS = 'PRESENT'
                    THEN 1 ELSE 0 END) AS PRESENT_DAYS,
           SUM(CASE WHEN STATUS = 'HALF DAY'
                    THEN 1 ELSE 0 END) AS HALF_DAYS,
           SUM(CASE WHEN STATUS = 'ABSENT'
                    THEN 1 ELSE 0 END) AS ABSENT_DAYS,
           COUNT(*) AS TOT_ATT
    FROM ATTENDANCE
    WHERE ATT_DATE >= DATE '2026-09-01'
      AND ATT_DATE <  DATE '2026-10-01'
    GROUP BY EMP_ID
)
SELECT E.EMP_ID,
       E.EMP_NAME,
       NVL(C.PRESENT_DAYS, 0) AS PRESENT_DAYS,
       NVL(C.HALF_DAYS, 0) AS HALF_DAYS,
       NVL(C.ABSENT_DAYS, 0) AS ABSENT_DAYS,
       CASE
           WHEN NVL(C.TOT_ATT, 0) = 0 THEN 0
           ELSE
               (NVL(C.PRESENT_DAYS, 0)
                + NVL(C.HALF_DAYS, 0) * 0.5)
               / C.TOT_ATT * 100
       END AS ATTENDANCE_PERCENTAGE
FROM EMPLOYEE E
LEFT JOIN CTE C
    ON E.EMP_ID = C.EMP_ID;


KEY CONCEPT:

EMPLOYEE
    ↓
LEFT JOIN
    ↓
Attendance statistics


LEFT JOIN ensures:

Employee WITH attendance → statistics

Employee WITHOUT attendance → NULL statistics
                              ↓
                            NVL → 0


IMPORTANT:

This question was testing more than CTE.

It was testing:

CTE
+
GROUP BY
+
CASE
+
LEFT JOIN
+
NVL
+
date filtering


==================================================
PATTERN 4 — LAG() + COMPARISON
--------------------------------------------------

QUESTION:
Find salary records where salary increased compared
with the previous salary.

YOUR ANSWER:

WITH CTE AS
(
    SELECT E.EMP_ID,
           E.EFFECTIVE_DATE,
           E.SALARY,
           LAG(SALARY) OVER(
               PARTITION BY E.EMP_ID
               ORDER BY E.EFFECTIVE_DATE
           ) AS PREVIOUS_SALARY
    FROM EMPLOYEE_SALARY E
)
SELECT EMP_ID,
       EFFECTIVE_DATE,
       SALARY,
       PREVIOUS_SALARY,
       (SALARY - PREVIOUS_SALARY) AS SALARY_INCREASE
FROM CTE
WHERE SALARY > PREVIOUS_SALARY;


RESULT:
✓ CORRECT


KEY CONCEPT:

Step 1:

LAG(SALARY)
    ↓
Get previous salary


Step 2:

SALARY - PREVIOUS_SALARY
    ↓
Calculate increase


Step 3:

WHERE SALARY > PREVIOUS_SALARY
    ↓
Keep only increases


Excellent use of the two-step pattern:

Window function
        ↓
CTE
        ↓
Filter calculated result


==================================================
PATTERN 5 — LATEST ACTIVE RECORD
--------------------------------------------------

QUESTION:
Find the latest ACTIVE bank account for every vendor.

Rules:

- Ignore INACTIVE
- Latest ACTIVE record only
- Vendor without ACTIVE record should not appear


YOUR ANSWER:

SELECT VENDOR_ID,
       BANK_AC_NO,
       CREATED_DATE
FROM
(
    SELECT VENDOR_ID,
           BANK_AC_NO,
           CREATED_DATE,
           ROW_NUMBER() OVER(
               PARTITION BY VENDOR_ID
               ORDER BY CREATED_DATE DESC
           ) AS RNK
           WHERE STATUS = 'ACTIVE'
)
WHERE RNK = 1;


RESULT:
✗ INCORRECT


PROBLEM:

Your WHERE clause is in the wrong place.

You wrote:

ROW_NUMBER() OVER(...)
WHERE STATUS = 'ACTIVE'


You need:

FROM VENDOR_BANK_DETAIL
WHERE STATUS = 'ACTIVE'


inside the subquery.


CORRECT ANSWER:

SELECT VENDOR_ID,
       BANK_AC_NO,
       CREATED_DATE
FROM
(
    SELECT VENDOR_ID,
           BANK_AC_NO,
           CREATED_DATE,
           ROW_NUMBER() OVER(
               PARTITION BY VENDOR_ID
               ORDER BY CREATED_DATE DESC
           ) AS RNK
    FROM VENDOR_BANK_DETAIL
    WHERE STATUS = 'ACTIVE'
)
WHERE RNK = 1;


KEY CONCEPT:

This order is critical:

FROM VENDOR_BANK_DETAIL
        ↓
WHERE STATUS = 'ACTIVE'
        ↓
ROW_NUMBER()
        ↓
PARTITION BY VENDOR_ID
        ↓
ORDER BY CREATED_DATE DESC
        ↓
RNK = 1


Why filter ACTIVE first?

Suppose:

VENDOR_ID | STATUS    | DATE
----------|-----------|------------
101       | ACTIVE    | Jan
101       | ACTIVE    | Feb
101       | INACTIVE  | Mar


We want:

Feb


NOT:

Mar


Therefore, INACTIVE records must be removed
BEFORE ROW_NUMBER() is calculated.


==================================================
TASK 5 RESULT
==================================================

Pattern 1 — NOT EXISTS             ✓ CORRECT
Pattern 2 — DENSE_RANK             ✓ CORRECT
Pattern 3 — CTE + JOIN              ✗ INCORRECT
Pattern 4 — LAG()                   ✓ CORRECT
Pattern 5 — Latest Active Record   ✗ INCORRECT


SCORE: 30 / 50
PERCENTAGE: 60%


==================================================
DAY-BY-DAY TRACKING
==================================================

DAY 1 → 68%
DAY 2 → 80%
DAY 3 → 80%
DAY 4 → 52%
DAY 5 → 60%


CURRENT AVERAGE → 68%


==================================================
MOST IMPORTANT LESSON FROM DAY 5
==================================================

SQL is not only about knowing functions.

You need to understand:

WHAT HAPPENS FIRST?
        ↓
WHERE
        ↓
GROUP BY
        ↓
WINDOW FUNCTION
        ↓
OUTER FILTER


Especially remember:

FILTER BEFORE ROW_NUMBER()

when you want the latest record
from a specific subset of data.


Example:

WHERE STATUS = 'ACTIVE'
        ↓
ROW_NUMBER()
        ↓
RN = 1


NOT:

ROW_NUMBER() over everything
        ↓
then try to filter ACTIVE


==================================================
DAY 5 — COMPLETED
==================================================