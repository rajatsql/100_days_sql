==================================================
DAY 8 — QUESTION + YOUR ANSWER + CORRECT ANSWER
==================================================


==================================================
PATTERN 1 — UNION
--------------------------------------------------

QUESTION:

Create one list containing employees from:

EMPLOYEE_CURRENT
EMPLOYEE_FORMER

Return:

EMP_ID
EMP_NAME
DEPT_ID

Requirement:
Use UNION.

Important:
If the same employee exists in both tables,
that employee should appear only once.


YOUR ANSWER:

SELECT EMP_ID,
       EMP_NAME,
       DEPT_ID
FROM EMPLOYEE_CURRENT
UNION
SELECT EMP_ID,
       EMP_NAME,
       DEPT_ID
FROM EMPLOYEE_FORMER;


RESULT:
✓ CORRECT


CORRECT ANSWER:

SELECT EMP_ID,
       EMP_NAME,
       DEPT_ID
FROM EMPLOYEE_CURRENT
UNION
SELECT EMP_ID,
       EMP_NAME,
       DEPT_ID
FROM EMPLOYEE_FORMER;


EXPLANATION:

UNION removes duplicate rows.

Your query exactly matches the requirement.


==================================================
PATTERN 2 — UNION ALL
--------------------------------------------------

QUESTION:

Create one attendance dataset containing all
records from January and February.

Return:

EMP_ID
ATT_DATE
STATUS

Requirement:
Use UNION ALL.

Duplicate rows must NOT be removed.


YOUR ANSWER:

SELECT EMP_ID,
       ATT_DATE,
       STATUS
FROM ATTENDANCE_JAN
UNION ALL
SELECT EMP_ID,
       ATT_DATE,
       STATUS
FROM ATTENDANCE_FEB;


RESULT:
✓ CORRECT


CORRECT ANSWER:

SELECT EMP_ID,
       ATT_DATE,
       STATUS
FROM ATTENDANCE_JAN
UNION ALL
SELECT EMP_ID,
       ATT_DATE,
       STATUS
FROM ATTENDANCE_FEB;


EXPLANATION:

UNION ALL keeps duplicate rows.

Your query is correct.


==================================================
PATTERN 3 — NOT EXISTS
--------------------------------------------------

QUESTION:

Find employees who have no attendance record
at all.

Return:

EMP_ID
EMP_NAME

Requirement:
Use NOT EXISTS.

Do not use:
JOIN
LEFT JOIN
NOT IN


YOUR ANSWER:

SELECT E.EMP_ID,
       E.EMP_NAME
FROM EMPLOYEE E
WHERE NOT EXISTS
(
    SELECT 1
    FROM ATTENDANCE A
    WHERE A.EMP_ID = E.EMP_ID
);


RESULT:
✓ CORRECT


CORRECT ANSWER:

SELECT E.EMP_ID,
       E.EMP_NAME
FROM EMPLOYEE E
WHERE NOT EXISTS
(
    SELECT 1
    FROM ATTENDANCE A
    WHERE A.EMP_ID = E.EMP_ID
);


EXPLANATION:

The subquery checks whether attendance exists
for each employee.

NOT EXISTS returns the employee only when
no matching attendance record exists.

Correct correlated subquery.


==================================================
PATTERN 4 — MINUS
--------------------------------------------------

QUESTION:

Find employees who exist in EMPLOYEE but have
never appeared in ATTENDANCE.

Return:

EMP_ID

Requirement:
For Oracle, use MINUS.

Do not use:
NOT EXISTS
LEFT JOIN


YOUR ANSWER:

SELECT EMP_ID
FROM EMPLOYEE
MINUS
SELECT EMP_ID
FROM ATTENDANCE;


RESULT:
✓ CORRECT


CORRECT ANSWER:

SELECT EMP_ID
FROM EMPLOYEE
MINUS
SELECT EMP_ID
FROM ATTENDANCE;


EXPLANATION:

MINUS returns rows from the first query that
do not exist in the second query.

Correct set-difference solution.


==================================================
PATTERN 5 — GROUP BY + HAVING
--------------------------------------------------

QUESTION:

For September 2026, find employees who:

1. Had at least one PRESENT day.
2. Had zero ABSENT days.

Return:

EMP_ID

Requirement:
Use GROUP BY + HAVING.

Do not use:
Window functions
CTE
NOT EXISTS


YOUR ANSWER:

SELECT EMP_ID
FROM ATTENDANCE
WHERE TO_CHAR(ATT_DATE,'MON-RRRR') = 'SEP-2026'
GROUP BY EMP_ID, STATUS
HAVING COUNT(STATUS) = 1
AND (STATUS = 'PRESENT' OR STATUS <> 'ABSENT');


RESULT:
✗ INCORRECT


MAIN PROBLEM:

You used:

GROUP BY EMP_ID, STATUS


But the question asks us to evaluate
the attendance of EACH EMPLOYEE as a whole.

Therefore the required grain is:

ONE GROUP = ONE EMPLOYEE


You need:

GROUP BY EMP_ID


not:

GROUP BY EMP_ID, STATUS


WHY YOUR APPROACH FAILS:

Suppose employee 101 has:

101 PRESENT
101 PRESENT
101 ABSENT

Your GROUP BY creates separate groups:

101 PRESENT
101 ABSENT

But we need one group:

101
   ↓
PRESENT = 2
ABSENT  = 1

Then we can determine whether employee 101
qualifies.


SECOND PROBLEM:

You wrote:

HAVING COUNT(STATUS) = 1


But the requirement is:

PRESENT >= 1
AND
ABSENT = 0


These are two separate conditions.


CORRECT ANSWER:

SELECT EMP_ID
FROM ATTENDANCE
WHERE ATT_DATE >= DATE '2026-09-01'
  AND ATT_DATE < DATE '2026-10-01'
GROUP BY EMP_ID
HAVING SUM(
           CASE
               WHEN STATUS = 'PRESENT' THEN 1
               ELSE 0
           END
       ) >= 1
   AND SUM(
           CASE
               WHEN STATUS = 'ABSENT' THEN 1
               ELSE 0
           END
       ) = 0;


EXPLANATION:

First filter September:

WHERE ATT_DATE >= DATE '2026-09-01'
  AND ATT_DATE < DATE '2026-10-01'


Then create one group per employee:

GROUP BY EMP_ID


Then calculate PRESENT count:

SUM(CASE WHEN STATUS = 'PRESENT'
         THEN 1 ELSE 0 END)


And ABSENT count:

SUM(CASE WHEN STATUS = 'ABSENT'
         THEN 1 ELSE 0 END)


Finally:

PRESENT >= 1
AND
ABSENT = 0


==================================================
IMPORTANT LESSON — QUERY GRAIN
==================================================

Before writing GROUP BY, ask:

"WHAT SHOULD ONE ROW/GROUP REPRESENT?"


If the requirement is:

Find employees...

and we need to evaluate ALL records
belonging to each employee:

GROUP BY EMP_ID


If the requirement is:

Find employee + status combinations:

GROUP BY EMP_ID, STATUS


Do not add columns to GROUP BY without
understanding how that changes the groups.


==================================================
DAY 8 — FINAL RESULT
==================================================

TOTAL QUERIES:
5

CORRECT:
4

PARTIALLY CORRECT:
0

WRONG:
1

FULLY CORRECT:
4 / 5 = 80%

PARTIALLY CORRECT:
0 / 5 = 0%

WRONG:
1 / 5 = 20%

EFFECTIVE ACCURACY:
80%


==================================================
DAY 8 MISTAKE
==================================================

MAIN WEAKNESS:

GROUP BY GRAIN


I understood GROUP BY + HAVING,
but grouped at the wrong level.

I need to ask:

"WHAT DOES ONE GROUP REPRESENT?"


==================================================
WEEK 2 PROGRESS
==================================================

DAY 8 COMPLETED

DAY 8 QUERIES:
5

DAY 8 CORRECT:
4

DAY 8 PARTIAL:
0

DAY 8 WRONG:
1

DAY 8 ACCURACY:
80%


TOTAL QUERIES SO FAR:
40


==================================================
END OF DAY 8
==================================================
