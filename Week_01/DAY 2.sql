==================================================
NON-NEGOTIABLE TASK 2 — SQL/PLSQL
QUESTION + ANSWER CHECK
==================================================


PATTERN 1 — GROUP BY + HAVING
--------------------------------------------------

QUESTION:
Find departments where:

- Department has at least 3 employees
- Maximum salary is greater than 50,000

Return:
DEPT_ID
EMP_COUNT
MAX_SALARY


YOUR ANSWER:

SELECT DEPT_ID,
       COUNT(*) AS EMP_COUNT,
       MAX(SALARY) AS MAX_SALARY
FROM EMPLOYEE
GROUP BY DEPT_ID
HAVING COUNT(*) >= 3
   AND MAX(SALARY) > 50000;


RESULT:
✓ CORRECT

KEY CONCEPT:
WHERE  → filters individual rows
HAVING → filters groups/aggregated results


==================================================
PATTERN 2 — EXISTS
--------------------------------------------------

QUESTION:
Find employees who belong to a department located
in 'DELHI'.

Restriction:
- Use EXISTS
- Do not use JOIN


YOUR ANSWER:

SELECT E.EMP_ID,
       E.EMP_NAME
FROM EMPLOYEE E
WHERE EXISTS
(
    SELECT 1
    FROM DEPARTMENT D
    WHERE D.LOCATION = 'DELHI'
      AND D.DEPT_ID = E.DEPT_ID
);


RESULT:
✓ CORRECT


KEY CONCEPT:

EXISTS checks whether the subquery returns
at least one row.

The important correlation is:

D.DEPT_ID = E.DEPT_ID


==================================================
PATTERN 3 — FIND DUPLICATES
--------------------------------------------------

QUESTION:
Find MOBILE_NO values that occur more than once.

Return:
MOBILE_NO
OCCURRENCE


YOUR ANSWER:

SELECT C.MOBILE_NO,
       COUNT(C.MOBILE_NO) AS OCCURRENCE
FROM CUSTOMER C
GROUP BY C.MOBILE_NO
HAVING COUNT(C.MOBILE_NO) > 1;


RESULT:
✓ CORRECT


KEY CONCEPT:

GROUP BY MOBILE_NO
        ↓
COUNT each mobile number
        ↓
HAVING COUNT > 1
        ↓
Duplicates


INTERVIEW FOLLOW-UP:

To retrieve the COMPLETE CUSTOMER RECORDS having
duplicate mobile numbers, you could use:

SELECT C.*
FROM CUSTOMER C
WHERE C.MOBILE_NO IN
(
    SELECT MOBILE_NO
    FROM CUSTOMER
    GROUP BY MOBILE_NO
    HAVING COUNT(*) > 1
);


==================================================
PATTERN 4 — TOP N PER GROUP
--------------------------------------------------

QUESTION:
Find the top 2 highest-paid employees from each
department.

Return:
EMP_ID
EMP_NAME
DEPT_ID
SALARY

Use a window function.


YOUR ANSWER:

SELECT EMP_ID,
       EMP_NAME,
       DEPT_ID,
       SALARY
FROM
(
    SELECT EMP_ID,
           EMP_NAME,
           DEPT_ID,
           SALARY,
           ROW_NUMBER() OVER
           (
               PARTITION BY DEPT_ID
               ORDER BY SALARY DESC
           ) AS RNK
    FROM EMPLOYEE
)
WHERE RNK <= 2;


RESULT:
✓ CORRECT


KEY CONCEPT:

PARTITION BY DEPT_ID
    → Restart ranking for every department

ORDER BY SALARY DESC
    → Highest salary first

ROW_NUMBER()
    → Assigns 1, 2, 3... within each department


IMPORTANT INTERVIEW DIFFERENCE:

ROW_NUMBER()
    → Exactly 2 employees per department

RANK()
    → Can return MORE than 2 employees if there
      are salary ties at rank 2.


==================================================
PATTERN 5 — MISSING RECORDS
--------------------------------------------------

QUESTION:
Find employees who do not have an attendance record
for 08-09-2026.

Restriction:
Use LEFT JOIN.


YOUR ANSWER:

SELECT E.EMP_ID,
       E.EMP_NAME
FROM EMPLOYEE E
LEFT JOIN ATTENDANCE A
       ON E.EMP_ID = A.EMP_ID
WHERE A.ATT_DATE = '08-09-2026'
  AND A.EMP_ID IS NULL;


RESULT:
✗ INCORRECT


PROBLEM:

This condition is the issue:

WHERE A.ATT_DATE = '08-09-2026'


For employees who have NO attendance record,
all columns from A become NULL.

Therefore:

A.ATT_DATE = '08-09-2026'

is FALSE/UNKNOWN for those employees.

Your query therefore eliminates the very rows
you are trying to find.


CORRECT ANSWER:

SELECT E.EMP_ID,
       E.EMP_NAME
FROM EMPLOYEE E
LEFT JOIN ATTENDANCE A
       ON E.EMP_ID = A.EMP_ID
      AND A.ATT_DATE = DATE '2026-09-08'
WHERE A.EMP_ID IS NULL;


IMPORTANT:

The date condition belongs in the ON clause:

ON E.EMP_ID = A.EMP_ID
AND A.ATT_DATE = DATE '2026-09-08'


Then:

WHERE A.EMP_ID IS NULL


means:

"No matching attendance record exists
for that particular date."


KEY CONCEPT:

LEFT JOIN + IS NULL
        ↓
Find missing related records


VERY IMPORTANT INTERVIEW RULE:

If you want to preserve unmatched rows from
the LEFT table, be careful when putting conditions
on the RIGHT table in WHERE.

Often:

LEFT JOIN ... WHERE right_table.column = X

can effectively turn your LEFT JOIN into an
INNER JOIN for that condition.


==================================================
TASK 2 RESULT
==================================================

Pattern 1 — GROUP BY + HAVING       ✓ CORRECT
Pattern 2 — EXISTS                  ✓ CORRECT
Pattern 3 — Duplicates              ✓ CORRECT
Pattern 4 — Top N per Group         ✓ CORRECT
Pattern 5 — Missing Records         ✗ INCORRECT


SCORE: 4 / 5
PERCENTAGE: 80%


DAY 1: 68%
DAY 2: 80%

IMPROVEMENT: +12 percentage points


==================================================
DAY 2 WEAK AREA
==================================================

LEFT JOIN + filtering on the right table

Remember this pattern:

FROM A
LEFT JOIN B
    ON A.ID = B.ID
   AND B.DATE = required_date
WHERE B.ID IS NULL;


Meaning:

"Give me A records for which no matching B record
exists for this condition."


==================================================
IMPORTANT ORACLE NOTE
==================================================

For Oracle, prefer:

DATE '2026-09-08'

instead of:

'08-09-2026'

because a plain string depends on the sessions
NLS date format.

This matters in your office SQL work.


==================================================
TASK 2 STATUS
==================================================

✓ COMPLETED

Next:
DAY 3

Focus:
SUBQUERIES → CTE → ROW_NUMBER → RANK/DENSE_RANK
→ LAG/LEAD
==================================================
