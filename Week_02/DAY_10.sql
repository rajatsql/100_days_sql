============================================================
DAY 10 — SQL CHALLENGE REVIEW
============================================================

DATE: 16-09-2026

TOTAL QUESTIONS: 5
CORRECT: 3
PARTIALLY CORRECT: 2
WRONG: 0

DAY 10 ACCURACY: 60%

============================================================
PATTERN 1 — NOT EXISTS + DATE FILTER
============================================================

QUESTION:

Find employees who had no ABSENT attendance record during
September 2026.

Tables:

EMPLOYEE
--------
EMP_ID
EMP_NAME
DEPT_ID

ATTENDANCE
----------
EMP_ID
ATT_DATE
STATUS

Requirement:
Use NOT EXISTS.

------------------------------------------------------------
MY ANSWER:
------------------------------------------------------------

SELECT E.EMP_ID,E.EMP_NAME FROM EMPLOYEE E
WHERE NOT EXISTS (SELECT 1 FROM ATTENDANCE A
WHERE TO_CHAR(ATT_DATE,'MON-RRRR') ='SEP-2026'
AND STATUS = 'ABSENT'
AND A.EMP_ID = E.EMP_ID);

------------------------------------------------------------
RESULT:
------------------------------------------------------------

CORRECT

------------------------------------------------------------
EXPLANATION:
------------------------------------------------------------

The query correctly checks whether an ABSENT attendance
record exists for each employee during September 2026.

The correlation condition:

A.EMP_ID = E.EMP_ID

correctly connects the subquery to the current employee.

If an ABSENT record exists → employee is excluded.

If no ABSENT record exists → employee is returned.

------------------------------------------------------------
CORRECT ANSWER:
------------------------------------------------------------

SELECT E.EMP_ID,
       E.EMP_NAME
FROM EMPLOYEE E
WHERE NOT EXISTS
(
    SELECT 1
    FROM ATTENDANCE A
    WHERE A.EMP_ID = E.EMP_ID
      AND A.STATUS = 'ABSENT'
      AND TO_CHAR(A.ATT_DATE,'MON-RRRR') = 'SEP-2026'
);

------------------------------------------------------------
LESSON:
------------------------------------------------------------

NOT EXISTS is useful when the requirement is:

"Return the records for which a matching record does NOT exist."

============================================================


PATTERN 2 — NOT EXISTS + RELATED TABLE
============================================================

QUESTION:

Find employees who do not belong to an ACTIVE department.

This includes:

1. DEPT_ID is NULL
2. Department does not exist
3. Department exists but is INACTIVE

Requirement:
Use NOT EXISTS.

------------------------------------------------------------
MY ANSWER:
------------------------------------------------------------

SELECT E.EMP_ID,E.EMP_NAME,E.DEPT_ID FROM EMPLOYEE E
WHERE NOT EXISTS
(SELECT 1 FROM DEPARTMENT D
WHERE D.STATUS = 'ACTIVE'
AND D.DEPT_ID = E.DEPT_ID);

------------------------------------------------------------
RESULT:
------------------------------------------------------------

CORRECT

------------------------------------------------------------
EXPLANATION:
------------------------------------------------------------

The query asks:

"Does an ACTIVE department matching this employee exist?"

If yes → NOT EXISTS is false → employee excluded.

If no → NOT EXISTS is true → employee returned.

This correctly handles NULL DEPT_ID, missing departments,
and INACTIVE departments.

------------------------------------------------------------
CORRECT ANSWER:
------------------------------------------------------------

SELECT E.EMP_ID,
       E.EMP_NAME,
       E.DEPT_ID
FROM EMPLOYEE E
WHERE NOT EXISTS
(
    SELECT 1
    FROM DEPARTMENT D
    WHERE D.DEPT_ID = E.DEPT_ID
      AND D.STATUS = 'ACTIVE'
);

------------------------------------------------------------
LESSON:
------------------------------------------------------------

Think about NOT EXISTS as:

"For this current row, can I find a matching valid record?"

If I cannot find one → return the row.

============================================================


PATTERN 3 — CTE + AGGREGATION + LEFT JOIN
============================================================

QUESTION:

For September 2026, generate:

EMP_ID
EMP_NAME
PRESENT_DAYS
ABSENT_DAYS
TOTAL_ATTENDANCE

Employees with no September attendance must still appear
with all values as 0.

Requirement:

CTE
GROUP BY
LEFT JOIN
NVL()

------------------------------------------------------------
MY ANSWER:
------------------------------------------------------------

WITH CTE AS
(SELECT EMP_ID,
SUM(CASE WHEN STATUS = 'PRESENT' TEHN 1 ELSE 0 END) AS PRESENT_DAYS,
SUM(CASE WHEN STATUS = 'ABSENT' TEHN 1 ELSE 0 END) AS ABSENT_DAYS,
COUNT(*) AS TOTAL_ATTENDANCE
FROM ATTENDANCE A
WHERE TO_CHAR(ATT_DATE,'MON-RRRR') ='SEP-2026'
GROUP BY EMP_ID)

SELECT E.EMP_ID,E.EMP_NAME
NVL(C.PRESENT_DAYS,0),
NVL(C.ABSENT_DAYS,0),
NVL(C.TOTAL_ATTENDANCE,0)
FROM EMPLOYEE E
LEFT JOIN CTE C
ON E.EMP_ID = C.EMP_ID;

------------------------------------------------------------
RESULT:
------------------------------------------------------------

PARTIALLY CORRECT

------------------------------------------------------------
WHAT WAS CORRECT:
------------------------------------------------------------

The overall design was correct:

ATTENDANCE
    ↓
September filter
    ↓
GROUP BY EMP_ID
    ↓
CTE
    ↓
LEFT JOIN EMPLOYEE
    ↓
NVL()

You also correctly used aggregation before joining.

------------------------------------------------------------
MISTAKES:
------------------------------------------------------------

1. "TEHN" should be "THEN".

2. Missing comma after E.EMP_NAME.

3. Calculated columns should preferably have aliases.

------------------------------------------------------------
WHY I MADE THIS MISTAKE:
------------------------------------------------------------

The main SQL logic was understood.

The problem was final SQL construction.

I moved from the logical design to the final query without
performing a syntax check.

KEY THINKING ISSUE:

I need to separate:

LOGICAL CORRECTNESS
from
SQL SYNTAX VALIDATION

------------------------------------------------------------
KEY PATTERN:
------------------------------------------------------------

Before submitting a query, check:

1. SELECT columns separated by commas
2. CASE WHEN ... THEN ... ELSE ... END
3. FROM
4. JOIN condition
5. GROUP BY
6. Parentheses
7. Aliases

------------------------------------------------------------
CORRECT ANSWER:
------------------------------------------------------------

WITH CTE AS
(
    SELECT EMP_ID,
           SUM(CASE WHEN STATUS = 'PRESENT' THEN 1 ELSE 0 END)
               AS PRESENT_DAYS,
           SUM(CASE WHEN STATUS = 'ABSENT' THEN 1 ELSE 0 END)
               AS ABSENT_DAYS,
           COUNT(*) AS TOTAL_ATTENDANCE
    FROM ATTENDANCE
    WHERE TO_CHAR(ATT_DATE,'MON-RRRR') = 'SEP-2026'
    GROUP BY EMP_ID
)
SELECT E.EMP_ID,
       E.EMP_NAME,
       NVL(C.PRESENT_DAYS,0) AS PRESENT_DAYS,
       NVL(C.ABSENT_DAYS,0) AS ABSENT_DAYS,
       NVL(C.TOTAL_ATTENDANCE,0) AS TOTAL_ATTENDANCE
FROM EMPLOYEE E
LEFT JOIN CTE C
    ON E.EMP_ID = C.EMP_ID;

------------------------------------------------------------
LESSON:
------------------------------------------------------------

Aggregation BEFORE JOIN prevents raw attendance rows from
unnecessarily multiplying employee rows.

Also remember:

LEFT JOIN keeps employees who have no matching attendance.

NVL converts NULL aggregate values into 0.

------------------------------------------------------------
REWRITE PRACTICE:
------------------------------------------------------------

REWRITE THIS QUERY YOURSELF WITHOUT LOOKING AT THE
CORRECT ANSWER.

STATUS:
PENDING REWRITE

============================================================


PATTERN 4 — LATEST ACTIVE BANK ACCOUNT
============================================================

QUESTION:

Find the latest ACTIVE bank account for every vendor.

Requirement:

Use ROW_NUMBER().

Ignore INACTIVE records.

------------------------------------------------------------
MY ANSWER:
------------------------------------------------------------

SELECT VENDOR_ID,BANK_AC_NO,CREATED_DATE
FROM
(
SELECT VENDOR_ID,
BANK_AC_NO,
CREATED_DATE,
ROW_NUMBER() OVER
(PARTITION BY VENDOR_ID ORDER BY CREATED_DATE DESC) AS RN
FROM VENDOR_BANK_DETAIL
WHERE STATUS = 'ACTIVE'
)
WHERE RN =1;

------------------------------------------------------------
RESULT:
------------------------------------------------------------

CORRECT

------------------------------------------------------------
EXPLANATION:
------------------------------------------------------------

The query correctly filters ACTIVE records before applying
ROW_NUMBER().

Then it partitions by vendor and sorts the newest record
first.

RN = 1 returns the latest ACTIVE record.

------------------------------------------------------------
CORRECT ANSWER:
------------------------------------------------------------

SELECT VENDOR_ID,
       BANK_AC_NO,
       CREATED_DATE
FROM
(
    SELECT VENDOR_ID,
           BANK_AC_NO,
           CREATED_DATE,
           ROW_NUMBER() OVER
           (
               PARTITION BY VENDOR_ID
               ORDER BY CREATED_DATE DESC
           ) AS RN
    FROM VENDOR_BANK_DETAIL
    WHERE STATUS = 'ACTIVE'
)
WHERE RN = 1;

------------------------------------------------------------
LESSON:
------------------------------------------------------------

Important order:

FILTER VALID RECORDS
        ↓
ROW_NUMBER()
        ↓
SELECT LATEST

Do not rank unwanted records first.

============================================================


PATTERN 5 — DEPARTMENT QUALIFICATION
============================================================

QUESTION:

Find departments where:

1. At least 3 ACTIVE employees exist.
2. Every ACTIVE employee earns more than 30,000.

Return:

DEPT_ID
ACTIVE_EMP_COUNT
MIN_ACTIVE_SALARY

Requirement:

WHERE
GROUP BY
HAVING

------------------------------------------------------------
MY ANSWER:
------------------------------------------------------------

SELECT E.DEPT_ID,
COUNT(*) AS ACTIVE_EMP_COUNT
MIN(E.SALARY) AS MIN_ACTIVE_SALARY
FROM EMPLOYEE E
WHERE STATUS = 'ACTIVE'
HAVING COUNT(*) >= 3
AND MIN(E.SALARY) > 30000;

------------------------------------------------------------
RESULT:
------------------------------------------------------------

PARTIALLY CORRECT

------------------------------------------------------------
WHAT WAS CORRECT:
------------------------------------------------------------

You correctly understood that:

WHERE STATUS = 'ACTIVE'

must happen before aggregation.

You also correctly identified:

MIN(SALARY) > 30000

as a way to express:

"Every ACTIVE employee earns more than 30,000."

You also correctly used:

COUNT(*) >= 3

in HAVING.

------------------------------------------------------------
MISTAKES:
------------------------------------------------------------

1. Missing comma after COUNT(*).

2. Missing GROUP BY DEPT_ID.

------------------------------------------------------------
WHY I MADE THIS MISTAKE:
------------------------------------------------------------

The important underlying mistake was QUERY GRAIN.

The question asks for:

ONE ROW = ONE DEPARTMENT

Therefore DEPT_ID must define the group:

GROUP BY DEPT_ID

I understood the aggregate conditions but did not explicitly
identify the output grain before completing the query.

------------------------------------------------------------
KEY PATTERN:
------------------------------------------------------------

Always ask:

"What does one output row represent?"

Here:

ONE ROW = ONE DEPARTMENT

Therefore:

GROUP BY DEPT_ID

Then calculate:

COUNT()
MIN()

Then filter groups using:

HAVING

------------------------------------------------------------
CORRECT ANSWER:
------------------------------------------------------------

SELECT E.DEPT_ID,
       COUNT(*) AS ACTIVE_EMP_COUNT,
       MIN(E.SALARY) AS MIN_ACTIVE_SALARY
FROM EMPLOYEE E
WHERE E.STATUS = 'ACTIVE'
GROUP BY E.DEPT_ID
HAVING COUNT(*) >= 3
   AND MIN(E.SALARY) > 30000;

------------------------------------------------------------
LESSON:
------------------------------------------------------------

Query construction order:

FROM
 ↓
WHERE
 ↓
GROUP BY
 ↓
HAVING
 ↓
SELECT result

For "EVERY employee satisfies condition X":

MIN(value) > X

can sometimes express the requirement.

------------------------------------------------------------
REWRITE PRACTICE:
------------------------------------------------------------

REWRITE THIS QUERY YOURSELF WITHOUT LOOKING AT THE
CORRECT ANSWER.

STATUS:
PENDING REWRITE

============================================================
DAY 10 FINAL REVIEW
============================================================

TOTAL QUESTIONS: 5

CORRECT: 3
PARTIALLY CORRECT: 2
WRONG: 0

ACCURACY: 60%

------------------------------------------------------------
STRONG AREAS
------------------------------------------------------------

1. NOT EXISTS
   Strength: Strong

2. Correlated subquery thinking
   Strength: Strong

3. Filtering before ROW_NUMBER()
   Strength: Strong

4. Understanding ACTIVE vs INACTIVE population
   Strength: Strong

------------------------------------------------------------
WEAK AREAS
------------------------------------------------------------

1. SQL syntax discipline
   Status: Needs improvement

2. Query grain
   Status: Needs improvement

3. Final validation before submitting SQL
   Status: Needs improvement

------------------------------------------------------------
MOST IMPORTANT MISTAKE TODAY
------------------------------------------------------------

QUERY GRAIN

Before writing GROUP BY, ask:

"What should one row represent?"

Then determine the GROUP BY columns.

------------------------------------------------------------
SECOND REPEATED ISSUE
------------------------------------------------------------

Syntax/detail errors:

- TEHN instead of THEN
- Missing comma
- Missing GROUP BY

These are avoidable errors.

------------------------------------------------------------
DAY 10 TAKEAWAY
------------------------------------------------------------

I understand the majority of todays SQL patterns.

My biggest problem is not understanding the SQL concept.

My biggest problem is sometimes failing to convert the
correct logical approach into complete executable SQL.

FOCUS FOR NEXT QUESTIONS:

1. Query grain
2. SQL construction discipline
3. Final syntax check
4. Continue NOT EXISTS and window-function patterns
5. Gradually combine patterns

============================================================
CHALLENGE PROGRESS
============================================================

DAYS COMPLETED: 10 / 100

TOTAL QUESTIONS COMPLETED: 50 / 500

DAY 10:
3 CORRECT
2 PARTIAL
0 WRONG

NEXT:
DAY 11

============================================================
END OF DAY 10
============================================================
