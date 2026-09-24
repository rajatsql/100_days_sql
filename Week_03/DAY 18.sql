SQL CHALLENGE — DAY 18
YOUR ANSWER + CORRECT ANSWER

Q1 — NOT EXISTS + CORRELATED CONDITION
RESULT: WRONG

YOUR ANSWER:
SELECT C.CUSTOMER_ID,
C.CUSTOMER_NAME FROM CUSTOMER C 
WHERE STATUS = 'ACTIVE'
AND EXISTS (SELECT 1 FROM ORDERS WHERE 
ORDER_DATE >= TO_DATE('01-SEP-2026','DD-MON-RRRR') AND 
ORDER_DATE <= TO_DATE('30-SEP-2026','DD-MON-RRRR') AND  ORDER_STATUS = 'COMPLETED')
AND NOT EXISTS (SELECT 1 FROM ORDERS WHERE 
ORDER_DATE >= TO_DATE('01-SEP-2026','DD-MON-RRRR') AND 
ORDER_DATE <= TO_DATE('30-SEP-2026','DD-MON-RRRR') AND  ORDER_STATUS = 'CANCELLED');

CORRECT ANSWER:
SELECT C.CUSTOMER_ID,
       C.CUSTOMER_NAME
FROM CUSTOMER C
WHERE C.STATUS = 'ACTIVE'
AND EXISTS
(
    SELECT 1 FROM ORDERS O
    WHERE O.CUSTOMER_ID = C.CUSTOMER_ID
    AND O.ORDER_DATE >= DATE '2026-09-01'
    AND O.ORDER_DATE < DATE '2026-10-01'
    AND O.ORDER_STATUS = 'COMPLETED'
)
AND NOT EXISTS
(
    SELECT 1 FROM ORDERS O
    WHERE O.CUSTOMER_ID = C.CUSTOMER_ID
    AND O.ORDER_DATE >= DATE '2026-09-01'
    AND O.ORDER_DATE < DATE '2026-10-01'
    AND O.ORDER_STATUS = 'CANCELLED'
);

EXPLANATION:
You correctly used EXISTS and NOT EXISTS and correctly filtered ACTIVE customers. The major problem is that neither subquery is correlated with the current customer. They check whether ANY completed/cancelled order exists in September rather than orders belonging to the current customer.

EXACT MISTAKES:
1. Missing correlation in EXISTS: O.CUSTOMER_ID = C.CUSTOMER_ID
2. Missing correlation in NOT EXISTS: O.CUSTOMER_ID = C.CUSTOMER_ID
3. Prefer the half-open September date range.

WHY THIS MISTAKE HAPPENED:
You remembered the EXISTS / NOT EXISTS structure, but missed the parent-child correlation.

KEY PATTERN / LESSON:
EXISTS and NOT EXISTS normally require the child row to be correlated to the current outer parent row.

Q2 — CONDITIONAL AGGREGATION + HAVING
RESULT: WRONG

YOUR ANSWER:
WITH SALE__SUMMARY(
SELECT PRODUCT_ID , 
COUNT(*) AS TOTAL_TRANSACTIONS ,
SUM(CASE WHEN STATUS = 'COMPLETED' THEN 1 ELSE 0 END) AS COMPLETED_TRANSACTIONS,
SUM(CASE WHEN STATUS = 'COMPLETED' THEN AMOUNT ELSE 0 END) AS COMPLETED_AMOUNT,
SUM(CASE WHEN STATUS = 'CANCELLED' THEN 1 ELSE 0 END) AS CANCELLED_TRANSACTIONS
FROM SALES 
WHERE 
SALE_DATE >= TO_DATE('01-SEP-2026','DD-MON-RRRR') AND 
SALE_DATE <= TO_DATE('30-SEP-2026','DD-MON-RRRR') 
GROUP BY PRODUCT_ID
HAVING 
COUNT(*) >=50 AND 
SUM(CASE WHEN STATUS = 'COMPLETED' THEN 1 ELSE 0 END)>=40 AND 
SUM(CASE WHEN STATUS = 'COMPLETED' THEN AMOUNT ELSE 0 END) > 500000 AND 
SUM(CASE WHEN STATUS = 'CANCELLED' THEN 1 ELSE 0 END) = 0)

SELECT P.PRODUCT_ID,
P.PRODUCT_NAME,
SS.TOTAL_TRANSACTIONS,
SS.COMPLETED_TRANSACTIONS,
SS.COMPLETED_AMOUNT,
SS.CANCELLED_TRANSACTIONS FROM PRODUCT P JOIN SALE__SUMMARY SS
ON P.PRODUCT_ID = P.PRODUCT_ID
WHERE P.STATUS = 'ACTIVE';

CORRECT ANSWER:
WITH SALE_SUMMARY AS
(
    SELECT PRODUCT_ID,
           COUNT(*) AS TOTAL_TRANSACTIONS,
           SUM(CASE WHEN STATUS = 'COMPLETED' THEN 1 ELSE 0 END) AS COMPLETED_TRANSACTIONS,
           SUM(CASE WHEN STATUS = 'COMPLETED' THEN AMOUNT ELSE 0 END) AS COMPLETED_AMOUNT,
           SUM(CASE WHEN STATUS = 'CANCELLED' THEN 1 ELSE 0 END) AS CANCELLED_TRANSACTIONS
    FROM SALES
    WHERE SALE_DATE >= DATE '2026-09-01'
    AND SALE_DATE < DATE '2026-10-01'
    GROUP BY PRODUCT_ID
    HAVING COUNT(*) >= 50
    AND SUM(CASE WHEN STATUS = 'COMPLETED' THEN 1 ELSE 0 END) >= 40
    AND SUM(CASE WHEN STATUS = 'COMPLETED' THEN AMOUNT ELSE 0 END) > 500000
    AND SUM(CASE WHEN STATUS = 'CANCELLED' THEN 1 ELSE 0 END) = 0
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
WHERE P.STATUS = 'ACTIVE';

EXPLANATION:
Your conditional aggregation and HAVING logic are conceptually correct. The major problem is the final JOIN condition.

EXACT MISTAKES:
1. Invalid CTE syntax: WITH SALE__SUMMARY( should be WITH SALE_SUMMARY AS (
2. Wrong JOIN condition: P.PRODUCT_ID = P.PRODUCT_ID should be P.PRODUCT_ID = SS.PRODUCT_ID
3. The wrong join condition can multiply every product against every summary row.
4. Prefer the half-open September date range.

WHY THIS MISTAKE HAPPENED:
The aggregation stage was mostly correct. The error occurred while connecting the aggregated result back to PRODUCT.

KEY PATTERN / LESSON:
After creating an aggregated CTE, verify that the JOIN connects the key from the left table to the corresponding key from the CTE.

Q3 — LAG() + CTE + BUSINESS CONDITION
RESULT: WRONG

YOUR ANSWER:
WITH LAST_2_SAL AS (
SELECT EMP_ID,SALARY,RN FROM
(SELECT EMP_ID,SALARY,EFFECTIVE_DATE,
ROW_NUMBER() OVER(PARTITION BY EMP_ID ORDER BY EFFECTIVE_DATE DESC) AS RN FROM EMPLOYEE_SALARY)
WHERE RN <= 2)

SELECT EMP_ID,SALARY AS LATEST_SALARY, LAG(SALARY) OVER(PARTITION BY EMP_ID ORDER BY RN) AS PREVIOUS_SALARY
(SALARY - LAG(SALARY) OVER(PARTITION BY EMP_ID ORDER BY RN)) AS SALARY_INCREASE
FROM LAST_2_SAL;

CORRECT ANSWER:
WITH SALARY_HISTORY AS
(
    SELECT EMP_ID,
           SALARY,
           EFFECTIVE_DATE,
           LAG(SALARY) OVER
           (PARTITION BY EMP_ID ORDER BY EFFECTIVE_DATE) AS PREVIOUS_SALARY,
           ROW_NUMBER() OVER
           (PARTITION BY EMP_ID ORDER BY EFFECTIVE_DATE DESC) AS RN
    FROM EMPLOYEE_SALARY
),
LATEST_SALARY AS
(
    SELECT EMP_ID,
           SALARY AS LATEST_SALARY,
           PREVIOUS_SALARY
    FROM SALARY_HISTORY
    WHERE RN = 1
)
SELECT EMP_ID,
       LATEST_SALARY,
       PREVIOUS_SALARY,
       LATEST_SALARY - PREVIOUS_SALARY AS SALARY_INCREASE
FROM LATEST_SALARY
WHERE PREVIOUS_SALARY IS NOT NULL;

EXPLANATION:
Your idea of limiting to the latest two records is reasonable, but the LAG logic and final filtering are incomplete.

EXACT MISTAKES:
1. Missing comma before SALARY_INCREASE.
2. You do not filter to RN = 1, so both latest and previous rows can remain.
3. Ordering LAG by RN makes the latest row RN=1 have no previous row. It is cleaner to calculate LAG over EFFECTIVE_DATE first, then select the latest row.
4. Employees with only one salary record must be excluded using PREVIOUS_SALARY IS NOT NULL.
5. The final latest-vs-previous comparison is not completed at one row per employee.

WHY THIS MISTAKE HAPPENED:
You recognized that only the latest two records matter, but filtered the history before establishing the LAG relationship.

KEY PATTERN / LESSON:
For latest-vs-previous: FULL HISTORY → LAG() → identify latest row → RN=1 → compare.

Q4 — MULTI-STAGE CTE + TOP-N PER GROUP
RESULT: WRONG

YOUR ANSWER:
WITH SALE_SUMMARY AS
(SELECT STORE_ID,PRODUCT_ID,SUM(CASE WHEN STATUS = 'COMPLETED' THEN AMOUNT ELSE 0 END) AS TOTAL_SALES_AMOUNT
FROM SALES 
WHERE 
SALE_DATE >= TO_DATE('01-SEP-2026','DD-MON-RRRR') AND 
SALE_DATE <= TO_DATE('30-SEP-2026','DD-MON-RRRR') 
GROUP BY STORE_ID,PRODUCT_ID),
SAL_RNK AS 
(SELECT STORE_ID,PRODUCT_ID,TOTAL_SALES_AMOUNT , 
DENSE_RANK() OVER(PARTITION BY STORE_ID,PRODUCT_ID ORDER BY TOTAL_SALES_AMOUNT DESC) AS SALES_RANK
FROM  SALE_SUMMARY)

SELECT S.STORE_ID,S.STORE_NAME
SR.PRODUCT_ID,SR.TOTAL_SALES_AMOUNT
,SR.SALES_RANK FROM STORE S JOIN SAL_RNK SR
ON S.STORE_ID = SR.STORE_ID
WHERE SR.SALES_RANK <= 2;

CORRECT ANSWER:
WITH SALE_SUMMARY AS
(
    SELECT STORE_ID,
           PRODUCT_ID,
           SUM(AMOUNT) AS TOTAL_SALES_AMOUNT
    FROM SALES
    WHERE SALE_DATE >= DATE '2026-09-01'
    AND SALE_DATE < DATE '2026-10-01'
    AND STATUS = 'COMPLETED'
    GROUP BY STORE_ID, PRODUCT_ID
),
SAL_RNK AS
(
    SELECT STORE_ID,
           PRODUCT_ID,
           TOTAL_SALES_AMOUNT,
           DENSE_RANK() OVER
           (PARTITION BY STORE_ID ORDER BY TOTAL_SALES_AMOUNT DESC) AS SALES_RANK
    FROM SALE_SUMMARY
)
SELECT S.STORE_ID,
       S.STORE_NAME,
       SR.PRODUCT_ID,
       SR.TOTAL_SALES_AMOUNT,
       SR.SALES_RANK
FROM STORE S
JOIN SAL_RNK SR
ON S.STORE_ID = SR.STORE_ID
WHERE SR.SALES_RANK <= 2;

EXPLANATION:
Your first stage correctly aggregates at STORE_ID + PRODUCT_ID. The ranking stage has the wrong partition.

EXACT MISTAKES:
1. Wrong RANK partition: PARTITION BY STORE_ID, PRODUCT_ID. Correct: PARTITION BY STORE_ID.
2. COMPLETED filtering is cleaner in WHERE followed by SUM(AMOUNT).
3. Missing comma after S.STORE_NAME.
4. Prefer the half-open September date range.

WHY THIS MISTAKE HAPPENED:
You understood the aggregate-then-rank architecture, but included PRODUCT_ID in PARTITION BY. That causes each product to rank against itself.

KEY PATTERN / LESSON:
For TOP-N products per store: PARTITION BY STORE_ID ORDER BY TOTAL_SALES_AMOUNT DESC.

Q5 — LEAD-LEVEL RECONCILIATION + MULTIPLE GRAINS
RESULT: WRONG

YOUR ANSWER:
WITH ORDER_SUMMARY AS 
(
SELECT 
CUSTOMER_ID,
COUNT(*) AS COMPLETED_ORDER_COUNT,
SUM(AMOUNT) AS TOTAL_ORDER_AMOUNT
FROM ORDERS
WHERE 
ORDER_DATE >= TO_DATE('01-SEP-2026','DD-MON-RRRR') AND 
ORDER_DATE <= TO_DATE('30-SEP-2026','DD-MON-RRRR') 
AND STATUS = 'COMPLETED'
HAVING
COUNT(*) >= 5
AND SUM(AMOUNT) > 50000
),

PAYMENT_SUMMARY(
	SELECT O.ORDER_ID , O.CUSTOMER_ID ,
	SUM(P.PAYMENT_AMOUNT) AS TOTAL_PAID_AMOUNT
	FROM  ORDERS O JOIN PAYMENT P
	O.ORDER_ID = P.ORDER_ID
	WHERE 
	ORDER_DATE >= TO_DATE('01-SEP-2026','DD-MON-RRRR') AND 
	ORDER_DATE <= TO_DATE('30-SEP-2026','DD-MON-RRRR') 
	AND STATUS = 'COMPLETED'
	GROUP BY O.ORDER_ID , O.CUSTOMER_ID 
),
UNPAD_ORDER(
	SELECT O.ORDER_ID , O.CUSTOMER_ID ,
	COUNT(*) AS UNPAID_ORDER_COUNT
	FROM  ORDERS O JOIN PAYMENT P
	O.ORDER_ID = P.ORDER_ID
	WHERE 
	ORDER_DATE >= TO_DATE('01-SEP-2026','DD-MON-RRRR') AND 
	ORDER_DATE <= TO_DATE('30-SEP-2026','DD-MON-RRRR') 
	AND STATUS = 'COMPLETED'
	AND P.PAYMENT_AMOUNT =0
	GROUP BY O.ORDER_ID , O.CUSTOMER_ID 
)

SELECT C.CUSTOMER_ID,C.CUSTOMER_NAME,
COMPLETED_ORDER_COUNT,TOTAL_ORDER_AMOUNT
TOTAL_PAID_AMOUNT,UNPAID_ORDER_COUNT
,OUTSTANDING_AMOUNT FROM CUSTOMER C JOIN ORDER_SUMMARY OS
ON C.CUSTOMER_ID = OS.C.CUSTOMER_ID JOIN PAYMENT_SUMMARY PS
ON OS.CUSTOMER_ID = PS.CUSTOMER_ID JOIN UNPAD_ORDER UO
ON OS.CUSTOMER_ID = UO.CUSTOMER_ID;

CORRECT ANSWER:
WITH ORDER_SUMMARY AS
(
    SELECT O.CUSTOMER_ID,
           COUNT(*) AS COMPLETED_ORDER_COUNT,
           SUM(O.AMOUNT) AS TOTAL_ORDER_AMOUNT
    FROM ORDERS O
    WHERE O.ORDER_DATE >= DATE '2026-09-01'
    AND O.ORDER_DATE < DATE '2026-10-01'
    AND O.STATUS = 'COMPLETED'
    GROUP BY O.CUSTOMER_ID
    HAVING COUNT(*) >= 5
    AND SUM(O.AMOUNT) > 50000
),
PAYMENT_BY_ORDER AS
(
    SELECT O.ORDER_ID,
           O.CUSTOMER_ID,
           SUM(P.PAYMENT_AMOUNT) AS TOTAL_PAID_AMOUNT
    FROM ORDERS O
    LEFT JOIN PAYMENT P
    ON P.ORDER_ID = O.ORDER_ID
    AND P.STATUS = 'SUCCESS'
    WHERE O.ORDER_DATE >= DATE '2026-09-01'
    AND O.ORDER_DATE < DATE '2026-10-01'
    AND O.STATUS = 'COMPLETED'
    GROUP BY O.ORDER_ID, O.CUSTOMER_ID
),
PAYMENT_SUMMARY AS
(
    SELECT CUSTOMER_ID,
           SUM(NVL(TOTAL_PAID_AMOUNT,0)) AS TOTAL_PAID_AMOUNT,
           SUM(CASE WHEN NVL(TOTAL_PAID_AMOUNT,0) = 0 THEN 1 ELSE 0 END) AS UNPAID_ORDER_COUNT
    FROM PAYMENT_BY_ORDER
    GROUP BY CUSTOMER_ID
)
SELECT C.CUSTOMER_ID,
       C.CUSTOMER_NAME,
       OS.COMPLETED_ORDER_COUNT,
       OS.TOTAL_ORDER_AMOUNT,
       NVL(PS.TOTAL_PAID_AMOUNT,0) AS TOTAL_PAID_AMOUNT,
       NVL(PS.UNPAID_ORDER_COUNT,0) AS UNPAID_ORDER_COUNT,
       OS.TOTAL_ORDER_AMOUNT - NVL(PS.TOTAL_PAID_AMOUNT,0) AS OUTSTANDING_AMOUNT
FROM CUSTOMER C
JOIN ORDER_SUMMARY OS
ON C.CUSTOMER_ID = OS.CUSTOMER_ID
LEFT JOIN PAYMENT_SUMMARY PS
ON OS.CUSTOMER_ID = PS.CUSTOMER_ID
WHERE C.STATUS = 'ACTIVE'
AND NVL(PS.TOTAL_PAID_AMOUNT,0) < OS.TOTAL_ORDER_AMOUNT
AND NVL(PS.UNPAID_ORDER_COUNT,0) >= 1;

EXPLANATION:
This was the Lead-level question. You correctly recognized the need for separate order, payment, and unpaid-order stages, but the grain transition was incomplete.

EXACT MISTAKES:
1. Missing GROUP BY CUSTOMER_ID in ORDER_SUMMARY.
2. PAYMENT_SUMMARY remains at ORDER grain instead of becoming CUSTOMER grain.
3. Missing ON before O.ORDER_ID = P.ORDER_ID.
4. Missing P.STATUS = 'SUCCESS'.
5. P.PAYMENT_AMOUNT = 0 does not correctly identify an unpaid order when there can be multiple payments.
6. INNER JOIN PAYMENT excludes orders with no successful payment; use LEFT JOIN.
7. UNPAID_ORDER_COUNT must be calculated after total successful payment is aggregated per order.
8. Missing final ACTIVE customer filter.
9. Missing final TOTAL_PAID_AMOUNT < TOTAL_ORDER_AMOUNT condition.
10. Incorrect alias OS.C.CUSTOMER_ID.
11. Missing commas and OUTSTANDING_AMOUNT calculation.
12. CTE syntax should use AS.

WHY THIS MISTAKE HAPPENED:
You understood that Q5 requires multiple stages, but you stopped at ORDER grain and did not complete the transition back to CUSTOMER grain.

The correct progression is:
ORDER → payment total per ORDER → identify unpaid orders → CUSTOMER summary → final customer reconciliation.

KEY PATTERN / LESSON:
PAYMENT_BY_ORDER = 1 row / ORDER.
PAYMENT_SUMMARY = 1 row / CUSTOMER.
FINAL RESULT = 1 row / CUSTOMER.

For an unpaid order, test total successful payment for the order = 0, not a single raw payment row = 0.

==================================================
DAY 18 FINAL RESULT
==================================================

Q1 → 🔴 WRONG
Q2 → 🔴 WRONG
Q3 → 🔴 WRONG
Q4 → 🔴 WRONG
Q5 → 🔴 WRONG

FULLY CORRECT:
0

PARTIALLY CORRECT:
0

WRONG:
5

STRICT SCORE:
0 / 5 = 0%

EFFECTIVE ACCURACY:
Correct = 0
Partial = 0 × 0.5 = 0
Wrong = 0

0 / 5 = 0%

==================================================
DAY 18 — CORE LESSON
==================================================

The biggest issue today:

QUERY GRAIN + CORRELATION

Q1:
EXISTS / NOT EXISTS → missing correlation

Q2:
Conditional aggregation → mostly understood
JOIN condition → incorrect

Q3:
LAG + latest record → concept partially understood
Latest-vs-previous comparison → not completed correctly

Q4:
Aggregation → correct
TOP-N partition → wrong grain

Q5:
Multi-stage reconciliation → correct direction
ORDER → CUSTOMER grain transition → not completed

==================================================
DAY 18 — PRIORITY LESSONS
==================================================

1. CORRELATION
For EXISTS / NOT EXISTS, connect the child to the current parent row.

2. JOIN PRECISION
Never write P.ID = P.ID when the intended join is between two tables.

3. LAG() + LATEST RECORD
FULL HISTORY → LAG() → identify latest row → RN=1 → compare.

4. TOP-N PER GROUP
TOP 2 PRODUCTS PER STORE → PARTITION BY STORE_ID.

5. MULTI-GRAIN THINKING
PAYMENT_BY_ORDER → 1 row / ORDER.
PAYMENT_SUMMARY → 1 row / CUSTOMER.
FINAL → 1 row / CUSTOMER.

6. UNPAID ORDER
UNPAID means total SUCCESS payment for the order = 0.

7. LEFT JOIN FOR MISSING CHILD RECORDS
If orders without payments must survive, use LEFT JOIN.

8. SQL SYNTAX PRECISION
Recurring issues:
* Missing commas
* Missing ON
* Wrong aliases
* Missing GROUP BY
* Invalid CTE syntax
* Wrong JOIN condition

==================================================
# CUMULATIVE STATUS THROUGH DAY 18
==================================================

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

### CUMULATIVE

* **Correct: 34**
* **Partial: 34**
* **Wrong: 21**
* **Questions: 90**

> The historical Day 1–7 baseline contains a one-question classification-count inconsistency, so the category counts do not sum to the 90-question total. The historical baseline is preserved rather than silently changed.

### CUMULATIVE STRICT SCORE

**34 / 90 = 37.78%**

### CUMULATIVE EFFECTIVE ACCURACY

**(34 + 34 × 0.5) / 90 = 56.67%**

==================================================
NO REWRITE PRACTICE
==================================================
