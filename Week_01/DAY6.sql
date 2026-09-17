==================================================
NON-NEGOTIABLE TASK 6 — SQL/PLSQL
QUESTION + ANSWER CHECK
==================================================


PATTERN 1 — LEFT JOIN: FILTER IN ON
--------------------------------------------------

QUESTION:
Find all employees and their PRESENT attendance
records for September 2026.

Employees without PRESENT attendance must still
appear.

YOUR ANSWER:

SELECT E.EMP_ID,
       E.EMP_NAME,
       A.ATT_DATE,
       A.STATUS
FROM EMPLOYEE E
LEFT JOIN ATTENDANCE A
    ON E.EMP_ID = A.EMP_ID
   AND A.STATUS = 'PRESENT'
   AND TO_CHAR(A.ATT_DATE,'MON-RRRR') = 'SEP-2026';


RESULT:
✓ CORRECT


WHY?

You correctly placed:

A.STATUS = 'PRESENT'

and

September condition

inside the ON clause.

Therefore the LEFT JOIN still preserves employees
who dont have a matching attendance record.


IMPORTANT:

If you had written:

LEFT JOIN ATTENDANCE A
    ON E.EMP_ID = A.EMP_ID
WHERE A.STATUS = 'PRESENT'


then employees with no attendance would have:

A.STATUS = NULL

and would be removed by WHERE.

That effectively turns the LEFT JOIN into an
INNER JOIN for this condition.


ONE IMPROVEMENT:

Instead of:

TO_CHAR(A.ATT_DATE,'MON-RRRR') = 'SEP-2026'


prefer:

A.ATT_DATE >= DATE '2026-09-01'
AND A.ATT_DATE < DATE '2026-10-01'


So a production-style version is:

SELECT E.EMP_ID,
       E.EMP_NAME,
       A.ATT_DATE,
       A.STATUS
FROM EMPLOYEE E
LEFT JOIN ATTENDANCE A
    ON E.EMP_ID = A.EMP_ID
   AND A.STATUS = 'PRESENT'
   AND A.ATT_DATE >= DATE '2026-09-01'
   AND A.ATT_DATE < DATE '2026-10-01';


Your LOGIC is correct.


==================================================
PATTERN 2 — AGGREGATION BEFORE JOIN
--------------------------------------------------

QUESTION:
Find every employees number of PRESENT days in
September 2026.

Employees with zero PRESENT days must appear.


YOUR ANSWER:

WITH CTE AS
(
    SELECT A.EMP_ID AS EMP_ID,
           COUNT(*) AS CTN
    FROM ATTENDANCE A
    WHERE TO_CHAR(A.ATT_DATE,'MON-RRRR') = 'SEP-2026'
      AND STATUS = 'PRESENT'
    GROUP BY A.EMP_ID
)
SELECT E.EMP_ID,
       E.EMP_NAME,
       NVL(C.CTN,0) AS PRESENT_DAYS
FROM EMPLOYEE E
LEFT JOIN CTE C
    ON E.EMP_ID = C.EMP_ID;


RESULT:
✓ CORRECT


This is exactly the intended pattern:

ATTENDANCE
    ↓
Filter PRESENT
    ↓
GROUP BY EMP_ID
    ↓
CTE
    ↓
LEFT JOIN EMPLOYEE
    ↓
NVL()


Excellent.


ONE IMPROVEMENT:

Again, for Oracle date filtering, prefer:

WHERE A.ATT_DATE >= DATE '2026-09-01'
  AND A.ATT_DATE < DATE '2026-10-01'


instead of TO_CHAR().


==================================================
PATTERN 3 — EMPLOYEES ABOVE DEPARTMENT AVERAGE
--------------------------------------------------

QUESTION:
Find employees whose salary is greater than their
departments average salary.

Use:

CTE + GROUP BY + JOIN


YOUR ANSWER:

WITH CTE AS
(
    SELECT DEPT_ID,
           AVG(SALARY) AS SAL
    FROM EMPLOYEE
    GROUP BY DEPT_ID
)
SELECT E.EMP_ID,
       E.EMP_NAME,
       E.DEPT_ID,
       E.SALARY,
       SAL AS DEPT_AVG_SALARY
       EMPLOYEE E
       JOIN CTE C
       ON E.DEPT_ID = C.DEPT_ID
      AND E.SALARY > SAL;


RESULT:
✗ INCORRECT


Your logic is correct, but the SQL syntax is broken.


PROBLEMS:

1. Missing FROM before EMPLOYEE:

You need:

FROM EMPLOYEE E


2. You should reference SAL through the CTE alias:

C.SAL


3. The alias for the average should be followed by
FROM, not EMPLOYEE.


CORRECT ANSWER:

WITH CTE AS
(
    SELECT DEPT_ID,
           AVG(SALARY) AS DEPT_AVG_SALARY
    FROM EMPLOYEE
    GROUP BY DEPT_ID
)
SELECT E.EMP_ID,
       E.EMP_NAME,
       E.DEPT_ID,
       E.SALARY,
       C.DEPT_AVG_SALARY
FROM EMPLOYEE E
JOIN CTE C
    ON E.DEPT_ID = C.DEPT_ID
WHERE E.SALARY > C.DEPT_AVG_SALARY;


You could also put the comparison inside ON:

FROM EMPLOYEE E
JOIN CTE C
    ON E.DEPT_ID = C.DEPT_ID
   AND E.SALARY > C.DEPT_AVG_SALARY;


Both are logically valid here.


KEY CONCEPT:

CTE:

DEPT_ID → AVG SALARY

Then:

EMPLOYEE
    ↓
JOIN department average
    ↓
SALARY > DEPT_AVG_SALARY


Your THINKING was right.

Your SQL construction was not.


==================================================
PATTERN 4 — LATEST ACTIVE RECORD
--------------------------------------------------

QUESTION:
Find the latest ACTIVE salary record for every
employee.


YOUR ANSWER:

WITH CTE AS
(
    SELECT E.EMP_ID,
           E.SALARY,
           E.EFFECTIVE_DATE,
           ROW_NUMBER() OVER(
               PARTITION BY E.EMP_ID
               ORDER BY ,E.EFFECTIVE_DATE DESC
           ) AS RNK
    FROM EMPLOYEE_SALARY E
    WHERE STATUS = 'ACTIVE'
)
SELECT EMP_ID,
       SALARY,
       EFFECTIVE_DATE
FROM CTE
WHERE RNK = 1;


RESULT:
⚠ ALMOST CORRECT


You fixed the important Day 5 logic:

✓ Filter ACTIVE first
✓ Partition by employee
✓ Order latest first
✓ RNK = 1


But you have one syntax error:

You wrote:

ORDER BY ,E.EFFECTIVE_DATE DESC


Remove the comma.


CORRECT ANSWER:

WITH CTE AS
(
    SELECT E.EMP_ID,
           E.SALARY,
           E.EFFECTIVE_DATE,
           ROW_NUMBER() OVER(
               PARTITION BY E.EMP_ID
               ORDER BY E.EFFECTIVE_DATE DESC
           ) AS RNK
    FROM EMPLOYEE_SALARY E
    WHERE E.STATUS = 'ACTIVE'
)
SELECT EMP_ID,
       SALARY,
       EFFECTIVE_DATE
FROM CTE
WHERE RNK = 1;


IMPORTANT:

This is exactly the mistake you had on Day 5,
and this time your LOGIC is correct.

Thats progress.


==================================================
PATTERN 5 — WHERE vs HAVING
--------------------------------------------------

QUESTION:
Find departments where:

- At least 3 ACTIVE employees
- Average salary > 40,000


YOUR ANSWER:

SELECT E.DEPT_ID,
       COUNT(*) AS ACTIVE_EMP_COUNT,
       AVG(SALARY) AS AVG_SALARY
FROM EMPLOYEE E
WHERE STATUS = 'ACTIVE'
GROUP BY E.DEPT_ID
HAVING COUNT(*) >= 3
   AND AVG(SALARY) > 40000;


RESULT:
✓ CORRECT


Exactly right.


Execution logic:

FROM
 ↓
WHERE STATUS = 'ACTIVE'
 ↓
GROUP BY DEPT_ID
 ↓
COUNT / AVG
 ↓
HAVING


The critical distinction:

WHERE
→ filters individual rows BEFORE aggregation.

HAVING
→ filters groups AFTER aggregation.


==================================================
TASK 6 RESULT
==================================================

Pattern 1 — LEFT JOIN + ON          ✓ CORRECT
Pattern 2 — Aggregation + JOIN      ✓ CORRECT
Pattern 3 — Department Average      ✗ SYNTAX ERROR
Pattern 4 — Latest ACTIVE           ⚠ ALMOST
Pattern 5 — WHERE vs HAVING         ✓ CORRECT


SCORE: 40 / 50
PERCENTAGE: 80%


==================================================
DAY-BY-DAY TRACKING
==================================================

DAY 1 → 68%
DAY 2 → 80%
DAY 3 → 80%
DAY 4 → 52%
DAY 5 → 60%
DAY 6 → 80%


CURRENT AVERAGE → 70%


==================================================
DAY 6 KEY RESULT
==================================================

Your SQL LOGIC is improving.

The biggest remaining problem is:

        SYNTAX PRECISION


Examples today:

❌ ORDER BY ,E.EFFECTIVE_DATE
✓ ORDER BY E.EFFECTIVE_DATE

❌ SAL AS DEPT_AVG_SALARY EMPLOYEE E
✓ C.DEPT_AVG_SALARY
  FROM EMPLOYEE E


So before executing your query, do a 10-second check:

1. Did I write FROM?
2. Did every SELECT expression have a comma?
3. Are all table aliases correct?
4. Did I accidentally type an extra comma?
5. Is the WHERE/ON condition in the correct place?
6. Does every aggregate query have the required GROUP BY?


==================================================
DAY 6 — COMPLETED
==================================================