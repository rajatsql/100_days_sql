==================================================
SQL CHALLENGE — DAY 15
YOUR ANSWER + CORRECT ANSWER
==================================================


==================================================
Q1 — ACTIVE CUSTOMERS + SEPTEMBER ORDERS + CONDITIONAL AGGREGATION
==================================================

RESULT:
🟡 PARTIALLY CORRECT


YOUR ANSWER:
--------------------------------------------------

WITH CTE AS 
(SELECT CUSTOMER_ID , COUNT(*) AS TOTAL_ORDERS ,
SUM(CASE WHEN ORDER_STATUS = 'COMPLETE' THEN 1 ELSE 0 END) AS COMPLETED_ORDERS,
SUM(CASE WHEN ORDER_STATUS = 'COMPLETE' THEN AMOUNT ELSE 0 END) AS COMPLETED_AMOUNT
TRUNC(ORDER_DATE) >= TO_DATE('01-SEP-2026','DD-MON-RRRR') AND
TRUNC(ORDER_DATE) =< TO_DATE('30-SEP-2026','DD-MON-RRRR')
GROUP BY CUSTOMER_ID)

SELECT C.CUSTOMER_ID,
C.CUSTOMER_NAME
NVL(CT.TOTAL_ORDERS,0),
NVL(CT.COMPLETED_ORDERS,0),
NVL(CT.COMPLETED_AMOUNT,0) 
FROM CUSTOMER C LEFT JOIN CTE CT
ON C.CUSTOMER_ID = CT.CUSTOMER_ID
AND C.STATUS = 'ACTIVE';


CORRECT ANSWER:
--------------------------------------------------

WITH CTE AS
(
    SELECT CUSTOMER_ID,
           COUNT(*) AS TOTAL_ORDERS,
           SUM(
               CASE
                   WHEN ORDER_STATUS = 'COMPLETED'
                   THEN 1
                   ELSE 0
               END
           ) AS COMPLETED_ORDERS,
           SUM(
               CASE
                   WHEN ORDER_STATUS = 'COMPLETED'
                   THEN AMOUNT
                   ELSE 0
               END
           ) AS COMPLETED_AMOUNT
    FROM ORDERS
    WHERE ORDER_DATE >= DATE '2026-09-01'
      AND ORDER_DATE < DATE '2026-10-01'
    GROUP BY CUSTOMER_ID
)
SELECT C.CUSTOMER_ID,
       C.CUSTOMER_NAME,
       NVL(CT.TOTAL_ORDERS, 0) AS TOTAL_ORDERS,
       NVL(CT.COMPLETED_ORDERS, 0) AS COMPLETED_ORDERS,
       NVL(CT.COMPLETED_AMOUNT, 0) AS COMPLETED_AMOUNT
FROM CUSTOMER C
LEFT JOIN CTE CT
    ON C.CUSTOMER_ID = CT.CUSTOMER_ID
WHERE C.STATUS = 'ACTIVE';


EXPLANATION:
--------------------------------------------------

Your overall architecture is correct:

ORDERS
→ aggregate by CUSTOMER_ID
→ conditional aggregation
→ LEFT JOIN CUSTOMER
→ NVL missing values to 0

The main implementation problems are syntax and date filtering.

1. Missing FROM ORDERS

Your CTE starts the SELECT but never specifies:

FROM ORDERS

2. Missing WHERE before the date condition

You wrote the date condition directly after the SELECT expressions.

It needs:

FROM ORDERS
WHERE ORDER_DATE >= ...


3. Invalid operator:

You used:

=<

Correct:

<=


4. September date filtering

You attempted:

TRUNC(ORDER_DATE) >= 01-SEP-2026
AND TRUNC(ORDER_DATE) <= 30-SEP-2026

A safer and cleaner range is:

ORDER_DATE >= DATE '2026-09-01'
AND ORDER_DATE < DATE '2026-10-01'


5. Missing comma after CUSTOMER_NAME

You wrote:

C.CUSTOMER_NAME
NVL(...)

It needs a comma.


WHY THIS MISTAKE HAPPENED:
--------------------------------------------------

You understood the business logic and JOIN structure, but SQL syntax precision broke the query.

The main improvement needed is:

SELECT
→ FROM
→ WHERE
→ GROUP BY
→ HAVING

Keep this clause order fixed in your mind.


KEY PATTERN / LESSON:
--------------------------------------------------

For month filtering:

DATE >= first_day_of_month
AND DATE < first_day_of_next_month

For this problem:

2026-09-01 inclusive
→ 2026-10-01 exclusive

Also remember:

LEFT JOIN + master table
→ preserve customers

NVL(...)
→ convert missing aggregate values to 0



==================================================
Q2 — CUSTOMER ORDERS + PAYMENTS + PRE-AGGREGATION
==================================================

RESULT:
🟡 PARTIALLY CORRECT


YOUR ANSWER:
--------------------------------------------------

SELECT C.CUSTOMER_ID,C.CUSTOMER_NAME,
NVL(O.TOTAL_ORDER_AMOUNT,0),NVL(P.TOTAL_PAYMENT_AMOUNT,0) FROM CUSTOMER C LEFT JOIN 
(SELECT CUSTOMER_ID,SUM(AMOUNT) AS TOTAL_ORDER_AMOUNT FROM ORDERS GROUP BY CUSTOMER_ID) O
ON C.CUSTOMER_ID = O.CUSTOMER_ID LEFT JOIN
(SELECT CUSTOMER_ID,SUM(AMOUNT) AS TOTAL_PAYMENT_AMOUNT FROM PAYMENT GROUP BY CUSTOMER_ID) P
ON C.CUSTOMER_ID = O.CUSTOMER_ID;


CORRECT ANSWER:
--------------------------------------------------

SELECT C.CUSTOMER_ID,
       C.CUSTOMER_NAME,
       NVL(O.TOTAL_ORDER_AMOUNT, 0) AS TOTAL_ORDER_AMOUNT,
       NVL(P.TOTAL_PAYMENT_AMOUNT, 0) AS TOTAL_PAYMENT_AMOUNT
FROM CUSTOMER C
LEFT JOIN
(
    SELECT CUSTOMER_ID,
           SUM(AMOUNT) AS TOTAL_ORDER_AMOUNT
    FROM ORDERS
    GROUP BY CUSTOMER_ID
) O
    ON C.CUSTOMER_ID = O.CUSTOMER_ID
LEFT JOIN
(
    SELECT CUSTOMER_ID,
           SUM(AMOUNT) AS TOTAL_PAYMENT_AMOUNT
    FROM PAYMENT
    GROUP BY CUSTOMER_ID
) P
    ON C.CUSTOMER_ID = P.CUSTOMER_ID;


EXPLANATION:
--------------------------------------------------

Your main design is correct.

You correctly understood that ORDERS and PAYMENT are two independent one-to-many sources.

Therefore:

ORDERS
→ GROUP BY CUSTOMER_ID
→ one row per customer

PAYMENT
→ GROUP BY CUSTOMER_ID
→ one row per customer

Then join both summaries to CUSTOMER.

This prevents:

ORDERS × PAYMENT

row multiplication.

The problem is one JOIN condition.

You wrote:

ON C.CUSTOMER_ID = O.CUSTOMER_ID

for the second JOIN.

But the second table is P.

It must be:

ON C.CUSTOMER_ID = P.CUSTOMER_ID


WHY THIS MISTAKE HAPPENED:
--------------------------------------------------

You correctly created the PAYMENT summary but copied the previous JOIN condition and did not change the alias from O to P.

This is a classic alias-precision error.

At Lead level, always read each JOIN as:

LEFT JOIN <table_alias>
ON <driving_alias> = <joined_alias>


KEY PATTERN / LESSON:
--------------------------------------------------

Never directly join two independent one-to-many detail tables.

Correct:

CUSTOMER
→ ORDERS SUMMARY
→ PAYMENT SUMMARY

Not:

CUSTOMER
→ ORDERS
→ PAYMENT

because:

3 orders × 4 payments = 12 joined rows.



==================================================
Q3 — LATEST ACTIVE PRICE + ROW_NUMBER
==================================================

RESULT:
🟢 CORRECT


YOUR ANSWER:
--------------------------------------------------

SELECT PRODUCT_ID,PRICE,EFFECTIVE_DATE FROM
(SELECT PRODUCT_ID,PRICE,EFFECTIVE_DATE,
ROW_NUMBER() OVER(PARTITION BY PRODUCT_ID ORDER BY EFFECTIVE_DATE DESC) AS RN
FROM PRODUCT_PRICE WHERE STATUS = 'ACTIVE')
WHERE RN = 1;


CORRECT ANSWER:
--------------------------------------------------

SELECT PRODUCT_ID,
       PRICE,
       EFFECTIVE_DATE
FROM
(
    SELECT PRODUCT_ID,
           PRICE,
           EFFECTIVE_DATE,
           ROW_NUMBER() OVER
           (
               PARTITION BY PRODUCT_ID
               ORDER BY EFFECTIVE_DATE DESC
           ) AS RN
    FROM PRODUCT_PRICE
    WHERE STATUS = 'ACTIVE'
)
WHERE RN = 1;


EXPLANATION:
--------------------------------------------------

Your query is correct.

You correctly used:

WHERE STATUS = 'ACTIVE'

then:

ROW_NUMBER()
PARTITION BY PRODUCT_ID
ORDER BY EFFECTIVE_DATE DESC

then:

WHERE RN = 1

This produces the latest ACTIVE price for each product.


WHY THIS WORKS:
--------------------------------------------------

For every PRODUCT_ID:

Latest record
→ RN = 1

Second latest
→ RN = 2

Third latest
→ RN = 3

Therefore:

WHERE RN = 1

returns exactly the latest ACTIVE record.


KEY PATTERN / LESSON:
--------------------------------------------------

LATEST RECORD PER GROUP:

ROW_NUMBER() OVER
(
    PARTITION BY business_key
    ORDER BY date_column DESC
)

then:

WHERE RN = 1


This is a pattern you should be able to write without thinking.



==================================================
Q4 — STORE SALES + BUSINESS CONDITIONS
==================================================

RESULT:
🔴 WRONG


YOUR ANSWER:
--------------------------------------------------

SELECT S.STORE_ID,
S.STORE_NAME,
SC.TOTAL_SALES,
SC.COMPLETED_SALES,
SC.CANCELLED_SALES FROM STORE S LEFT JOIN
(SELECT STORE_ID , COUNT(*) AS TOTAL_SALES,
SUM(CASE WHEN STATUS = 'COMPLETE' THEN 1 ELSE 0 END) AS COMPLETED_SALES,
SUM(CASE WHEN STATUS = 'CANCEL' THEN 1 ELSE 0 END) AS CANCELLED_SALES
FROM SALES
SALE_DATE >=TO_DATE('01-SEP-2026' ,'DD-MON-RRRR') AND
SALE_DATE <= TO_DATE('01-SEP-2026' ,'DD-MON-RRRR') 
GROUP BY STORE_ID
HAVING SUM(AMOUNT) > 1000000
AND SUM(CASE WHEN STATUS = 'COMPLETE' THEN 1 ELSE 0 END) >= 100
AND SUM(CASE WHEN STATUS = 'CANCEL' THEN 1 ELSE 0 END) = 0)SC
ON S.STORE_ID = SC.STORE_ID;


CORRECT ANSWER:
--------------------------------------------------

SELECT S.STORE_ID,
       S.STORE_NAME,
       SC.TOTAL_SALES,
       SC.COMPLETED_SALES,
       SC.CANCELLED_SALES
FROM STORE S
JOIN
(
    SELECT STORE_ID,
           SUM(AMOUNT) AS TOTAL_SALES,
           SUM(
               CASE
                   WHEN STATUS = 'COMPLETED'
                   THEN 1
                   ELSE 0
               END
           ) AS COMPLETED_SALES,
           SUM(
               CASE
                   WHEN STATUS = 'CANCELLED'
                   THEN 1
                   ELSE 0
               END
           ) AS CANCELLED_SALES
    FROM SALES
    WHERE SALE_DATE >= DATE '2026-09-01'
      AND SALE_DATE < DATE '2026-10-01'
    GROUP BY STORE_ID
    HAVING SUM(AMOUNT) > 1000000
       AND SUM(
               CASE
                   WHEN STATUS = 'COMPLETED'
                   THEN 1
                   ELSE 0
               END
           ) >= 100
       AND SUM(
               CASE
                   WHEN STATUS = 'CANCELLED'
                   THEN 1
                   ELSE 0
               END
           ) = 0
) SC
    ON S.STORE_ID = SC.STORE_ID;


EXPLANATION:
--------------------------------------------------

There are multiple issues here.

1. Missing WHERE

You wrote:

FROM SALES
SALE_DATE >= ...

Correct:

FROM SALES
WHERE SALE_DATE >= ...


2. Incorrect September date range

You wrote:

SALE_DATE >= 01-SEP-2026
AND SALE_DATE <= 01-SEP-2026

That means only September 1.

Correct:

SALE_DATE >= DATE '2026-09-01'
AND SALE_DATE < DATE '2026-10-01'


3. TOTAL_SALES is the wrong calculation

The requirement says:

"total sales amount > 1,000,000"

You used:

COUNT(*) AS TOTAL_SALES

COUNT(*) = number of transactions.

The requirement needs:

SUM(AMOUNT) AS TOTAL_SALES


4. Status values do not match the requirement

Requirement:

COMPLETED
CANCELLED

You used:

COMPLETE
CANCEL

The business value must match the actual required status.


5. LEFT JOIN is unnecessary here

The requirement asks for stores satisfying the HAVING conditions.

Therefore the aggregated result already contains only qualifying stores.

An INNER JOIN is sufficient.


WHY THIS MISTAKE HAPPENED:
--------------------------------------------------

The main issue was translating business language into the correct SQL aggregate.

"Total sales amount"
→ SUM(AMOUNT)

"100 completed transactions"
→ COUNT completed transactions

"zero cancelled transactions"
→ COUNT cancelled transactions = 0

Do not let a column alias like TOTAL_SALES decide the operation.

Read the business requirement first.


KEY PATTERN / LESSON:
--------------------------------------------------

Business requirement:

TOTAL AMOUNT
→ SUM(AMOUNT)

NUMBER OF TRANSACTIONS
→ COUNT(*) or conditional SUM

ZERO TRANSACTIONS OF TYPE X
→ SUM(CASE WHEN ... THEN 1 ELSE 0 END) = 0

Month:
→ >= first day
→ < first day of next month



==================================================
Q5 — LATEST SALARY + DEPARTMENT AVERAGE
==================================================

RESULT:
🔴 WRONG


YOUR ANSWER:
--------------------------------------------------

SELECT E.EMP_ID,
E.EMP_NAME,
A.DEPT_ID,
A.LATEST_SALARY,
E.DEPT_AVG_LATEST_SALARY
 FROM
(SELECT ES.EMP_ID AS EMP_ID,ES.SALARY AS SALARY,E.DEPT_ID,E.EMP_NAME
ROW_NUMBER() OVER(PARTITION BY ES.EMP_ID ORDER BY ES.EFFECTIVE_DATE DESC) AS RN FROM EMPLOYEE E 
JOIN EMPLOYEE_SALARY ES
WHERE ES.EMP_ID = A.EMP_ID) A
JOIN (SELECT E.DEPT_ID, AVG(ES.SALARY) FROM EMPLOYEE E JOIN EMPLOYEE_SALARY ES
WHERE ES.EMP_ID = A.EMP_ID
GROUP BY E.DEPT_ID) E ON 
A.DEPT_ID = E.DEPT_ID
WHERE RN =1


CORRECT ANSWER:
--------------------------------------------------

WITH LATEST_SALARY AS
(
    SELECT EMP_ID,
           SALARY AS LATEST_SALARY,
           ROW_NUMBER() OVER
           (
               PARTITION BY EMP_ID
               ORDER BY EFFECTIVE_DATE DESC
           ) AS RN
    FROM EMPLOYEE_SALARY
),
EMP_LATEST AS
(
    SELECT E.EMP_ID,
           E.EMP_NAME,
           E.DEPT_ID,
           L.LATEST_SALARY
    FROM EMPLOYEE E
    JOIN LATEST_SALARY L
        ON E.EMP_ID = L.EMP_ID
    WHERE L.RN = 1
),
DEPT_AVG AS
(
    SELECT DEPT_ID,
           AVG(LATEST_SALARY) AS DEPT_AVG_LATEST_SALARY
    FROM EMP_LATEST
    GROUP BY DEPT_ID
)
SELECT E.EMP_ID,
       E.EMP_NAME,
       E.DEPT_ID,
       E.LATEST_SALARY,
       D.DEPT_AVG_LATEST_SALARY
FROM EMP_LATEST E
JOIN DEPT_AVG D
    ON E.DEPT_ID = D.DEPT_ID
WHERE E.LATEST_SALARY > D.DEPT_AVG_LATEST_SALARY;


EXPLANATION:
--------------------------------------------------

This question was testing query layering and business grain.

The required sequence is:

1. Find latest salary per employee.
2. Keep only the latest salary.
3. Calculate department average from those latest salaries.
4. Compare each employee against the department average.


EXACT MISTAKES:
--------------------------------------------------

1. Missing comma before ROW_NUMBER()

You wrote:

E.EMP_NAME
ROW_NUMBER()

There must be a comma.

Correct:

E.EMP_NAME,
ROW_NUMBER()


2. Invalid alias reference

You wrote:

WHERE ES.EMP_ID = A.EMP_ID

But A is the alias of the outer derived table.

A does not exist inside that subquery.


3. Missing JOIN condition

You wrote:

JOIN EMPLOYEE_SALARY ES
WHERE ...

The JOIN needs an ON condition.

Correct:

JOIN EMPLOYEE_SALARY ES
    ON E.EMP_ID = ES.EMP_ID


4. LATEST_SALARY was never created

You selected:

ES.SALARY AS SALARY

but later referenced:

A.LATEST_SALARY

Those are different column names.


5. Department average is logically wrong

You used:

AVG(ES.SALARY)

against salary history.

The requirement is:

AVG(latest salary per employee)

These are not the same.

Example:

EMP A:
2025 = 40,000
2026 = 50,000

EMP B:
2025 = 60,000
2026 = 70,000

Correct department average:

(50,000 + 70,000) / 2
= 60,000

You cannot average all historical records.


WHY THIS MISTAKE HAPPENED:
--------------------------------------------------

The main problem was aggregation at the wrong grain.

You need to establish:

1 row = 1 employee

before calculating:

1 row = 1 department average


Think in layers:

SALARY HISTORY
→ latest salary per employee
→ employee-level dataset
→ department average
→ comparison


KEY PATTERN / LESSON:
--------------------------------------------------

When a requirement says:

"latest X, then average latest X"

you must first isolate the latest record.

Correct sequence:

DETAIL HISTORY
↓
LATEST RECORD PER ENTITY
↓
ENTITY-LEVEL DATASET
↓
GROUP BY DEPARTMENT
↓
AVERAGE
↓
COMPARE



==================================================
DAY 15 — FINAL RESULT
==================================================

Q1 → 🟡 PARTIALLY CORRECT
Q2 → 🟡 PARTIALLY CORRECT
Q3 → 🟢 CORRECT
Q4 → 🔴 WRONG
Q5 → 🔴 WRONG


FULLY CORRECT:
1

PARTIALLY CORRECT:
2

WRONG:
2


STRICT SCORE:
1 / 5 = 20%


EFFECTIVE ACCURACY:
Correct = 1
Partial = 2 × 0.5 = 1
Wrong = 0

2 / 5 = 40%


==================================================
DAY 15 — CORE LESSONS
==================================================

1. LEFT JOIN + AGGREGATION

Preserve the required population first.

If every customer must appear:

CUSTOMER
→ LEFT JOIN
→ ORDER SUMMARY


2. AGGREGATE BEFORE JOIN

Independent one-to-many sources must usually be aggregated
to the required grain before joining.

ORDERS
→ CUSTOMER grain

PAYMENTS
→ CUSTOMER grain


3. LATEST RECORD PATTERN

ROW_NUMBER() OVER
(
    PARTITION BY ENTITY_ID
    ORDER BY EFFECTIVE_DATE DESC
)

then:

RN = 1


4. BUSINESS TERMINOLOGY → SQL

"Total sales amount"
→ SUM(AMOUNT)

"Number of completed transactions"
→ COUNT / conditional SUM

"Zero cancelled"
→ conditional count = 0


5. MONTH FILTERING

Do not use:

DATE = 'SEP-2026'

Use:

DATE >= DATE '2026-09-01'
AND DATE < DATE '2026-10-01'


6. QUERY GRAIN

Always identify:

WHAT DOES ONE FINAL ROW REPRESENT?

Examples:

1 row = customer
1 row = store
1 row = product
1 row = employee


7. LATEST → THEN AGGREGATE

If the requirement says:

"average latest salary"

do not average salary history directly.

First:

latest salary per employee

then:

average by department


8. SQL SYNTAX PRECISION

Recurring issues in Day 15:

- Missing FROM
- Missing WHERE
- Missing ON
- Missing commas
- Wrong aliases
- Invalid operator =<
- Wrong date range

These are now a priority weakness.


==================================================
DAY 15 — NEXT FOCUS
==================================================

Primary weaknesses to reinforce:

1. SQL clause order
2. Syntax precision
3. Query grain
4. Aggregation before JOIN
5. Date-range filtering
6. Business requirement → correct aggregate
7. Multi-stage CTE thinking
8. Alias discipline


==================================================
NO REWRITE PRACTICE
==================================================
