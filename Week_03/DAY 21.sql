SQL CHALLENGE — DAY 21
YOUR ANSWER + CORRECT ANSWER
============================================================

Q1 — CUSTOMER ORDER QUALIFICATION
============================================================

RESULT: ⚠ PARTIALLY CORRECT

## YOUR ANSWER:

WITH ORDER_SUMMARY AS
(
	SELECT 
		O.CUSTOMER_ID,
		SUM(CASE WHEN O.STATUS = 'COMPLETED' THEN 1 ELSE 0 END) AS COMPLETED_ORDER_COUNT,
		SUM(CASE WHEN O.STATUS = 'COMPLETED' THEN O.AMOUNT ELSE 0 END) AS TOTAL_COMPLETED_AMOUNT,
		SUM(CASE WHEN O.STATUS = 'CANCELLED' THEN 1 ELSE 0 END) AS CANCELLED_ORDER_COUNT,
		COUNT(DISTINCT CASE WHEN O.STATUS = 'COMPLETED' THEN STORE_ID ELSE 0 END) AS STORE_COUNT
	FROM ORDERS O
	WHERE ORDER_DATE >= DATE '2026-10-01'
	  AND ORDER_DATE <= DATE '2026-10-31'
	GROUP BY O.CUSTOMER_ID
)
SELECT C.CUSTOMER_ID, C.CUSTOMER_NAME,
       OS.COMPLETED_ORDER_COUNT, OS.TOTAL_COMPLETED_AMOUNT, OS.STORE_COUNT
FROM CUSTOMER C JOIN ORDER_SUMMARY OS
  ON C.CUSTOMER_ID = OS.CUSTOMER_ID
WHERE C.STATUS = 'ACTIVE'
  AND OS.COMPLETED_ORDER_COUNT >= 3
  AND OS.TOTAL_COMPLETED_AMOUNT > 75000
  AND OS.STORE_COUNT >= 2
  AND OS.CANCELLED_ORDER_COUNT = 0;

## CORRECT ANSWER:

WITH ORDER_SUMMARY AS
(
    SELECT O.CUSTOMER_ID,
           COUNT(CASE WHEN O.STATUS = 'COMPLETED' THEN 1 END) AS COMPLETED_ORDER_COUNT,
           SUM(CASE WHEN O.STATUS = 'COMPLETED' THEN O.AMOUNT ELSE 0 END) AS TOTAL_COMPLETED_AMOUNT,
           COUNT(CASE WHEN O.STATUS = 'CANCELLED' THEN 1 END) AS CANCELLED_ORDER_COUNT,
           COUNT(DISTINCT CASE WHEN O.STATUS = 'COMPLETED' THEN O.STORE_ID END) AS STORE_COUNT
    FROM ORDERS O
    WHERE O.ORDER_DATE >= DATE '2026-10-01'
      AND O.ORDER_DATE < DATE '2026-11-01'
    GROUP BY O.CUSTOMER_ID
)
SELECT C.CUSTOMER_ID, C.CUSTOMER_NAME,
       OS.COMPLETED_ORDER_COUNT, OS.TOTAL_COMPLETED_AMOUNT, OS.STORE_COUNT
FROM CUSTOMER C
JOIN ORDER_SUMMARY OS ON C.CUSTOMER_ID = OS.CUSTOMER_ID
WHERE C.STATUS = 'ACTIVE'
  AND OS.COMPLETED_ORDER_COUNT >= 3
  AND OS.TOTAL_COMPLETED_AMOUNT > 75000
  AND OS.STORE_COUNT >= 2
  AND OS.CANCELLED_ORDER_COUNT = 0;

## EXPLANATION:
Your overall aggregation structure is correct. The mistake is:
COUNT(DISTINCT CASE WHEN ... THEN STORE_ID ELSE 0 END)

The ELSE 0 becomes a real distinct value. A customer with completed orders from only one store could therefore get STORE_COUNT = 2. Omit ELSE so non-completed rows become NULL and are not counted.

Also prefer < DATE '2026-11-01' when ORDER_DATE can contain a time component.

## EXACT MISTAKES:
1. ELSE 0 inside COUNT(DISTINCT ...) artificially counts store 0.
2. Date upper boundary is less safe if ORDER_DATE contains time.

## WHY THIS MISTAKE HAPPENED:
You applied the ELSE 0 pattern useful for SUM/conditional arithmetic to COUNT(DISTINCT), where 0 is an actual value.

## KEY PATTERN / LESSON:
COUNT(DISTINCT CASE WHEN condition THEN column END)

============================================================
Q2 — PRODUCT PERFORMANCE QUALIFICATION
============================================================

RESULT: ✓ CORRECT

## YOUR ANSWER:

WITH SALE_SUMMARY AS 
(
	SELECT S.PRODUCT_ID,
	       COUNT(*) AS TOTAL_TRANSACTIONS,
	       COUNT(CASE WHEN S.STATUS = 'COMPLETED' THEN 1 END) AS COMPLETED_TRANSACTIONS,
	       SUM(CASE WHEN S.STATUS = 'COMPLETED' THEN S.AMOUNT ELSE 0 END) AS COMPLETED_AMOUNT,
	       SUM(CASE WHEN S.STATUS = 'CANCELLED' THEN 1 ELSE 0 END) AS CANCELLED_TRANSACTIONS
	FROM SALES S
	WHERE S.SALE_DATE >= DATE '2026-10-01'
	  AND S.SALE_DATE <= DATE '2026-10-31'
	GROUP BY S.PRODUCT_ID
)
SELECT P.PRODUCT_ID, P.PRODUCT_NAME, SS.TOTAL_TRANSACTIONS,
       SS.COMPLETED_TRANSACTIONS,
       (SS.COMPLETED_TRANSACTIONS /SS.TOTAL_TRANSACTIONS)*100 AS COMPLETION_PERCENTAGE,
       SS.COMPLETED_AMOUNT
FROM PRODUCT P JOIN SALE_SUMMARY SS
  ON P.PRODUCT_ID = SS.PRODUCT_ID
WHERE P.STATUS = 'ACTIVE'
  AND SS.TOTAL_TRANSACTIONS >= 100 
  AND SS.COMPLETED_TRANSACTIONS >= 80 
  AND ((SS.COMPLETED_TRANSACTIONS /SS.TOTAL_TRANSACTIONS)*100) >= 80
  AND SS.COMPLETED_AMOUNT > 1000000
  AND SS.CANCELLED_TRANSACTIONS = 0;

## CORRECT ANSWER:
Your logic is substantively correct. The percentage calculation and all qualification conditions are correct. The date boundary can be made safer with < DATE '2026-11-01'.

## EXPLANATION:
You correctly built the product-level aggregate first and then applied all business qualification conditions in the outer query.

## EXACT MISTAKES:
No substantive logic mistake.

## KEY PATTERN / LESSON:
Aggregate at the business entity grain first, then qualify that entity.

============================================================
Q3 — EMPLOYEE SALARY PROGRESSION
============================================================

RESULT: ⚠ PARTIALLY CORRECT

## YOUR ANSWER:

WITH SALARY_SUMMARY AS
(
SELECT EMP_ID, SALARY, EFFECTIVE_DATE, RN 
FROM
 (SELECT EMP_ID, SALARY, EFFECTIVE_DATE,
         ROW_NUMBER() OVER(PARTITION BY EMP_ID ORDER BY EFFECTIVE_DATE DESC) AS RN 
  FROM EMPLOYEE_SALARY) A 
WHERE RN <= 2
),
PRE_SALARY AS
(
SELECT EMP_ID,
       LAG(SALARY) OVER(PARTITION BY EMP_ID ORDER BY RN DESC) AS PREVIOUS_SALARY,
       SALARY AS LATEST_SALARY,
       EFFECTIVE_DATE, RN,
       SALARY - (LAG(SALARY) OVER(PARTITION BY EMP_ID ORDER BY RN DESC)) AS SALARY_INCREASE,
       ROUND(((SALARY - (LAG(SALARY) OVER(PARTITION BY EMP_ID ORDER BY RN DESC)))
       /(LAG(SALARY) OVER(PARTITION BY EMP_ID ORDER BY RN DESC)))*100,2) ASINCREASE_PERCENTAGE
FROM SALARY_SUMMARY)
SELECT EMP_ID, MAX(PREVIOUS_SALARY), MAX(LATEST_SALARY),
       MAX(SALARY_INCREASE), MAX(INCREASE_PERCENTAGE)
FROM PRE_SALARY
GROUP BY EMP_ID
HAVING MAX(LATEST_SALARY) > MAX(PREVIOUS_SALARY)
   AND MAX(INCREASE_PERCENTAGE) <= 15;

## CORRECT ANSWER:

WITH SALARY_RANKED AS
(
    SELECT EMP_ID, SALARY, EFFECTIVE_DATE,
           ROW_NUMBER() OVER
           (PARTITION BY EMP_ID ORDER BY EFFECTIVE_DATE DESC) AS RN
    FROM EMPLOYEE_SALARY
),
SALARY_CHANGE AS
(
    SELECT EMP_ID,
           LAG(SALARY) OVER(PARTITION BY EMP_ID ORDER BY RN DESC) AS PREVIOUS_SALARY,
           SALARY AS LATEST_SALARY,
           SALARY - LAG(SALARY) OVER(PARTITION BY EMP_ID ORDER BY RN DESC) AS SALARY_INCREASE,
           RN
    FROM SALARY_RANKED
    WHERE RN <= 2
)
SELECT EMP_ID, PREVIOUS_SALARY, LATEST_SALARY, SALARY_INCREASE,
       ROUND((SALARY_INCREASE / PREVIOUS_SALARY) * 100, 2) AS INCREASE_PERCENTAGE
FROM SALARY_CHANGE
WHERE RN = 1
  AND LATEST_SALARY > PREVIOUS_SALARY
  AND (SALARY_INCREASE / PREVIOUS_SALARY) * 100 < 15;

## EXPLANATION:
Your latest/previous comparison logic is close. The main qualification error is <= 15 when the question says less than 15%. Exactly 15% must be excluded.

The final MAX/GROUP BY is also unnecessary; preserving the latest-row grain is clearer.

## EXACT MISTAKES:
1. <= 15 should be < 15.
2. Unnecessary MAX/GROUP BY hides the intended latest-row grain.
3. Output aliases are missing.
4. EFFECTIVE_DATE ties would need a deterministic tie-breaker if possible.

## WHY THIS MISTAKE HAPPENED:
The comparison boundary was treated as inclusive instead of exclusive.

## KEY PATTERN / LESSON:
LESS THAN X = < X
AT MOST X = <= X
GREATER THAN X = > X
AT LEAST X = >= X

============================================================
Q4 — STORE TOP 2 PRODUCTS
============================================================

RESULT: ✗ INCORRECT

## YOUR ANSWER:

WITH SALE_SUMMARY AS 
(
	SELECT S.STORE_ID, S.PRODUCT_ID,
	       SUM(S.AMOUNT) AS TOTAL_REVENUE,
	FROM SALES S
	WHERE S.SALE_DATE >= DATE '2026-10-01'
	  AND S.SALE_DATE <= DATE '2026-10-31'
	  AND S.STATUS = 'COMPLETED'
	GROUP BY S.STORE_ID ,S.PRODUCT_ID
)
SALARY_RANK AS
(SELECT SS.STORE_ID, SS.PRODUCT_ID, SS.TOTAL_REVENUE,
        DENSE_RANK() OVER(PARTITION BY SS.STORE_ID,SS.PRODUCT_ID
                          ORDER BY SS.TOTAL_REVENUE DESC) AS REVENUE_RANK
 FROM SALE_SUMMARY)
SELECT S.STORE_ID, S.STORE_NAME, SR.PRODUCT_ID,
       SR.TOTAL_REVENUE, SR.REVENUE_RANK
FROM STORE S JOIN SALARY_RANK SR
JOIN S.STORE_ID = SR.STORE_ID
WHERE SR.REVENUE_RANK <= 2;

## CORRECT ANSWER:

WITH SALE_SUMMARY AS
(
    SELECT S.STORE_ID, S.PRODUCT_ID, SUM(S.AMOUNT) AS TOTAL_REVENUE
    FROM SALES S
    WHERE S.SALE_DATE >= DATE '2026-10-01'
      AND S.SALE_DATE < DATE '2026-11-01'
      AND S.STATUS = 'COMPLETED'
    GROUP BY S.STORE_ID, S.PRODUCT_ID
),
SALES_RANK AS
(
    SELECT SS.STORE_ID, SS.PRODUCT_ID, SS.TOTAL_REVENUE,
           DENSE_RANK() OVER
           (PARTITION BY SS.STORE_ID ORDER BY SS.TOTAL_REVENUE DESC) AS REVENUE_RANK
    FROM SALE_SUMMARY SS
)
SELECT S.STORE_ID, S.STORE_NAME, SR.PRODUCT_ID,
       SR.TOTAL_REVENUE, SR.REVENUE_RANK
FROM STORE S
JOIN SALES_RANK SR ON S.STORE_ID = SR.STORE_ID
WHERE SR.REVENUE_RANK <= 2;

## EXPLANATION:
Multiple errors:
1. Extra comma after TOTAL_REVENUE makes the CTE invalid.
2. PARTITION BY STORE_ID, PRODUCT_ID ranks each product against itself, making the ranking useless.
3. JOIN syntax is invalid. It must use ON.
4. CTE name SALARY_RANK is misleading.
5. Date upper boundary is less safe with timestamps.

## EXACT MISTAKES:
Aggregation grain was correct, but ranking grain was wrong.

## WHY THIS MISTAKE HAPPENED:
You correctly used STORE_ID + PRODUCT_ID for aggregation, then carried both columns into the ranking partition. But PRODUCT_ID is the thing being ranked, so it must not be in PARTITION BY.

## KEY PATTERN / LESSON:
AGGREGATION GRAIN != RANKING GRAIN

GROUP BY STORE_ID, PRODUCT_ID
then
DENSE_RANK() OVER(PARTITION BY STORE_ID ORDER BY TOTAL_REVENUE DESC)

============================================================
Q5 — LEAD-LEVEL CUSTOMER PAYMENT RECONCILIATION
============================================================

RESULT: ✗ INCORRECT

## YOUR ANSWER:

WITH PAYMENT_SUMMARY AS
(
	SELECT O.CUSTOMER_ID, P.ORDER_ID, 
	       SUM(CASE WHEN P.STATUS = 'SUCCESS' THEN P.PAYMENT_AMOUNT ELSE 0 END) AS TOTAL_PAID_AMOUNT,
	       SUM(CASE WHEN O.STATUS = 'COMPLETED' THEN 1 ELSE 0 END) AS COMPLETED_ORDER_COUNT,
	       SUM(CASE WHEN O.STATUS = 'COMPLETED' THEN O.AMOUNT ELSE 0 END) AS TOTAL_ORDER_AMOUNT
	FROM PAYMENT P JOIN ORDERS O
	  ON P.ORDER_ID = O.ORDER_ID	
	WHERE ORDER_DATE >= DATE '2026-10-01'
	  AND ORDER_DATE <= DATE '2026-10-31'
	GROUP BY O.CUSTOMER_ID,P.ORDER_ID
),
ORDER_SUMMARY AS
(
	SELECT PS.CUSTOMER_ID,
	       SUM(PS.TOTAL_PAID_AMOUNT) AS TOTAL_PAID_AMOUNT,
	       SUM(PS.COMPLETED_ORDER_COUNT) AS COMPLETED_ORDER_COUNT,
	       SUM(PS.TOTAL_ORDER_AMOUNT) AS TOTAL_ORDER_AMOUNT,
	       SUM(CASE WHEN TOTAL_PAID_AMOUNT = 0 THEN 1 ELSE 0 END) AS UNPAID_ORDER_COUNT,
	       SUM(CASE WHEN TOTAL_PAID_AMOUNT > 0 AND TOTAL_PAID_AMOUNT < TOTAL_ORDER_AMOUNT THEN 1 ELSE 0 END) AS PARTIALLY_PAID_ORDER_COUNT,
	       SUM(CASE WHEN TOTAL_PAID_AMOUNT >= TOTAL_ORDER_AMOUNT THEN 1 ELSE 0 END) AS PAID_ORDER_COUNT
	FROM PAYMENT_SUMMARY PS
	GROUP BY O.CUSTOMER_ID
)
SELECT C.CUSTOMER_ID, C.CUSTOMER_NAME, OS.COMPLETED_ORDER_COUNT,
       OS.TOTAL_ORDER_AMOUNT, OS.TOTAL_PAID_AMOUNT,
       OS.UNPAID_ORDER_COUNT, OS.PARTIALLY_PAID_ORDER_COUNT,
       OS.PAID_ORDER_COUNT,
       (OS.TOTAL_ORDER_AMOUNT - OS.TOTAL_PAID_AMOUNT) AS OUTSTANDING_AMOUNT
FROM CUSTOMER C JOIN ORDER_SUMMARY OS
  ON C.CUSTOMER_ID = OS.CUSTOMER_ID
WHERE OS.COMPLETED_ORDER_COUNT >= 5
  AND OS.TOTAL_ORDER_AMOUNT > 100000
  AND OS.TOTAL_PAID_AMOUNT < OS.TOTAL_ORDER_AMOUNT
  AND OS.UNPAID_ORDER_COUNT >= 2
  AND OS.PARTIALLY_PAID_ORDER_COUNT >= 1
  AND OS.PAID_ORDER_COUNT >= 3;

## CORRECT ANSWER:

WITH PAYMENT_SUMMARY AS
(
    SELECT O.ORDER_ID,
           SUM(CASE WHEN P.STATUS = 'SUCCESS'
                    THEN P.PAYMENT_AMOUNT ELSE 0 END) AS TOTAL_PAID_AMOUNT
    FROM ORDERS O
    LEFT JOIN PAYMENT P ON O.ORDER_ID = P.ORDER_ID
    GROUP BY O.ORDER_ID
),
ORDER_SUMMARY AS
(
    SELECT O.CUSTOMER_ID, O.ORDER_ID, O.AMOUNT AS ORDER_AMOUNT,
           NVL(PS.TOTAL_PAID_AMOUNT, 0) AS TOTAL_PAID_AMOUNT
    FROM ORDERS O
    LEFT JOIN PAYMENT_SUMMARY PS ON O.ORDER_ID = PS.ORDER_ID
    WHERE O.ORDER_DATE >= DATE '2026-10-01'
      AND O.ORDER_DATE < DATE '2026-11-01'
      AND O.STATUS = 'COMPLETED'
),
CUSTOMER_SUMMARY AS
(
    SELECT CUSTOMER_ID,
           COUNT(*) AS COMPLETED_ORDER_COUNT,
           SUM(ORDER_AMOUNT) AS TOTAL_ORDER_AMOUNT,
           SUM(TOTAL_PAID_AMOUNT) AS TOTAL_PAID_AMOUNT,
           SUM(CASE WHEN TOTAL_PAID_AMOUNT = 0 THEN 1 ELSE 0 END) AS UNPAID_ORDER_COUNT,
           SUM(CASE WHEN TOTAL_PAID_AMOUNT > 0 AND TOTAL_PAID_AMOUNT < ORDER_AMOUNT THEN 1 ELSE 0 END) AS PARTIALLY_PAID_ORDER_COUNT,
           SUM(CASE WHEN TOTAL_PAID_AMOUNT >= ORDER_AMOUNT THEN 1 ELSE 0 END) AS PAID_ORDER_COUNT,
           COUNT(CASE WHEN TOTAL_PAID_AMOUNT > 0 THEN ORDER_ID END) AS ORDERS_WITH_SUCCESS_PAYMENT
    FROM ORDER_SUMMARY
    GROUP BY CUSTOMER_ID
)
SELECT C.CUSTOMER_ID, C.CUSTOMER_NAME,
       CS.COMPLETED_ORDER_COUNT, CS.TOTAL_ORDER_AMOUNT,
       CS.TOTAL_PAID_AMOUNT, CS.UNPAID_ORDER_COUNT,
       CS.PARTIALLY_PAID_ORDER_COUNT, CS.PAID_ORDER_COUNT,
       CS.TOTAL_ORDER_AMOUNT - CS.TOTAL_PAID_AMOUNT AS OUTSTANDING_AMOUNT
FROM CUSTOMER C
JOIN CUSTOMER_SUMMARY CS ON C.CUSTOMER_ID = CS.CUSTOMER_ID
WHERE C.STATUS = 'ACTIVE'
  AND CS.COMPLETED_ORDER_COUNT >= 5
  AND CS.TOTAL_ORDER_AMOUNT > 100000
  AND CS.TOTAL_PAID_AMOUNT < CS.TOTAL_ORDER_AMOUNT
  AND CS.UNPAID_ORDER_COUNT >= 2
  AND CS.PARTIALLY_PAID_ORDER_COUNT >= 1
  AND CS.ORDERS_WITH_SUCCESS_PAYMENT >= 3;

## EXPLANATION:
This is the main Lead-level issue.

Your query starts from PAYMENT and INNER JOINs ORDERS. Therefore an order with no payment disappears immediately, violating the explicit requirement that unpaid orders remain included.

The correct driving entity is ORDERS. First aggregate payments to ORDER_ID, then LEFT JOIN that result back to every completed order.

Other issues:
- GROUP BY O.CUSTOMER_ID in ORDER_SUMMARY is invalid because O is not in scope there.
- Completed order counting is tied to payment rows.
- No proper O.STATUS = 'COMPLETED' filter at the order grain.
- CUSTOMER.STATUS = 'ACTIVE' is missing.
- PAID_ORDER_COUNT >= 3 is not the same as at least 3 different orders with successful payments. A partially paid order also has a successful payment.
- Multiple payments must be collapsed before order classification.

## EXACT MISTAKES:
1. INNER JOIN removes unpaid orders.
2. Wrong driving table for reconciliation.
3. Completed order count depends on payment rows.
4. Invalid alias O in GROUP BY.
5. Missing completed-order filter.
6. Missing ACTIVE customer filter.
7. Missing separate count of orders with successful payments.
8. Missing NVL/COALESCE for orders with no payment.

## WHY THIS MISTAKE HAPPENED:
You approached the problem from the PAYMENT side. The business grain is the ORDER, so ORDERS must drive the reconciliation.

## KEY PATTERN / LESSON:
PAYMENT
→ aggregate payment total per ORDER
→ LEFT JOIN to ORDERS
→ classify each ORDER
→ aggregate to CUSTOMER
→ apply customer qualification

============================================================
DAY 21 FINAL RESULT
============================================================

FULLY CORRECT: 1
PARTIALLY CORRECT: 2
WRONG: 2

STRICT SCORE:
1 / 5 = 20.00%

EFFECTIVE ACCURACY:
(1 + 2 × 0.5) / 5 = 40.00%

============================================================
DAY 21 — CORE LESSON
============================================================

Q2 shows that your conditional aggregation and entity-level qualification are working.

The main weakness remains multi-stage SQL grain.

You often get the first aggregation close, but then lose the required grain during ranking or reconciliation.

Priority patterns:
1. COUNT(DISTINCT CASE WHEN condition THEN column END)
2. AGGREGATION GRAIN != RANKING GRAIN
3. ORDERS must drive payment reconciliation.
4. Aggregate child transactions before joining them to the parent.
5. Always check whether a JOIN can remove rows required by the business rule.

============================================================
DAY 21 — PRIORITY LESSONS
============================================================

1. Do not use ELSE 0 inside COUNT(DISTINCT CASE...).
2. For top products within each store:
   GROUP BY STORE_ID, PRODUCT_ID
   then DENSE_RANK() PARTITION BY STORE_ID.
3. For reconciliation:
   ORDERS → payment total per ORDER → order classification → customer aggregation.
4. "3 paid orders" and "3 orders with successful payment" are different conditions.
5. Translate boundaries exactly: less than = <, at most = <=.
6. Before finalizing a query, verify the grain of every CTE.

============================================================
NO REWRITE PRACTICE
============================================================

# CUMULATIVE STATUS THROUGH DAY 21

Historical Day 1–14
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

### Day 20
* Correct: 0
* Partial: 3
* Wrong: 2

### Day 21
* Correct: 1
* Partial: 2
* Wrong: 2

### CUMULATIVE
* **Correct: 35**
* **Partial: 43**
* **Wrong: 26**
* **Questions: 105**

> The historical Day 1–7 baseline contains a one-question classification-count inconsistency, so the category counts do not sum to the 105-question total. The historical baseline is preserved rather than silently changed.

### CUMULATIVE STRICT SCORE
**35 / 105 = 33.33%**

### CUMULATIVE EFFECTIVE ACCURACY
**(35 + 43 × 0.5) / 105 = 53.81%**
