==================================================
DAY 9 — QUESTION + YOUR ANSWER + CORRECT ANSWER
==================================================


==================================================
PATTERN 1 — SCALAR SUBQUERY
--------------------------------------------------

QUESTION:

Find employees whose salary is greater than the
overall average salary of all employees.

Return:

EMP_ID
EMP_NAME
SALARY

Requirement:
Use a scalar subquery.

Do not use:
JOIN
Window functions
GROUP BY


YOUR ANSWER:

SELECT EMP_ID,
       EMP_NAME,
       SALARY
FROM EMPLOYEE
WHERE SALARY > (SELECT AVG(SALARY)
                FROM EMPLOYEE);


RESULT:
✓ CORRECT


CORRECT ANSWER:

SELECT EMP_ID,
       EMP_NAME,
       SALARY
FROM EMPLOYEE
WHERE SALARY > (SELECT AVG(SALARY)
                FROM EMPLOYEE);


EXPLANATION:

The inner query:

SELECT AVG(SALARY)
FROM EMPLOYEE

returns one value.

That makes it a scalar subquery.

The outer query compares every employees salary
against that single average value.

You also correctly avoided:
- JOIN
- GROUP BY
- Window functions


==================================================
PATTERN 2 — NOT EXISTS
--------------------------------------------------

QUESTION:

Find employees whose DEPT_ID does not exist in
the DEPARTMENT table.

Return:

EMP_ID
EMP_NAME
DEPT_ID

Requirement:
Use NOT EXISTS.

Do not use:
NOT IN
JOIN


YOUR ANSWER:

SELECT EMP_ID,
       EMP_NAME,
       DEPT_ID
FROM EMPLOYEE E
WHERE NOT EXISTS
(
    SELECT 1
    FROM DEPARTMENT D
    WHERE D.DEPT_ID = E.DEPT_ID
);


RESULT:
✓ CORRECT


CORRECT ANSWER:

SELECT EMP_ID,
       EMP_NAME,
       DEPT_ID
FROM EMPLOYEE E
WHERE NOT EXISTS
(
    SELECT 1
    FROM DEPARTMENT D
    WHERE D.DEPT_ID = E.DEPT_ID
);


EXPLANATION:

For each employee, the subquery checks whether
a matching department exists.

If no matching department exists,
NOT EXISTS becomes TRUE.

The correlation is:

D.DEPT_ID = E.DEPT_ID

Correct.

You also correctly followed the restriction:
NOT EXISTS instead of NOT IN.


==================================================
PATTERN 3 — CORRELATED SUBQUERY + MAX
--------------------------------------------------

QUESTION:

Find employees who have the highest salary in
their own department.

If two employees have the same highest salary,
return both.

Requirement:

Use a correlated subquery.

Do not use:
RANK()
DENSE_RANK()
ROW_NUMBER()
CTE


YOUR ANSWER:

SELECT E.EMP_ID,
       E.EMP_NAME,
       E.DEPT_ID,
       E.SALARY
FROM EMPLOYEE E
JOIN
(
    SELECT MAX(SALARY) AS MAX_SAL,
           DEPT_ID
    FROM EMPLOYEE
    GROUP BY DEPT_ID
) D
ON E.DEPT_ID = D.DEPT_ID
AND E.SALARY = D.MAX_SAL;


RESULT:
⚠ PARTIALLY CORRECT


WHY?

Your query can return the correct employees.

However, the question specifically required:

CORRELATED SUBQUERY

You used:

JOIN
+
GROUP BY
+
MAX()


So your LOGIC is correct, but your REQUIRED PATTERN
is wrong.

For this challenge, this is PARTIALLY CORRECT,
not fully correct.


CORRECT ANSWER:

SELECT E.EMP_ID,
       E.EMP_NAME,
       E.DEPT_ID,
       E.SALARY
FROM EMPLOYEE E
WHERE E.SALARY =
(
    SELECT MAX(E2.SALARY)
    FROM EMPLOYEE E2
    WHERE E2.DEPT_ID = E.DEPT_ID
);


EXPLANATION:

The outer query processes one employee at a time.

For that employee:

E.DEPT_ID

is passed into the correlated subquery.

The subquery finds:

MAX(E2.SALARY)

for that employees department.

Then:

E.SALARY = department maximum salary

determines whether the employee should be returned.


Example:

DEPT 10

100000
90000
90000
80000


For employee earning 100000:

MAX salary in DEPT 10 = 100000
100000 = 100000 → RETURN


For employee earning 90000:

MAX salary in DEPT 10 = 100000
90000 = 100000 → DONT RETURN


If two employees earn 100000,
both will be returned.

This satisfies the requirement.


IMPORTANT:

Your previous approach:

DEPT
 ↓
GROUP BY
 ↓
MAX
 ↓
JOIN

is also a valid real-world solution.

But when an interview question says:

"Use a correlated subquery"

you must demonstrate that specific technique.


==================================================
PATTERN 4 — CONDITIONAL AGGREGATION + HAVING
--------------------------------------------------

QUESTION:

For September 2026, find employees who have:

At least 20 PRESENT days

AND

No more than 2 ABSENT days.

Return:

EMP_ID
PRESENT_DAYS
ABSENT_DAYS

Requirement:

Use:
GROUP BY
HAVING
SUM(CASE WHEN...)

Do not use:
CTE
Window functions
NOT EXISTS


YOUR ANSWER:

SELECT EMP_ID,
       SUM(CASE
               WHEN STATUS = 'PRESENT'
               THEN 1
               ELSE 0
           END) AS PRESENT_DAYS,
       SUM(CASE
               WHEN STATUS = 'ABSENT'
               THEN 1
               ELSE 0
           END) AS ABSENT_DAYS
FROM ATTENDANCE
WHERE TO_CHAR(ATT_DATE,'MON-RRRR') = 'SEP-2026'
GROUP BY EMP_ID
HAVING SUM(CASE
               WHEN STATUS = 'PRESENT'
               THEN 1
               ELSE 0
           END) >= 20
   AND SUM(CASE
               WHEN STATUS = 'ABSENT'
               THEN 1
               ELSE 0
           END) <= 2;


RESULT:
✓ CORRECT


CORRECT ANSWER:

SELECT EMP_ID,
       SUM(CASE WHEN STATUS = 'PRESENT'
                THEN 1 ELSE 0 END) AS PRESENT_DAYS,
       SUM(CASE WHEN STATUS = 'ABSENT'
                THEN 1 ELSE 0 END) AS ABSENT_DAYS
FROM ATTENDANCE
WHERE TO_CHAR(ATT_DATE,'MON-RRRR') = 'SEP-2026'
GROUP BY EMP_ID
HAVING SUM(CASE WHEN STATUS = 'PRESENT'
                THEN 1 ELSE 0 END) >= 20
   AND SUM(CASE WHEN STATUS = 'ABSENT'
                THEN 1 ELSE 0 END) <= 2;


EXPLANATION:

You correctly separated:

WHERE
→ filters September records.

GROUP BY
→ creates one group per employee.

SUM(CASE...)
→ calculates PRESENT and ABSENT counts.

HAVING
→ filters the aggregated results.

This is exactly the required execution logic.


==================================================
PATTERN 5 — LATEST ACTIVE SALARY + LEFT JOIN
--------------------------------------------------

QUESTION:

Find the latest ACTIVE salary record for every
employee.

Rules:

- Ignore INACTIVE records.
- Return only the latest ACTIVE record.
- Every employee must appear.
- Employees without an ACTIVE salary must still
  appear with NULL salary/date.

Requirement:

Use:
ROW_NUMBER()
LEFT JOIN


YOUR ANSWER:

WITH CTE AS
(
    SELECT EMP_ID,
           SALARY,
           EFFECTIVE_DATE,
           STATUS
    FROM
    (
        SELECT EMP_ID,
               SALARY,
               EFFECTIVE_DATE,
               STATUS,
               ROW_NUMBER() OVER
               (
                   PARTITION BY EMP_ID
                   ORDER BY EFFECTIVE_DATE DESC
               ) AS RNK
        FROM EMPLOYEE_SALARY
        WHERE STATUS = 'ACTIVE'
    )
    WHERE RNK = 1
)
SELECT E.EMP_ID,
       E.EMP_NAME,
       C.SALARY,
       C.EFFECTIVE_DATE
FROM EMPLOYEE E
LEFT JOIN CTE C
ON E.EMP_ID = C.EMP_ID;


RESULT:
✓ CORRECT


CORRECT ANSWER:

WITH CTE AS
(
    SELECT EMP_ID,
           SALARY,
           EFFECTIVE_DATE,
           STATUS
    FROM
    (
        SELECT EMP_ID,
               SALARY,
               EFFECTIVE_DATE,
               STATUS,
               ROW_NUMBER() OVER
               (
                   PARTITION BY EMP_ID
                   ORDER BY EFFECTIVE_DATE DESC
               ) AS RNK
        FROM EMPLOYEE_SALARY
        WHERE STATUS = 'ACTIVE'
    )
    WHERE RNK = 1
)
SELECT E.EMP_ID,
       E.EMP_NAME,
       C.SALARY,
       C.EFFECTIVE_DATE
FROM EMPLOYEE E
LEFT JOIN CTE C
ON E.EMP_ID = C.EMP_ID;


EXPLANATION:

Your execution order is correct:

EMPLOYEE_SALARY
        ↓
WHERE STATUS = 'ACTIVE'
        ↓
ROW_NUMBER()
        ↓
RNK = 1
        ↓
LEFT JOIN
        ↓
EMPLOYEE


Most importantly, you filtered ACTIVE records
BEFORE applying ROW_NUMBER().

Therefore an INACTIVE record cannot become
the latest record.

You also used LEFT JOIN, so employees without
an ACTIVE salary record remain in the result.


==================================================
DAY 9 — FINAL RESULT
==================================================

TOTAL QUERIES:
5

FULLY CORRECT:
4 / 5

PARTIALLY CORRECT:
1 / 5

WRONG:
0 / 5


FULLY CORRECT:
80%

PARTIALLY CORRECT:
20%

WRONG:
0%


EFFECTIVE ACCURACY:

4 + (1 × 0.5)
= 4.5

4.5 / 5 × 100
= 90%


==================================================
DAY 9 MAIN MISTAKE
==================================================

PATTERN 3

I solved the business problem correctly,
but did NOT follow the required SQL pattern.

Question required:

CORRELATED SUBQUERY

I wrote:

JOIN + GROUP BY + MAX


LESSON:

When an interview question gives a specific
restriction, solving the problem another way
is not fully correct.

I need to satisfy BOTH:

1. Correct result
2. Required technique


==================================================
DAY 9 STRENGTHS
==================================================

✓ Scalar subquery
✓ NOT EXISTS
✓ Conditional aggregation
✓ HAVING
✓ ROW_NUMBER()
✓ LEFT JOIN
✓ Filtering before ROW_NUMBER()
✓ Correct query execution order


==================================================
DAY 9 AREA TO IMPROVE
==================================================

CORRELATED SUBQUERY

I understand how to solve the problem using
JOIN + aggregation, but I need to become
comfortable expressing the same logic using
a correlated subquery.


==================================================
CUMULATIVE SQL CHALLENGE
==================================================

DAYS COMPLETED:
9 / 100

TOTAL QUERIES WRITTEN:
45 / 500

DAY 9:
4 Correct
1 Partial
0 Wrong

DAY 9 FULL ACCURACY:
80%

DAY 9 EFFECTIVE ACCURACY:
90%


==================================================
END OF DAY 9
==================================================