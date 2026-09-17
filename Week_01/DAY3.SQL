==================================================
NON-NEGOTIABLE TASK 3 — SQL/PLSQL
QUESTION + ANSWER CHECK
==================================================


PATTERN 1 — ROW_NUMBER() FOR LATEST RECORD
--------------------------------------------------

QUESTION:
Find the latest salary record for every employee.

YOUR ANSWER:

SELECT EMP_ID,
       SALARY,
       EFFECTIVE_DATE
FROM
(
    SELECT EMP_ID,
           SALARY,
           EFFECTIVE_DATE,
           ROW_NUMBER() OVER(
               PARTITION BY EMP_ID
               ORDER BY EFFECTIVE_DATE DESC
           ) AS RNK
    FROM EMPLOYEE_SALARY
)
WHERE RNK = 1;


RESULT:
✓ CORRECT


KEY CONCEPT:

PARTITION BY EMP_ID
    → Separate ranking for every employee

ORDER BY EFFECTIVE_DATE DESC
    → Latest record comes first

ROW_NUMBER() = 1
    → Pick the latest record


==================================================
PATTERN 2 — DENSE_RANK()
--------------------------------------------------

QUESTION:
Find the 3rd highest DISTINCT salary in each department.

YOUR ANSWER:

SELECT DISTINCT DEPT_ID,
       EMP_NAME,
       SALARY
FROM
(
    SELECT DEPT_ID,
           EMP_NAME,
           SALARY,
           DENSE_RANK() OVER(
               PARTITION BY DEPT_ID
               ORDER BY SALARY DESC
           ) AS RNK
    FROM EMPLOYEE
)
WHERE RNK = 3;


RESULT:
✓ CORRECT


KEY CONCEPT:

DENSE_RANK() handles duplicate salaries without
skipping the next rank.

Example:

90000 → 1
80000 → 2
80000 → 2
70000 → 3


IMPORTANT:
Your DISTINCT is not necessary for the normal
case because each employee row is already returned.

But it does not make the query incorrect.


==================================================
PATTERN 3 — LAG()
--------------------------------------------------

QUESTION:
For every salary record, show the previous salary
for that employee based on EFFECTIVE_DATE.


YOUR ANSWER:

SELECT EMP_ID,
       EFFECTIVE_DATE,
       SALARY,
       LAG(SALARY) OVER(
           PARTITION BY EMP_ID
           ORDER BY EFFECTIVE_DATE
       ) AS PREVIOUS_SALARY
FROM EMPLOYEE_SALARY;


RESULT:
✓ CORRECT


KEY CONCEPT:

LAG()
    → Look at a previous row

PARTITION BY EMP_ID
    → Previous row must belong to the same employee

ORDER BY EFFECTIVE_DATE
    → Defines what "previous" means


==================================================
PATTERN 4 — LEAD()
--------------------------------------------------

QUESTION:
For every salary record, show the next salary
for that employee based on EFFECTIVE_DATE.


YOUR ANSWER:

SELECT EMP_ID,
       EFFECTIVE_DATE,
       SALARY,
       LEAD(SALARY) OVER(
           PARTITION BY EMP_ID
           ORDER BY EFFECTIVE_DATE
       ) AS NEXT_SALARY
FROM EMPLOYEE_SALARY;


RESULT:
✓ CORRECT


KEY CONCEPT:

LEAD()
    → Look at a future/next row

LAG()
    → Look backward

LEAD()
    → Look forward


MENTAL MODEL:

        Previous     Current      Next
           ↑           │           ↓
         LAG()       ROW        LEAD()


==================================================
PATTERN 5 — CTE + AGGREGATION
--------------------------------------------------

QUESTION:
For September 2026, find each employees:

- Total attendance days
- Average working hours
- Maximum working hours

YOUR ANSWER:

WITH CTE AS
(
    SELECT E.EMP_ID,
           E.EMP_NAME,
           A.ATT_DATE,
           ((A.OUT_TIME - A.IN_TIME) * 24) AS WORKING_HR
    FROM EMPLOYEE E
    INNER JOIN ATT_DATE A
        ON E.EMP_ID = A.EMP_ID
    WHERE A.ATT_DATE BETWEEN
          TO_DATE('01-09-2026','DD-MM-RRRR')
          AND TO_DATE('30-09-2026','DD-MM-RRRR')
)

SELECT EMP_ID,
       EMP_NAME,
       COUNT(ATT_DATE) AS ATTENDANCE_DAYS,
       AVG(WORKING_HR) AS AVG_WORKING_HOURS
       MAX(WORKING_HR) AS MAX_WORKING_HOURS
FROM CTE
GROUP BY EMP_ID, EMP_NAME;


RESULT:
✗ INCORRECT


PROBLEMS:

1. ATT_DATE is being used as a table name.

You wrote:

INNER JOIN ATT_DATE A

But ATT_DATE is a COLUMN of ATTENDANCE.

It should be:

INNER JOIN ATTENDANCE A


2. Missing comma after AVG(WORKING_HR).

You wrote:

AVG(WORKING_HR) AS AVG_WORKING_HOURS
MAX(WORKING_HR) AS MAX_WORKING_HOURS

It needs:

AVG(WORKING_HR) AS AVG_WORKING_HOURS,
MAX(WORKING_HR) AS MAX_WORKING_HOURS


CORRECT ANSWER:

WITH CTE AS
(
    SELECT E.EMP_ID,
           E.EMP_NAME,
           A.ATT_DATE,
           (A.OUT_TIME - A.IN_TIME) * 24 AS WORKING_HR
    FROM EMPLOYEE E
    INNER JOIN ATTENDANCE A
        ON E.EMP_ID = A.EMP_ID
    WHERE A.ATT_DATE >= DATE '2026-09-01'
      AND A.ATT_DATE <  DATE '2026-10-01'
)
SELECT EMP_ID,
       EMP_NAME,
       COUNT(ATT_DATE) AS ATTENDANCE_DAYS,
       AVG(WORKING_HR) AS AVG_WORKING_HOURS,
       MAX(WORKING_HR) AS MAX_WORKING_HOURS
FROM CTE
GROUP BY EMP_ID,
         EMP_NAME;


KEY CONCEPT:

STEP 1:
CTE calculates DAILY working hours.

        ↓

STEP 2:
GROUP BY employee.

        ↓

STEP 3:
COUNT → attendance days
AVG   → average working hours
MAX   → maximum working hours


IMPORTANT ORACLE DATE POINT:

Instead of:

BETWEEN TO_DATE('01-09-2026','DD-MM-RRRR')
    AND TO_DATE('30-09-2026','DD-MM-RRRR')


this is safer when ATT_DATE contains a TIME:

A.ATT_DATE >= DATE '2026-09-01'
AND A.ATT_DATE < DATE '2026-10-01'


Why?

If ATT_DATE is:

30-09-2026 15:30:00

then:

A.ATT_DATE <= DATE '2026-09-30'

can fail because DATE '2026-09-30' means:

30-09-2026 00:00:00


==================================================
TASK 3 RESULT
==================================================

Pattern 1 — ROW_NUMBER()       ✓ CORRECT
Pattern 2 — DENSE_RANK()       ✓ CORRECT
Pattern 3 — LAG()              ✓ CORRECT
Pattern 4 — LEAD()             ✓ CORRECT
Pattern 5 — CTE + Aggregation  ✗ INCORRECT


SCORE: 4 / 5

PERCENTAGE: 80%


==================================================
DAY-BY-DAY TRACKING
==================================================

DAY 1 → 68%
DAY 2 → 80%
DAY 3 → 80%


CURRENT AVERAGE:
76%


==================================================
WHAT YOU ARE GETTING RIGHT
==================================================

✓ GROUP BY / HAVING
✓ JOIN
✓ EXISTS
✓ Duplicate detection
✓ ROW_NUMBER
✓ DENSE_RANK
✓ LAG
✓ LEAD


WHAT STILL NEEDS ATTENTION:

1. SQL syntax precision
   → commas, aliases, table names

2. Oracle date/time handling
   → DATE arithmetic
   → date ranges

3. Reading the schema carefully
   → ATTENDANCE is the table
   → ATT_DATE is the column


==================================================
DAY 3 — COMPLETED
==================================================