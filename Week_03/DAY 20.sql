SQL CHALLENGE — DAY 20
YOUR ANSWER + CORRECT ANSWER

============================================================
Q1 — CUSTOMER MONTHLY ACTIVITY
============================================================

RESULT: ✗ INCORRECT

## YOUR ANSWER:

WITH AS ORDER_SUMMARY AS (
SELECT 
	O.CUSTOMER_ID , O.STORE_ID , COUNT(*) AS STORE_COUNT,
	SUM(CASE WHEN O.STATUS = 'COMPLETED' THEN 1 ELSE 0 END) AS COMPLETED_ORDER_COUNT ,
	SUM(CASE WHEN O.STATUS = 'COMPLETED' THEN O.AMOUNT ELSE 0 END) AS TOTAL_COMPLETED_AMOUNT ,
	SUM(CASE WHEN O.STATUS = 'CANCELLED' THEN 1 ELSE 0 END) AS CANCELLED_ORDER_COUNT
FROM 
	ORDERS O 
WHERE 
	O.ORDER_DATE >= TO_DATE('01-SEP-2026','DD-MON-RRRR') AND 
	O.ORDER_DATE <= TO_DATE('30-SEP-2026','DD-MON-RRRR') 
GROUP BY 
	O.CUSTOMER_ID , O.STORE_ID 
)

SELECT 
	C.CUSTOMER_ID,
	C.CUSTOMER_NAME,
	OS.COMPLETED_ORDER_COUNT,
	OS.TOTAL_COMPLETED_AMOUNT,
	OS.STORE_COUNT
FROM 
	CUSTOMER C 
LEFT JOIN 
	ORDER_SUMMARY OS 
ON 
	C.CUSTOMER_ID = OS.CUSTOMER_ID
	AND OS.STORE_COUNT >= 2
	AND OS.COMPLETED_ORDER_COUNT >= 5
	AND OS.TOTAL_COMPLETED_AMOUNT > 100000
	AND OS.CANCELLED_ORDER_COUNT = 0
WHERE 
	C.STATUS = 'ACTIVE';

## CORRECT ANSWER:

WITH ORDER_SUMMARY AS (
    SELECT O.CUSTOMER_ID,
           COUNT(CASE WHEN O.STATUS = 'COMPLETED' THEN 1 END) AS COMPLETED_ORDER_COUNT,
           SUM(CASE WHEN O.STATUS = 'COMPLETED' THEN O.AMOUNT ELSE 0 END) AS TOTAL_COMPLETED_AMOUNT,
           COUNT(DISTINCT CASE WHEN O.STATUS = 'COMPLETED' THEN O.STORE_ID END) AS STORE_COUNT,
           SUM(CASE WHEN O.STATUS = 'CANCELLED' THEN 1 ELSE 0 END) AS CANCELLED_ORDER_COUNT
    FROM ORDERS O
    WHERE O.ORDER_DATE >= DATE '2026-09-01'
      AND O.ORDER_DATE < DATE '2026-10-01'
    GROUP BY O.CUSTOMER_ID
)
SELECT C.CUSTOMER_ID,
       C.CUSTOMER_NAME,
       OS.COMPLETED_ORDER_COUNT,
       OS.TOTAL_COMPLETED_AMOUNT,
       OS.STORE_COUNT
FROM CUSTOMER C
JOIN ORDER_SUMMARY OS
  ON C.CUSTOMER_ID = OS.CUSTOMER_ID
WHERE C.STATUS = 'ACTIVE'
  AND OS.COMPLETED_ORDER_COUNT >= 5
  AND OS.TOTAL_COMPLETED_AMOUNT > 100000
  AND OS.STORE_COUNT >= 2
  AND OS.CANCELLED_ORDER_COUNT = 0;

## EXPLANATION:

Your main problem is the aggregation grain. You grouped by CUSTOMER_ID + STORE_ID, so each summary row represents one customer/store combination. COUNT(*) therefore counts orders, not stores.

The final requirement is one row per CUSTOMER. The summary must therefore be at CUSTOMER grain and use COUNT(DISTINCT STORE_ID).

You also repeated the LEFT JOIN + ON-filter mistake from earlier days.

## EXACT MISTAKES:

1. Wrong GROUP BY grain: CUSTOMER_ID + STORE_ID.
2. STORE_COUNT is not a store count.
3. Need COUNT(DISTINCT STORE_ID) for completed orders.
4. Final output must be one row per customer.
5. LEFT JOIN preserves non-qualifying customers.
6. Qualification conditions should be in WHERE.
7. `WITH AS ORDER_SUMMARY` is invalid syntax; use `WITH ORDER_SUMMARY AS`.
8. Date boundary is safer with `< DATE '2026-10-01'`.

## WHY THIS MISTAKE HAPPENED:

You recognized STORE_ID was needed but put it into GROUP BY instead of using it inside a distinct aggregate.

## KEY PATTERN / LESSON:

If final grain is CUSTOMER:

GROUP BY CUSTOMER_ID

Then calculate:

COUNT(DISTINCT STORE_ID)

A column needed for an aggregate does not automatically belong in GROUP BY.

============================================================
Q2 — PRODUCT SALES QUALIFICATION
============================================================

RESULT: ⚠ PARTIALLY CORRECT

## YOUR ANSWER:

WITH SALE_SUMMARY AS(
	SELECT 
		S.PRODUCT_ID , 
		COUNT(*) AS TOTAL_TRANSACTIONS,
		SUM(CASE WHEN STATUS = 'COMPLETED' THEN 1 ELSE 0 END)  AS COMPLETED_TRANSACTIONS,
		SUM(CASE WHEN STATUS = 'COMPLETED' THEN S.AMOUNT ELSE 0 END) AS COMPLETED_AMOUNT,
		SUM(CASE WHEN STATUS = 'CANCELLED' THEN 1 ELSE 0 END) AS CANCELLED_TRANSACTIONS 
	FROM 
		SALES S
	WHERE 
		S.SALE_DATE >= TO_DATE('01-SEP-2026','DD-MON-RRRR') AND
		S.SALE_DATE <= TO_DATE('30-SEP-2026','DD-MON-RRRR')
	GROUP BY 
		S.PRODUCT_ID
)

SELECT 
	P.PRODUCT_ID,
	P.PRODUCT_NAME,
	SS.TOTAL_TRANSACTIONS,
	SS.COMPLETED_TRANSACTIONS,
	(SS.COMPLETED_TRANSACTIONS / SS.TOTAL_TRANSACTIONS) * 100 AS COMPLETION_PERCENTAGE,
	SS.COMPLETED_AMOUNT
FROM 
	PRODUCT P LEFT JOIN SALE_SUMMARY SS
	ON P.PRODUCT_ID = SS.PRODUCT_ID
	AND SS.TOTAL_TRANSACTIONS >=200
	AND SS.COMPLETED_TRANSACTIONS >=150
	AND SS.COMPLETED_AMOUNT > 2000000
	AND SS.CANCELLED_TRANSACTIONS = 0
	AND (SS.COMPLETED_TRANSACTIONS / SS.TOTAL_TRANSACTIONS)/100 >= 80
WHERE
	P.STATUS = 'ACTIVE'; 

## CORRECT ANSWER:

WITH SALE_SUMMARY AS (
    SELECT S.PRODUCT_ID,
           COUNT(*) AS TOTAL_TRANSACTIONS,
           SUM(CASE WHEN S.STATUS = 'COMPLETED' THEN 1 ELSE 0 END) AS COMPLETED_TRANSACTIONS,
           SUM(CASE WHEN S.STATUS = 'COMPLETED' THEN S.AMOUNT ELSE 0 END) AS COMPLETED_AMOUNT,
           SUM(CASE WHEN S.STATUS = 'CANCELLED' THEN 1 ELSE 0 END) AS CANCELLED_TRANSACTIONS
    FROM SALES S
    WHERE S.SALE_DATE >= DATE '2026-09-01'
      AND S.SALE_DATE < DATE '2026-10-01'
    GROUP BY S.PRODUCT_ID
)
SELECT P.PRODUCT_ID,
       P.PRODUCT_NAME,
       SS.TOTAL_TRANSACTIONS,
       SS.COMPLETED_TRANSACTIONS,
       (SS.COMPLETED_TRANSACTIONS / SS.TOTAL_TRANSACTIONS) * 100 AS COMPLETION_PERCENTAGE,
       SS.COMPLETED_AMOUNT
FROM PRODUCT P
JOIN SALE_SUMMARY SS
  ON P.PRODUCT_ID = SS.PRODUCT_ID
WHERE P.STATUS = 'ACTIVE'
  AND SS.TOTAL_TRANSACTIONS >= 200
  AND SS.COMPLETED_TRANSACTIONS >= 150
  AND SS.COMPLETED_AMOUNT > 2000000
  AND SS.CANCELLED_TRANSACTIONS = 0
  AND (SS.COMPLETED_TRANSACTIONS / SS.TOTAL_TRANSACTIONS) * 100 >= 80;

## EXPLANATION:

Your aggregation and displayed percentage calculation are correct.

The percentage filter is wrong. You calculate percentage with `* 100` but filter with `/ 100`.

Also, the same LEFT JOIN + ON-filter issue appears again.

## EXACT MISTAKES:

1. Percentage filter uses `/100` instead of `*100`.
2. LEFT JOIN preserves non-qualifying products.
3. Aggregate qualification conditions should be in WHERE.
4. Date boundary is safer with `< DATE '2026-10-01'`.

## WHY THIS MISTAKE HAPPENED:

You correctly calculated the percentage but changed the mathematical expression when writing the condition.

## KEY PATTERN / LESSON:

Keep the calculation and filter identical:

(COMPLETED / TOTAL) * 100 >= 80

============================================================
Q3 — EMPLOYEE SALARY CHANGE
============================================================

RESULT: ⚠ PARTIALLY CORRECT

## YOUR ANSWER:

WITH 
	SALARY_SUMMARY 
AS
	(SELECT 
		EMP_ID,
		SALARY,
		RN
	FROM
		(SELECT 
			ES.EMP_ID,
			ES.SALARY,
			ROW_NUMBER() OVER(PARTITION BY ES.EMP_ID ORDER BY ES.EFFECTIVE_DATE DESC) RN
		FROM 
			EMPLOYEE_SALARY ES) 
	WHERE 
		RN <= 2
	),
SALARY_LAT AS (
	SELECT 
		SS.EMP_ID,
		LEAD(SS.SALARY) OVER(PARTITION BY SS.EMP_ID ORDER BY RN) AS PREVIOUS_SALARY,
		SS.SALARY AS LATEST_SALARY
	FROM 
		SALARY_SUMMARY SS)

SELECT 
	SL.EMP_ID,
	SL.PREVIOUS_SALARY,
	SL.LATEST_SALARY,
	(SL.LATEST_SALARY - SL.PREVIOUS_SALARY) AS SALARY_INCREASE,
	((SL.LATEST_SALARY - SL.PREVIOUS_SALARY)/SL.PREVIOUS_SALARY)*100 AS INCREASE_PERCENTAGE
FROM 
	SALARY_LAT SL
WHERE 
	SL.LATEST_SALARY > SL.PREVIOUS_SALARY
	AND((SL.LATEST_SALARY - SL.PREVIOUS_SALARY)/SL.PREVIOUS_SALARY)*100 >=20;

## CORRECT ANSWER:

WITH SALARY_SUMMARY AS (
    SELECT EMP_ID,
           SALARY,
           ROW_NUMBER() OVER (
               PARTITION BY EMP_ID
               ORDER BY EFFECTIVE_DATE DESC
           ) AS RN
    FROM EMPLOYEE_SALARY
),
SALARY_COMPARE AS (
    SELECT EMP_ID,
           RN,
           LEAD(SALARY) OVER (
               PARTITION BY EMP_ID
               ORDER BY RN
           ) AS PREVIOUS_SALARY,
           SALARY AS LATEST_SALARY
    FROM SALARY_SUMMARY
    WHERE RN <= 2
)
SELECT EMP_ID,
       PREVIOUS_SALARY,
       LATEST_SALARY,
       LATEST_SALARY - PREVIOUS_SALARY AS SALARY_INCREASE,
       ((LATEST_SALARY - PREVIOUS_SALARY) / PREVIOUS_SALARY) * 100 AS INCREASE_PERCENTAGE
FROM SALARY_COMPARE
WHERE RN = 1
  AND LATEST_SALARY > PREVIOUS_SALARY
  AND ((LATEST_SALARY - PREVIOUS_SALARY) / PREVIOUS_SALARY) * 100 < 20;

## EXPLANATION:

Your latest/previous salary logic is mostly correct. The major business-condition error is the threshold.

The question says the increase must be LESS THAN 20%. You used >= 20%, which selects the opposite group.

## EXACT MISTAKES:

1. Used `>= 20` instead of `< 20`.
2. Did not explicitly filter RN = 1 in the final result.
3. Duplicate EFFECTIVE_DATE values may require a deterministic tie-breaker.

## WHY THIS MISTAKE HAPPENED:

The SQL mechanics were mostly correct, but the English business condition was reversed.

## KEY PATTERN / LESSON:

Translate comparison words literally:

LESS THAN → `<`
GREATER THAN → `>`
AT LEAST → `>=`
AT MOST → `<=`

============================================================
Q4 — STORE TOP PRODUCT BY REVENUE
============================================================

RESULT: ⚠ PARTIALLY CORRECT

## YOUR ANSWER:

WITH SALE_SUMMARY AS (
SELECT 
	S.STORE_ID,
	S.PRODUCT_ID,
	SUM(CASE WHEN S.STATUS = 'COMPLETED' THEN AMOUNT ELSE 0 END) AS TOTAL_SALES_AMOUNT
FROM 
	SALES S
WHERE 
	S.SALE_DATE >= TO_DATE('01-SEP-2026','DD-MON-RRRR') AND
	S.SALE_DATE <= TO_DATE('30-SEP-2026','DD-MON-RRRR')
GROUP BY 
	S.STORE_ID,
	S.PRODUCT_ID),

SALARY_RNK AS(
SELECT 
	SS.STORE_ID,
	SS.PRODUCT_ID,
	SS.TOTAL_SALES_AMOUNT,
	DENSE_RANK() OVER(PARTITION BY SS.STORE_ID ORDER BY SS.TOTAL_SALES_AMOUNT DESC) AS RN
FROM 
	SALE_SUMMARY SS
)

SELECT 
	S.STORE_ID
	S.STORE_NAME
	SR.PRODUCT_ID
	SR.TOTAL_SALES_AMOUNT
FROM 
	STORE S LEFT JOIN SALARY_RNK SR
	ON S.STORE_ID = SR.STORE_ID
WHERE 
	SR.RN = 1;

## CORRECT ANSWER:

WITH SALE_SUMMARY AS (
    SELECT S.STORE_ID,
           S.PRODUCT_ID,
           SUM(S.AMOUNT) AS TOTAL_SALES_AMOUNT
    FROM SALES S
    WHERE S.SALE_DATE >= DATE '2026-09-01'
      AND S.SALE_DATE < DATE '2026-10-01'
      AND S.STATUS = 'COMPLETED'
    GROUP BY S.STORE_ID, S.PRODUCT_ID
),
SALES_RANK AS (
    SELECT STORE_ID,
           PRODUCT_ID,
           TOTAL_SALES_AMOUNT,
           DENSE_RANK() OVER (
               PARTITION BY STORE_ID
               ORDER BY TOTAL_SALES_AMOUNT DESC
           ) AS RN
    FROM SALE_SUMMARY
)
SELECT S.STORE_ID,
       S.STORE_NAME,
       SR.PRODUCT_ID,
       SR.TOTAL_SALES_AMOUNT
FROM STORE S
JOIN SALES_RANK SR
  ON S.STORE_ID = SR.STORE_ID
WHERE SR.RN = 1;

## EXPLANATION:

Your ranking logic is correct: aggregate STORE + PRODUCT, then rank within STORE.

The main issue is SQL syntax in the final SELECT: commas are missing after STORE_ID and STORE_NAME.

The CTE name `SALARY_RNK` is also incorrect semantically, although not a syntax error.

## EXACT MISTAKES:

1. Missing comma after `S.STORE_ID`.
2. Missing comma after `S.STORE_NAME`.
3. CTE name `SALARY_RNK` should describe sales ranking.
4. COMPLETED should preferably be filtered before aggregation.
5. Date boundary is safer with `< DATE '2026-10-01'`.

## WHY THIS MISTAKE HAPPENED:

The relational logic was correct, but the final SQL assembly was rushed.

## KEY PATTERN / LESSON:

Before submission, perform a SELECT-list syntax check. Every selected column except the final one needs a comma.

============================================================
Q5 — LEAD-LEVEL CUSTOMER RECONCILIATION
============================================================

RESULT: ✗ WRONG

## YOUR ANSWER:

WITH ORDER_SUMMARY AS
(
	SELECT 
		O.CUSTOMER_ID,
		SUM(CASE WHEN O.STATUS = 'COMPLETED' THEN 1 ELSE 0 END) AS COMPLETED_ORDER_COUNT,
		SUM(CASE WHEN O.STATUS = 'COMPLETED' THEN O.AMOUNT ELSE 0 END) AS TOTAL_ORDER_AMOUNT
	FROM 
		ORDERS O
	WHERE 
		O.ORDER_DATE >= TO_DATE('01-SEP-2026','DD-MON-RRRR') AND 
		O.ORDER_DATE <= TO_DATE('30-SEP-2026','DD-MON-RRRR') 
	GROUP BY 
		O.CUSTOMER_ID
),

PAYMENT_PAID AS 
(
	SELECT 
		O.CUSTOMER_ID,
		O.ORDER_ID,
		SUM(CASE WHEN O.STATUS = 'COMPLETED' THEN O.AMOUNT ELSE 0 END) AS TOTAL_ORDER_AMOUNT,
		SUM(CASE WHEN P.STATUS = 'SUCCESS' THEN P.PAYMENT_AMOUNT ELSE 0 END) AS TOTAL_PAID_AMOUNT
	FROM 
		PAYMENT P RIGHT JOIN ORDERS O
		ON P.ORDER_ID = O.ORDER_ID
	WHERE 
		O.ORDER_DATE >= TO_DATE('01-SEP-2026','DD-MON-RRRR') AND 
		O.ORDER_DATE <= TO_DATE('30-SEP-2026','DD-MON-RRRR') 
	GROUP BY 
		O.CUSTOMER_ID,O.ORDER_ID
),

PAYMENT_SUMMARY AS
(
	SELECT 
		PP.CUSTOMER_ID,
		PP.ORDER_ID,
		SUM(CASE WHEN PP.TOTAL_PAID_AMOUNT = TOTAL_ORDER_AMOUNT THEN 1 ELSE 0 END) PAID_ORDER_COUNT,
		SUM(CASE WHEN PP.TOTAL_PAID_AMOUNT < TOTAL_ORDER_AMOUNT THEN 1 ELSE 0 END) PARTIALLY_PAID_ORDER_COUNT,
		SUM(CASE WHEN PP.TOTAL_PAID_AMOUNT = 0 THEN 1 ELSE 0 END) UNPAID_ORDER_COUNT
	FROM 
		PAYMENT_PAID PP
	GROUP BY 
	    PP.CUSTOMER_ID,
		PP.ORDER_ID
)

SELECT 
	C.CUSTOMER_ID,
	C.CUSTOMER_NAME,
	OS.COMPLETED_ORDER_COUNT,
	OS.TOTAL_ORDER_AMOUNT,
	PD.TOTAL_PAID_AMOUNT,
	PS.UNPAID_ORDER_COUNT,
	PS.PARTIALLY_PAID_ORDER_COUNT,
	PS.PAID_ORDER_COUNT,
	(PD.TOTAL_PAID_AMOUNT - OS.TOTAL_ORDER_AMOUNT) OUTSTANDING_AMOUNT
FROM 
	CUSTOMER C LEFT JOIN ORDER_SUMMARY OS
	ON C.CUSTOMER_ID = OS.CUSTOMER_ID 
	AND OS.COMPLETED_ORDER_COUNT >= 5
	AND OS.TOTAL_ORDER_AMOUNT > 100000
	LEFT JOIN PAYMENT_PAID PD
	ON OS.CUSTOMER_ID = PD.CUSTOMER_ID 
	AND OS.TOTAL_ORDER_AMOUNT < PD.TOTAL_PAID_AMOUNT
	LEFT JOIN PAYMENT_SUMMARY PS
	ON PD.CUSTOMER_ID = PS.CUSTOMER_ID
	AND PS.PARTIALLY_PAID_ORDER_COUNT >=1
	AND PS.UNPAID_ORDER_COUNT >= 2
	AND PS.PAID_ORDER_COUNT >= 3
WHERE
	C.STATUS = 'ACTIVE';

## CORRECT ANSWER:

WITH ORDER_PAYMENT AS (
    SELECT O.ORDER_ID,
           O.CUSTOMER_ID,
           O.AMOUNT AS ORDER_AMOUNT,
           SUM(CASE WHEN P.STATUS = 'SUCCESS'
                    THEN P.PAYMENT_AMOUNT ELSE 0 END) AS TOTAL_PAID_AMOUNT
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
           SUM(TOTAL_PAID_AMOUNT) AS TOTAL_PAID_AMOUNT,
           SUM(CASE WHEN TOTAL_PAID_AMOUNT = 0 THEN 1 ELSE 0 END) AS UNPAID_ORDER_COUNT,
           SUM(CASE WHEN TOTAL_PAID_AMOUNT > 0
                     AND TOTAL_PAID_AMOUNT < ORDER_AMOUNT
                    THEN 1 ELSE 0 END) AS PARTIALLY_PAID_ORDER_COUNT,
           SUM(CASE WHEN TOTAL_PAID_AMOUNT >= ORDER_AMOUNT
                    THEN 1 ELSE 0 END) AS PAID_ORDER_COUNT
    FROM ORDER_PAYMENT
    GROUP BY CUSTOMER_ID
)
SELECT C.CUSTOMER_ID,
       C.CUSTOMER_NAME,
       CS.COMPLETED_ORDER_COUNT,
       CS.TOTAL_ORDER_AMOUNT,
       CS.TOTAL_PAID_AMOUNT,
       CS.UNPAID_ORDER_COUNT,
       CS.PARTIALLY_PAID_ORDER_COUNT,
       CS.PAID_ORDER_COUNT,
       CS.TOTAL_ORDER_AMOUNT - CS.TOTAL_PAID_AMOUNT AS OUTSTANDING_AMOUNT
FROM CUSTOMER C
JOIN CUSTOMER_SUMMARY CS
  ON C.CUSTOMER_ID = CS.CUSTOMER_ID
WHERE C.STATUS = 'ACTIVE'
  AND CS.COMPLETED_ORDER_COUNT >= 5
  AND CS.TOTAL_ORDER_AMOUNT > 100000
  AND CS.TOTAL_PAID_AMOUNT < CS.TOTAL_ORDER_AMOUNT
  AND CS.UNPAID_ORDER_COUNT >= 2
  AND CS.PARTIALLY_PAID_ORDER_COUNT >= 1
  AND CS.PAID_ORDER_COUNT >= 3;

## EXPLANATION:

This question requires:

ORDER GRAIN
→ classify each completed order
→ CUSTOMER GRAIN
→ apply final customer conditions

Your query does not maintain that structure.

PAYMENT_PAID is at ORDER grain, but it is joined directly to customer-level ORDER_SUMMARY. That can create multiple rows per customer.

You also have several business-condition errors.

## EXACT MISTAKES:

1. PAYMENT_PAID does not restrict to COMPLETED orders.
2. Payment information remains at order grain while being joined to customer-level data.
3. No customer-level SUM of successful payments.
4. `OS.TOTAL_ORDER_AMOUNT < PD.TOTAL_PAID_AMOUNT` is the opposite of the requirement.
5. OUTSTANDING_AMOUNT is reversed. It should be ORDER - PAID.
6. PAID classification uses equality only; requirement is payment >= order amount.
7. PARTIALLY PAID requires payment > 0 and payment < order amount.
8. Customer-level conditions are placed in JOIN conditions.
9. LEFT JOIN can preserve non-qualifying customers.
10. Multiple payments per order must be aggregated before classification.
11. The query can produce multiple rows per customer.
12. Required final customer grain is not maintained.

## WHY THIS MISTAKE HAPPENED:

You tried to solve CUSTOMER → ORDERS → PAYMENT in one join structure.

The correct approach is hierarchical:

1. One row per completed order.
2. Calculate successful payment total for that order.
3. Classify the order.
4. Aggregate those classifications to customer.
5. Apply customer-level filters.

## KEY PATTERN / LESSON:

For reconciliation:

ORDER GRAIN
→ PAYMENT TOTAL PER ORDER
→ ORDER CLASSIFICATION
→ CUSTOMER GRAIN
→ FINAL FILTER

This is a major Lead-level SQL pattern.

============================================================
DAY 20 FINAL RESULT
============================================================

FULLY CORRECT: 0
PARTIALLY CORRECT: 3
WRONG: 2

STRICT SCORE:
0 / 5 = 0.00%

EFFECTIVE ACCURACY:
(0 + 3 × 0.5) / 5 = 30.00%

DAY 20 — CORE LESSON

You generally understand the business requirements, but your SQL grain still frequently does not match the required result grain.

The strongest example is Q5:

CUSTOMER → ORDERS → PAYMENT

You must control the ORDER grain before rolling the result to CUSTOMER grain.

DAY 20 — PRIORITY LESSONS

1. Final output grain must be fixed before GROUP BY.
2. GROUP BY columns determine the row grain.
3. Use COUNT(DISTINCT ...) when counting entities across another dimension.
4. Do not put final qualification filters inside LEFT JOIN ON conditions.
5. Keep percentage calculation and percentage filter mathematically identical.
6. Translate comparison words literally: LESS THAN = <, AT LEAST = >=.
7. Window partition and aggregation grain are different concepts.
8. Pre-aggregate one-to-many relationships before joining.
9. OUTSTANDING = ORDER - PAID.
10. Always perform a final syntax + grain + business-condition check.

NO REWRITE PRACTICE

============================================================
# CUMULATIVE STATUS THROUGH DAY 20
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

### Day 20

* Correct: 0
* Partial: 3
* Wrong: 2

### CUMULATIVE

* **Correct: 34**
* **Partial: 41**
* **Wrong: 24**
* **Questions: 100**

> The historical Day 1–7 baseline contains a one-question classification-count inconsistency, so the category counts do not sum to the 100-question total. The historical baseline is preserved rather than silently changed.

### CUMULATIVE STRICT SCORE

**34 / 100 = 34.00%**

### CUMULATIVE EFFECTIVE ACCURACY

**(34 + 41 × 0.5) / 100 = 54.50%**
