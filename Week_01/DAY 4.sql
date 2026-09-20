==================================================
NON-NEGOTIABLE TASK 4 — SQL/PLSQL
QUESTION + ANSWER CHECK
==================================================


PATTERN 1 — NULL HANDLING WITH NVL()
--------------------------------------------------

QUESTION:
Find each employees total compensation:

SALARY + BONUS

If BONUS is NULL, treat it as 0.

Use Oracle NVL().


YOUR ANSWER:

SELECT EMP_ID,
       EMP_NAME,
       SALARY,
       BONUS,
       (NVL(SALARY,0) + NVL(BONUS,0)) AS TOTAL_COMPENSATION
FROM EMPLOYEE;


RESULT:
✓ CORRECT


KEY CONCEPT:

NVL(BONUS, 0)

means:

If BONUS is NULL → use 0
Otherwise → use BONUS


NOTE:
The requirement only said BONUS can be NULL, so
technically this is enough:

SALARY + NVL(BONUS, 0)

Your use of NVL on SALARY is harmless and makes
the calculation NULL-safe if SALARY is also NULL.


==================================================
PATTERN 2 — DYNAMIC DATE FILTERING
--------------------------------------------------

QUESTION:
Find attendance records for the current month.

Do not hard-code the month.

Use Oracle date functions.


YOUR ANSWER:

SELECT EMP_ID,
       ATT_DATE,
       IN_TIME,
       OUT_TIME
FROM ATTENDANCE
WHERE TO_CHAR(ATT_DATE,'MM') = TO_CHAR(SYSDATE,'MM');


RESULT:
✗ INCORRECT


PROBLEM:

You only compared the MONTH:

TO_CHAR(ATT_DATE,'MM')


This means:

September 2025
September 2026
September 2027

would ALL match if the current month is September.


You need to compare the complete month/year period.


CORRECT ANSWER:

SELECT EMP_ID,
       ATT_DATE,
       IN_TIME,
       OUT_TIME
FROM ATTENDANCE
WHERE ATT_DATE >= TRUNC(SYSDATE, 'MM')
  AND ATT_DATE <  ADD_MONTHS(TRUNC(SYSDATE, 'MM'), 1);


KEY CONCEPT:

TRUNC(SYSDATE, 'MM')
        ↓
First day of current month


ADD_MONTHS(TRUNC(SYSDATE, 'MM'), 1)
        ↓
First day of next month


Therefore:

ATT_DATE >= first day of month
AND
ATT_DATE < first day of next month


This also works correctly when ATT_DATE contains
a TIME component.


IMPORTANT OFFICE/INTERVIEW POINT:

Avoid this when filtering dates:

TO_CHAR(ATT_DATE, 'MM') = ...


It converts the DATE to text and can prevent Oracle
from efficiently using an index on ATT_DATE.

Prefer date-to-date comparisons.


==================================================
PATTERN 3 — LEFT JOIN + NULL
--------------------------------------------------

QUESTION:
Find employees who do not have a valid department.

That means:

- DEPT_ID is NULL
OR
- DEPT_ID has no matching department.


YOUR ANSWER:

SELECT E.EMP_ID,
       E.EMP_NAME,
       E.DEPT_ID
FROM EMPLOYEE E
LEFT JOIN DEPARTMENT D
    ON E.DEPT_ID = D.DEPT_ID
WHERE E.DEPT_ID IS NULL;


RESULT:
✗ INCORRECT


PROBLEM:

You only handled:

E.DEPT_ID IS NULL


But you also need to find employees whose DEPT_ID
has a value but DOES NOT exist in DEPARTMENT.


Example:

EMPLOYEE:

EMP_ID   DEPT_ID
101      10
102      20
103      NULL
104      99


DEPARTMENT:

DEPT_ID
10
20


Employee 103 → NULL department
Employee 104 → Invalid department


Your query finds 103 but misses 104.


CORRECT ANSWER:

SELECT E.EMP_ID,
       E.EMP_NAME,
       E.DEPT_ID
FROM EMPLOYEE E
LEFT JOIN DEPARTMENT D
    ON E.DEPT_ID = D.DEPT_ID
WHERE D.DEPT_ID IS NULL;


WHY?

After LEFT JOIN:

Valid department:
E.DEPT_ID → D.DEPT_ID exists

Invalid department:
E.DEPT_ID → D.DEPT_ID becomes NULL

NULL employee department:
E.DEPT_ID is NULL → no match → D.DEPT_ID becomes NULL


Therefore:

WHERE D.DEPT_ID IS NULL

captures BOTH cases.


KEY CONCEPT:

LEFT JOIN
+
RIGHT TABLE IS NULL
=
Find records with no matching record.


==================================================
PATTERN 4 — CONDITIONAL AGGREGATION
--------------------------------------------------

QUESTION:
For each employee calculate:

PRESENT_DAYS
ABSENT_DAYS
HALF_DAYS

Use:

SUM(CASE WHEN ...)


YOUR ANSWER:

SELECT EMP_ID,
       SUM(CASE WHEN STATUS = 'PRESENT'
                THEN 1 ELSE 0 END) AS PRESENT_DAYS,
       SUM(CASE WHEN STATUS = 'ABSENT'
                THEN 1 ELSE 0 END) AS ABSENT_DAYS,
       SUM(CASE WHEN STATUS = 'HALF DAY'
                THEN 1 ELSE 0 END) AS HALF_DAYS
FROM ATTENDANCE;


RESULT:
⚠ ALMOST CORRECT


PROBLEM:

You forgot:

GROUP BY EMP_ID


Without GROUP BY, you cannot return EMP_ID together
with these aggregate calculations.


CORRECT ANSWER:

SELECT EMP_ID,
       SUM(CASE WHEN STATUS = 'PRESENT'
                THEN 1 ELSE 0 END) AS PRESENT_DAYS,
       SUM(CASE WHEN STATUS = 'ABSENT'
                THEN 1 ELSE 0 END) AS ABSENT_DAYS,
       SUM(CASE WHEN STATUS = 'HALF DAY'
                THEN 1 ELSE 0 END) AS HALF_DAYS
FROM ATTENDANCE
GROUP BY EMP_ID;


KEY CONCEPT:

GROUP BY EMP_ID
        ↓
One result per employee

SUM(CASE WHEN...)
        ↓
Count only rows matching that condition


This is one of the most useful SQL reporting patterns.


==================================================
PATTERN 5 — DUPLICATE RECORDS + ROW_NUMBER()
--------------------------------------------------

QUESTION:
For each VENDOR_ID + BANK_AC_NO:

Keep the latest record.

Return only the older duplicate records.

Use ROW_NUMBER().


YOUR ANSWER:

SELECT ID,
       VENDOR_ID,
       BANK_AC_NO,
       CREATED_DATE
FROM
(
    SELECT ID,
           VENDOR_ID,
           BANK_AC_NO,
           CREATED_DATE,
           ROW_NUMBER() OVER(
               PARTITION BY VENDOR_ID, BANK_AC_NO
               ORDER BY CREATED_DATE
           ) AS RNK
           VENDOR_BANK_DETAIL
) A
WHERE A.RNK > 1;


RESULT:
✗ INCORRECT


PROBLEMS:

1. Missing FROM:

You wrote:

VENDOR_BANK_DETAIL

but it needs:

FROM VENDOR_BANK_DETAIL


2. More importantly, the ORDER BY is wrong.

You wrote:

ORDER BY CREATED_DATE


That makes the OLDEST record:

RNK = 1

and the latest record gets a larger number.


But the requirement says:

Keep the LATEST record
Identify OLDER duplicates.


Therefore, latest must be RNK = 1.


CORRECT ANSWER:

SELECT ID,
       VENDOR_ID,
       BANK_AC_NO,
       CREATED_DATE
FROM
(
    SELECT ID,
           VENDOR_ID,
           BANK_AC_NO,
           CREATED_DATE,
           ROW_NUMBER() OVER(
               PARTITION BY VENDOR_ID, BANK_AC_NO
               ORDER BY CREATED_DATE DESC
           ) AS RNK
    FROM VENDOR_BANK_DETAIL
) A
WHERE A.RNK > 1;


Example:

ID   DATE         RNK
1    01-01-2026   3
2    10-02-2026   2
3    15-03-2026   1


RNK = 1
→ Latest record → KEEP


RNK > 1
→ Older records → DUPLICATES


KEY CONCEPT:

ROW_NUMBER() + DESC
        ↓
Latest record = 1

ROW_NUMBER() + ASC
        ↓
Oldest record = 1


==================================================
TASK 4 RESULT
==================================================

Pattern 1 — NVL()                  ✓ CORRECT
Pattern 2 — Date Filtering         ✗ INCORRECT
Pattern 3 — LEFT JOIN + NULL       ✗ INCORRECT
Pattern 4 — Conditional Aggregate  ⚠ ALMOST
Pattern 5 — Deduplication          ✗ INCORRECT


SCORE: 26 / 50
PERCENTAGE: 52%


==================================================
DAY-BY-DAY TRACKING
==================================================

DAY 1 → 68%
DAY 2 → 80%
DAY 3 → 80%
DAY 4 → 52%


CURRENT AVERAGE → 70%


==================================================
DAY 4 KEY LESSONS
==================================================

1. DATE FILTERING

Dont think only about the month number.

Think:

START OF MONTH
        ↓
        <
START OF NEXT MONTH


2. LEFT JOIN

When looking for missing matches:

LEFT JOIN
    ↓
WHERE RIGHT_TABLE.PRIMARY_KEY IS NULL


3. CONDITIONAL AGGREGATION

SUM(CASE WHEN ...)
        +
GROUP BY


4. ROW_NUMBER DEDUPLICATION

Latest = ROW_NUMBER() 1

Therefore:

ORDER BY DATE DESC


==================================================
DAY 4 — COMPLETED
==================================================
