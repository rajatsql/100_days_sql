SQL CHALLENGE — DAY 19
YOUR ANSWER + CORRECT ANSWER

============================================================
Q1 — CUSTOMER ORDER QUALIFICATION
============================================================

RESULT: ⚠ PARTIALLY CORRECT

## YOUR ANSWER:

WITH ORDER_SUMMARY AS (
SELECT CUSTOMER_ID,
SUM(CASE WHEN STATUS = 'COMPLETED' THEN 1 ELSE 0 END) 
AS COMPLETED_ORDER_COUNT ,
SUM(CASE WHEN STATUS = 'CANCELLED' THEN 1 ELSE 0 END) 
AS CANCELLED_ORDER_COUNT ,
SUM(CASE WHEN STATUS = 'COMPLETED' THEN AMOUNT ELSE 0 END) 
AS TOTAL_COMPLETED_AMOUNT 
FROM ORDERS WHERE
ORDER_DATE >= TO_DATE('01-SEP-2026','DD-MON-RRRR') AND
ORDER_DATE <= TO_DATE('30-SEP-2026','DD-MON-RRRR')
GROUP BY  CUSTOMER_ID)

SELECT C.CUSTOMER_ID,C.CUSTOMER_NAME,NVL(OS.COMPLETED_ORDER_COUNT,0),NVL(OS.TOTAL_COMPLETED_AMOUNT,0) FROM 
CUSTOMER C LEFT JOIN ORDER_SUMMARY OS 
ON C.CUSTOMER_ID = OS.CUSTOMER_ID 
AND OS.COMPLETED_ORDER_COUNT >= 3
AND OS.TOTAL_COMPLETED_AMOUNT > 50000
AND OS.CANCELLED_ORDER_COUNT = 0
WHERE
STATUS  = 'ACTIVE';

## CORRECT ANSWER:

WITH ORDER_SUMMARY AS (
    SELECT CUSTOMER_ID,
           COUNT(CASE WHEN STATUS = 'COMPLETED' THEN 1 END) AS COMPLETED_ORDER_COUNT,
           SUM(CASE WHEN STATUS = 'CANCELLED' THEN 1 ELSE 0 END) AS CANCELLED_ORDER_COUNT,
           SUM(CASE WHEN STATUS = 'COMPLETED' THEN AMOUNT ELSE 0 END) AS TOTAL_COMPLETED_AMOUNT
    FROM ORDERS
    WHERE ORDER_DATE >= DATE '2026-09-01'
      AND ORDER_DATE <  DATE '2026-10-01'
    GROUP BY CUSTOMER_ID
)
SELECT C.CUSTOMER_ID,
       C.CUSTOMER_NAME,
       OS.COMPLETED_ORDER_COUNT,
       OS.TOTAL_COMPLETED_AMOUNT
FROM CUSTOMER C
JOIN ORDER_SUMMARY OS
  ON C.CUSTOMER_ID = OS.CUSTOMER_ID
WHERE C.STATUS = 'ACTIVE'
  AND OS.COMPLETED_ORDER_COUNT >= 3
  AND OS.TOTAL_COMPLETED_AMOUNT > 50000
  AND OS.CANCELLED_ORDER_COUNT = 0;

## EXPLANATION:

Your aggregation logic and customer grain are correct.

The main mistake is using LEFT JOIN while placing the qualification conditions in ON. A LEFT JOIN preserves ACTIVE customers even when the summary does not satisfy the conditions.

The requirement is to return only qualifying customers, so use INNER JOIN and apply the qualification in WHERE.

## EXACT MISTAKES:

1. LEFT JOIN can preserve non-qualifying customers.
2. Aggregate qualification filters are incorrectly placed in ON.
3. STATUS should be qualified as C.STATUS.
4. <= 30-SEP-2026 is less safe when ORDER_DATE contains a time component.

## WHY THIS MISTAKE HAPPENED:

You correctly built the customer-level summary, but treated the qualification criteria as join conditions.

## KEY PATTERN / LESSON:

JOIN condition = how rows match.
WHERE condition = which final rows survive.

============================================================
Q2 — PRODUCT SALES ANALYSIS
============================================================

RESULT: ⚠ PARTIALLY CORRECT

## YOUR ANSWER:

WITH SALE_SUMMARY AS 
(SELECT PRODUCT_ID,
COUNT(*) AS TOTAL_TRANSACTIONS,
SUM(CASE WHEN STATUS = 'COMPLETED' THEN 1 ELSE 0 END) AS COMPLETED_TRANSACTIONS,
SUM(CASE WHEN STATUS = 'CANCELLED' THEN 1 ELSE 0 END) AS CANCELLED_TRANSACTIONS,
SUM(CASE WHEN STATUS = 'COMPLETED' THEN AMOUNT ELSE 0 END) AS COMPLETED_AMOUNT,
FROM SALES WHERE
SALE_DATE >= TO_DATE('01-SEP-2026','DD-MON-RRRR') AND
SALE_DATE <= TO_DATE('30-SEP-2026','DD-MON-RRRR')
GROUP BY PRODUCT_ID)

SELECT 
	P.PRODUCT_ID,
	P.PRODUCT_NAME,
	SS.TOTAL_TRANSACTIONS,
	SS.COMPLETED_TRANSACTIONS,
	SS.COMPLETED_AMOUNT,
	SS.CANCELLED_TRANSACTIONS
FROM PRODUCT P LEFT JOIN SALE_SUMMARY SS
ON P.PRODUCT_ID = SS.PRODUCT_ID
AND SS.TOTAL_TRANSACTIONS >= 100
AND SS.COMPLETED_TRANSACTIONS >= 80
AND SS.COMPLETED_AMOUNT > 1000000
AND SS.CANCELLED_TRANSACTIONS = 0
WHERE
STATUS = 'ACTIVE';

## CORRECT ANSWER:

WITH SALE_SUMMARY AS (
    SELECT PRODUCT_ID,
           COUNT(*) AS TOTAL_TRANSACTIONS,
           SUM(CASE WHEN STATUS = 'COMPLETED' THEN 1 ELSE 0 END) AS COMPLETED_TRANSACTIONS,
           SUM(CASE WHEN STATUS = 'CANCELLED' THEN 1 ELSE 0 END) AS CANCELLED_TRANSACTIONS,
           SUM(CASE WHEN STATUS = 'COMPLETED' THEN AMOUNT ELSE 0 END) AS COMPLETED_AMOUNT
    FROM SALES
    WHERE SALE_DATE >= DATE '2026-09-01'
      AND SALE_DATE <  DATE '2026-10-01'
    GROUP BY PRODUCT_ID
)
SELECT P.PRODUCT_ID,
       P.PRODUCT_NAME,
       SS.TOTAL_TRANSACTIONS,
       SS.COMPLETED_TRANSACTIONS,
       SS.COMPLETED_AMOUNT,
       SS.CANCELLED_TRANSACTIONS
FROM PRODUCT P
JOIN SALE_SUMMARY SS
  ON P.PRODUCT_ID = SS.PRODUCT_ID
WHERE P.STATUS = 'ACTIVE'
  AND SS.TOTAL_TRANSACTIONS >= 100
  AND SS.COMPLETED_TRANSACTIONS >= 80
  AND SS.COMPLETED_AMOUNT > 1000000
  AND SS.CANCELLED_TRANSACTIONS = 0;

## EXPLANATION:

Your aggregation logic and PRODUCT_ID grain are correct.

There is a syntax error: the comma after COMPLETED_AMOUNT is invalid.

The bigger logical issue is the same LEFT JOIN + ON-filter mistake from Q1. Non-qualifying ACTIVE products can still survive the LEFT JOIN.

## EXACT MISTAKES:

1. Extra comma after COMPLETED_AMOUNT.
2. LEFT JOIN preserves non-qualifying products.
3. Aggregate qualification conditions belong in WHERE.
4. STATUS should be P.STATUS.
5. Date boundary should preferably use < DATE '2026-10-01'.

## WHY THIS MISTAKE HAPPENED:

You correctly understood the aggregation but reused LEFT JOIN without checking the effect of filtering inside ON.

## KEY PATTERN / LESSON:

For aggregate qualification:
AGGREGATE → JOIN → WHERE qualification

============================================================
Q3 — SALARY HISTORY
============================================================

RESULT: ⚠ PARTIALLY CORRECT

## YOUR ANSWER:

WITH LATEST_SALARY AS (
SELECT ES.EMP_ID,ES.SALARY AS LATEST_SALARY FROM EMPLOYEE_SALARY ES 
WHERE ES.EFFECTIVE_DATE = 
(SELECT MAX(ESS.EFFECTIVE_DATE) FROM EMPLOYEE_SALARY ESS WHERE ES.EMP_ID = ESS.EMP_ID))


WITH PREVIOUS_SALARY AS (
SELECT ES.EMP_ID,ES.SALARY AS PREVIOUS_SALARY FROM EMPLOYEE_SALARY ES 
WHERE ES.EFFECTIVE_DATE = 
(SELECT MAX(ESS.EFFECTIVE_DATE) FROM EMPLOYEE_SALARY ESS WHERE ES.EMP_ID = ESS.EMP_ID
AND  ESS.EFFECTIVE_DATE <> (SELECT MAX(ESS.EFFECTIVE_DATE) FROM EMPLOYEE_SALARY ESS WHERE ES.EMP_ID = ESS.EMP_ID)))

SELECT LS.EMP_ID,PS.PREVIOUS_SALARY,LS.LATEST_SALARY
,(LS.LATEST_SALARY - PS.PREVIOUS_SALARY) AS SALARY_INCREASE
FROM LATEST_SALARY LS JOIN PREVIOUS_SALARY PS 
ON LS.EMP_ID = PS.EMP_ID
WHERE LS.LATEST_SALARY > PS.PREVIOUS_SALARY;

## CORRECT ANSWER:

WITH SALARY_HISTORY AS (
    SELECT EMP_ID,
           SALARY,
           EFFECTIVE_DATE,
           ROW_NUMBER() OVER (
               PARTITION BY EMP_ID
               ORDER BY EFFECTIVE_DATE DESC
           ) AS RN
    FROM EMPLOYEE_SALARY
)
SELECT EMP_ID,
       MAX(CASE WHEN RN = 2 THEN SALARY END) AS PREVIOUS_SALARY,
       MAX(CASE WHEN RN = 1 THEN SALARY END) AS LATEST_SALARY,
       MAX(CASE WHEN RN = 1 THEN SALARY END)
       - MAX(CASE WHEN RN = 2 THEN SALARY END) AS SALARY_INCREASE
FROM SALARY_HISTORY
WHERE RN <= 2
GROUP BY EMP_ID
HAVING MAX(CASE WHEN RN = 1 THEN SALARY END)
     > MAX(CASE WHEN RN = 2 THEN SALARY END);

## EXPLANATION:

Your overall idea is close: identify latest salary, identify previous salary, then compare.

However, two separate WITH clauses are invalid in one SQL statement. Also, this is fundamentally a row-position problem, so ROW_NUMBER is clearer and safer than nested MAX subqueries.

## EXACT MISTAKES:

1. Two separate WITH clauses are invalid.
2. Previous-record logic is unnecessarily complicated.
3. Duplicate EFFECTIVE_DATE values can produce multiple rows.
4. No deterministic tie-breaker if duplicate dates are possible.

## WHY THIS MISTAKE HAPPENED:

You tried to solve a row-position problem with nested MAX() logic.

## KEY PATTERN / LESSON:

For latest / previous / second latest / Nth record, think:
ROW_NUMBER(), LAG(), LEAD().

============================================================
Q4 — STORE / PRODUCT RANKING
============================================================

RESULT: ⚠ PARTIALLY CORRECT

## YOUR ANSWER:

WITH SALE_SUMMARY AS(
SELECT STORE_ID,PRODUCT_ID,TOTAL_SALES_AMOUNT, 
DENSE_RANK() OVER(PARTITION BY STORE_ID,PRODUCT_ID ORDER BY TOTAL_SALES_AMOUNT DESC) AS SALES_RANK FROM
(SELECT STORE_ID,PRODUCT_ID,
SUM(CASE WHEN STATUS = 'COMPLETED' THEN AMOUNT ELSE 0 END)TOTAL_SALES_AMOUNT
FROM SALES WHERE
SALE_DATE >= TO_DATE('01-SEP-2026','DD-MON-RRRR') AND
SALE_DATE <= TO_DATE('30-SEP-2026','DD-MON-RRRR')
GROUP BY STORE_ID,PRODUCT_ID))

SELECT S.STORE_ID,
S.STORE_NAME,
SS.PRODUCT_ID,
SS.TOTAL_SALES_AMOUNT,
SS.SALES_RANK
FROM STORE S JOIN SALE_SUMMARY SS
ON S.STORE_ID =SS.STORE_ID
WHERE SS.SALES_RANK <= 2;

## CORRECT ANSWER:

WITH SALE_SUMMARY AS (
    SELECT STORE_ID,
           PRODUCT_ID,
           SUM(AMOUNT) AS TOTAL_SALES_AMOUNT
    FROM SALES
    WHERE SALE_DATE >= DATE '2026-09-01'
      AND SALE_DATE < DATE '2026-10-01'
      AND STATUS = 'COMPLETED'
    GROUP BY STORE_ID, PRODUCT_ID
),
SALE_RANK AS (
    SELECT STORE_ID,
           PRODUCT_ID,
           TOTAL_SALES_AMOUNT,
           DENSE_RANK() OVER (
               PARTITION BY STORE_ID
               ORDER BY TOTAL_SALES_AMOUNT DESC
           ) AS SALES_RANK
    FROM SALE_SUMMARY
)
SELECT S.STORE_ID,
       S.STORE_NAME,
       SR.PRODUCT_ID,
       SR.TOTAL_SALES_AMOUNT,
       SR.SALES_RANK
FROM STORE S
JOIN SALE_RANK SR
  ON S.STORE_ID = SR.STORE_ID
WHERE SR.SALES_RANK <= 2;

## EXPLANATION:

You got the aggregation grain correct: STORE_ID + PRODUCT_ID.

But the ranking partition is wrong.

You used:
PARTITION BY STORE_ID, PRODUCT_ID

That creates a separate ranking partition for every store/product combination, so products do not compete against each other within the store.

It should be:
PARTITION BY STORE_ID

## EXACT MISTAKES:

1. Wrong ranking partition: STORE_ID, PRODUCT_ID instead of STORE_ID.
2. STATUS should preferably be filtered before aggregation.
3. Date boundary should preferably use < DATE '2026-10-01'.

## WHY THIS MISTAKE HAPPENED:

You correctly identified the GROUP BY grain but assumed the window partition should use the same columns.

## KEY PATTERN / LESSON:

GROUP BY defines the rows being ranked.
PARTITION BY defines the group within which those rows compete.

============================================================
Q5 — LEAD-LEVEL PAYMENT RECONCILIATION
============================================================

RESULT: ✗ WRONG

## YOUR ANSWER:

WITH ORDER_SUMMARY AS(
SELECT ORDER_ID,CUSTOMER_ID,
SUM(CASE WHEN STATUS = 'COMPLETED' THEN 1 ELSE O END) AS COMPLETED_ORDER_COUNT,
SUM(CASE WHEN STATUS = 'COMPLETED' THEN AMOUNT ELSE O END) AS TOTAL_ORDER_AMOUNT,
FROM ORDERS
WHERE
ORDER_DATE >= TO_DATE('01-SEP-2026','DD-MON-RRRR') AND
ORDER_DATE <= TO_DATE('30-SEP-2026','DD-MON-RRRR')
GROUP BY ORDER_ID,CUSTOMER_ID),

PAYMENT_WORK AS (
SELECT O.ORDER_ID , P.PAYMENT_AMOUNT , SUM(CASE WHEN P.PAYMENT_AMOUNT = 0  THEN 1 ELSE 0 END) AS UNPAID_ORDER_COUNT
FROM ORDERS O JOIN PAYMENT P
ON O.ORDER_ID = P.ORDER_ID
WHERE
O.ORDER_DATE >= TO_DATE('01-SEP-2026','DD-MON-RRRR') AND
O.ORDER_DATE <= TO_DATE('30-SEP-2026','DD-MON-RRRR')
AND O.STATUS = 'SUCCESS'
AND P.STATUS = 'COMPLETED'
GROUP BY O.ORDER_ID , P.PAYMENT_AMOUNT
),

PAYMENT_SUMMARY AS (
SELECT ORDER_ID , SUM(PAYMENT_AMOUNT) AS TOTAL_PAID_AMOUNT FROM PAYMENT_WORK 
GROUP BY ORDER_ID
)

SELECT C.CUSTOMER_ID,
C.CUSTOMER_NAME,
OS.COMPLETED_ORDER_COUNT,
OS.TOTAL_ORDER_AMOUNT,
PS.TOTAL_PAID_AMOUNT,
PW.UNPAID_ORDER_COUNT,
(OS.TOTAL_ORDER_AMOUNT - PS.TOTAL_PAID_AMOUNT) AS OUTSTANDING_AMOUNT
FROM CUSTOMER C LEFT JOIN ORDER_SUMMARY OS
ON C.CUSTOMER_ID = OS.CUSTOMER_ID LEFT JOIN PAYMENT_WORK PW
ON OS.ORDER_ID = PW.ORDER_ID LEFT JOIN PAYMENT_SUMMARY PS
ON PW.ORDER_ID = PS.ORDER_ID
WHERE 
STATUS = 'ACTIVE'

## CORRECT ANSWER:

WITH ORDER_PAYMENT AS (
    SELECT O.ORDER_ID,
           O.CUSTOMER_ID,
           O.AMOUNT AS ORDER_AMOUNT,
           SUM(CASE
                   WHEN P.STATUS = 'SUCCESS'
                   THEN P.PAYMENT_AMOUNT
                   ELSE 0
               END) AS PAID_AMOUNT
    FROM ORDERS O
    LEFT JOIN PAYMENT P
      ON O.ORDER_ID = P.ORDER_ID
    WHERE O.ORDER_DATE >= DATE '2026-09-01'
      AND O.ORDER_DATE < DATE '2026-10-01'
      AND O.STATUS = 'COMPLETED'
    GROUP BY O.ORDER_ID, O.CUSTOMER_ID, O.AMOUNT
),
CUSTOMER_SUMMARY AS (
    SELECT CUSTOMER_ID,
           COUNT(*) AS COMPLETED_ORDER_COUNT,
           SUM(ORDER_AMOUNT) AS TOTAL_ORDER_AMOUNT,
           SUM(PAID_AMOUNT) AS TOTAL_PAID_AMOUNT,
           SUM(CASE WHEN PAID_AMOUNT = 0 THEN 1 ELSE 0 END) AS UNPAID_ORDER_COUNT
    FROM ORDER_PAYMENT
    GROUP BY CUSTOMER_ID
)
SELECT C.CUSTOMER_ID,
       C.CUSTOMER_NAME,
       CS.COMPLETED_ORDER_COUNT,
       CS.TOTAL_ORDER_AMOUNT,
       CS.TOTAL_PAID_AMOUNT,
       CS.UNPAID_ORDER_COUNT,
       CS.TOTAL_ORDER_AMOUNT - CS.TOTAL_PAID_AMOUNT AS OUTSTANDING_AMOUNT
FROM CUSTOMER C
JOIN CUSTOMER_SUMMARY CS
  ON C.CUSTOMER_ID = CS.CUSTOMER_ID
WHERE C.STATUS = 'ACTIVE'
  AND CS.COMPLETED_ORDER_COUNT >= 5
  AND CS.TOTAL_ORDER_AMOUNT > 100000
  AND CS.TOTAL_PAID_AMOUNT < CS.TOTAL_ORDER_AMOUNT
  AND CS.UNPAID_ORDER_COUNT >= 1;

## EXPLANATION:

This question required controlling the grain across CUSTOMER → ORDERS → PAYMENT.

The safe sequence is:

PAYMENT → ORDER GRAIN → CUSTOMER GRAIN → FINAL CUSTOMER FILTER

Your query joins the tables before stabilizing the order-level payment result.

## EXACT MISTAKES:

1. ORDER_SUMMARY is grouped by ORDER_ID + CUSTOMER_ID instead of customer grain.
2. ELSE O is invalid; it should be ELSE 0.
3. Extra comma after TOTAL_ORDER_AMOUNT.
4. O.STATUS = 'SUCCESS' is incorrect; SUCCESS is a PAYMENT status.
5. P.STATUS = 'COMPLETED' is incorrect for the stated requirement; use SUCCESS.
6. INNER JOIN PAYMENT removes orders with no payment record.
7. GROUP BY O.ORDER_ID, P.PAYMENT_AMOUNT can create multiple rows per order.
8. Payment totals are not rolled up correctly to customer grain.
9. No correct unpaid-order detection.
10. No final TOTAL_PAID_AMOUNT < TOTAL_ORDER_AMOUNT condition.
11. No UNPAID_ORDER_COUNT >= 1 condition.
12. Missing zero/NULL handling for orders without successful payment.
13. STATUS should be qualified as C.STATUS.

## WHY THIS MISTAKE HAPPENED:

This is the recurring one-to-many + grain problem.

One customer → many orders.
One order → many payments.

Joining everything directly can multiply rows.

## KEY PATTERN / LESSON:

For CUSTOMER → ORDERS → PAYMENT:

1. Determine payment at ORDER grain.
2. Roll order information to CUSTOMER grain.
3. Apply customer-level conditions.
4. Join CUSTOMER master.
5. Return one row per CUSTOMER.

============================================================
DAY 19 FINAL RESULT
============================================================

FULLY CORRECT: 0
PARTIALLY CORRECT: 4
WRONG: 1

STRICT SCORE:
0 / 5 = 0.00%

EFFECTIVE ACCURACY:
(0 + 4 × 0.5) / 5 = 40.00%

DAY 19 — CORE LESSON

Your biggest issue today was not understanding the business requirement.

You generally identified the correct tables and aggregation ideas.

The recurring problem was WHERE the logic belongs:
- ON vs WHERE
- aggregation grain vs ranking partition
- order grain vs customer grain
- payment status vs order status

Your SQL thinking is improving, but you are still writing the query before fully locking the relational structure.

DAY 19 — PRIORITY LESSONS

1. LEFT JOIN + ON filter does NOT mean "return only matching rows".
2. JOIN condition answers how rows match.
3. WHERE answers which final rows survive.
4. Aggregation grain and window-function partition are different concepts.
5. Use ROW_NUMBER() / LAG() for latest/previous records.
6. Pre-aggregate one-to-many relationships before joining them.
7. Always identify the final output grain first.
8. Check every STATUS against its correct table.
9. Orders with no payment require LEFT JOIN.
10. Do a final syntax + grain check before submitting.

NO REWRITE PRACTICE

============================================================
# CUMULATIVE STATUS THROUGH DAY 19
============================================================

### Historical Day 1–14

* Correct: 30
* Partial: 29
* Wrong: 10
* Questions: 70

### Day 15

* Correct: 1
* Partial: 2
* Wrong: 2

### Day 16

* Correct: 3
* Partial: 1
* Wrong: 1

### Day 17

* Correct: 0
* Partial: 2
* Wrong: 3

### Day 18

* Correct: 0
* Partial: 0
* Wrong: 5

### Day 19

* Correct: 0
* Partial: 4
* Wrong: 1

### CUMULATIVE

* **Correct: 34**
* **Partial: 38**
* **Wrong: 22**
* **Questions: 95**

> The historical Day 1–7 baseline contains a one-question classification-count inconsistency, so the category counts do not sum to the 95-question total. The historical baseline is preserved rather than silently changed.

### CUMULATIVE STRICT SCORE

**34 / 95 = 35.79%**

### CUMULATIVE EFFECTIVE ACCURACY

**(34 + 38 × 0.5) / 95 = 56.84%**
