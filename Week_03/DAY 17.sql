==================================================
SQL CHALLENGE — DAY 17
YOUR ANSWER + CORRECT ANSWER
==================================================

==================================================
Q1 — CORRELATED SUBQUERY + NULL
==================================================

RESULT:
🟡 PARTIALLY CORRECT

## YOUR ANSWER:

SELECT CUSTOMER_ID,CUSTOMER_NAME, (SELECT SUM(AMOUNT) FROM ORDERS O
WHERE ORDER_DATE >= DATE'01-SEP-2026' AND
ORDER_DATE <= DATE'30-SEP-2026'
AND ORDER_STATUS = 'COMPLETED' AND O.CUSTOMER_ID = C.CUSTOMER_ID) AS TOTAL_ORDER_AMOUNT
FROM CUSTOMER C
WHERE 
(SELECT SUM(AMOUNT) FROM ORDERS O
WHERE ORDER_DATE >= DATE'01-SEP-2026' AND
ORDER_DATE <= DATE'30-SEP-2026'
AND ORDER_STATUS = 'COMPLETED' AND O.CUSTOMER_ID = C.CUSTOMER_ID)>
(SELECT AVG(AMOUNT) FROM ORDERS 
WHERE ORDER_DATE >= DATE'01-SEP-2026' AND
ORDER_DATE <= DATE'30-SEP-2026'
AND ORDER_STATUS = 'COMPLETED')

## CORRECT ANSWER:

SELECT C.CUSTOMER_ID,
       C.CUSTOMER_NAME,
       (SELECT SUM(O.AMOUNT)
        FROM ORDERS O
        WHERE O.CUSTOMER_ID = C.CUSTOMER_ID
        AND O.ORDER_DATE >= DATE '2026-09-01'
        AND O.ORDER_DATE < DATE '2026-10-01'
        AND O.ORDER_STATUS = 'COMPLETED') AS TOTAL_ORDER_AMOUNT
FROM CUSTOMER C
WHERE C.STATUS = 'ACTIVE'
AND (SELECT SUM(O.AMOUNT)
     FROM ORDERS O
     WHERE O.CUSTOMER_ID = C.CUSTOMER_ID
     AND O.ORDER_DATE >= DATE '2026-09-01'
     AND O.ORDER_DATE < DATE '2026-10-01'
     AND O.ORDER_STATUS = 'COMPLETED')
    >
    (SELECT AVG(O.AMOUNT)
     FROM ORDERS O
     WHERE O.ORDER_DATE >= DATE '2026-09-01'
     AND O.ORDER_DATE < DATE '2026-10-01'
     AND O.ORDER_STATUS = 'COMPLETED');

## EXPLANATION:

Your overall correlated-subquery design is correct.

You correctly identified:

CUSTOMER
→ correlated subquery
→ customer-level SUM
→ compare against overall AVG

You also correctly used:

O.CUSTOMER_ID = C.CUSTOMER_ID

to correlate the inner query with the outer customer.

The main missing requirement is:

C.STATUS = 'ACTIVE'

The question specifically asked for ACTIVE customers.

## EXACT MISTAKES:

1. Missing ACTIVE customer filter

You need:

WHERE C.STATUS = 'ACTIVE'

2. Date-range precision

You used:

ORDER_DATE >= DATE'01-SEP-2026'
AND ORDER_DATE <= DATE'30-SEP-2026'

Preferred Oracle pattern:

ORDER_DATE >= DATE '2026-09-01'
AND ORDER_DATE < DATE '2026-10-01'

This is safer when ORDER_DATE contains a time component.

## WHY THIS MISTAKE HAPPENED:

The correlated-subquery logic was understood correctly, but you focused on the aggregation and comparison and missed one condition from the outer table.

## KEY PATTERN / LESSON:

For correlated subqueries:

OUTER TABLE
→ apply outer-table business filters

CORRELATED SUBQUERY
→ calculate current-row-specific value

NON-CORRELATED SUBQUERY
→ calculate comparison benchmark

Also remember:

SUM(...) > AVG(...)

will not return TRUE when the SUM is NULL, so customers with no matching orders are naturally excluded.


==================================================
Q2 — NOT EXISTS
==================================================

RESULT:
🔴 WRONG

## YOUR ANSWER:

SELECT PRODUCT_ID,PRODUCT_NAME FROM PRODUCT 
WHERE NOT EXISTS(SELECT 1 FROM SALES WHERE 
SALE_DATE >= DATE'01-SEP-2026' AND 
SALE_DATE <= DATE'30-SEP-2026' AND STATUS = 'COMPLETED')
AND STATUS = 'ACTIVE';

## CORRECT ANSWER:

SELECT P.PRODUCT_ID,
       P.PRODUCT_NAME
FROM PRODUCT P
WHERE P.STATUS = 'ACTIVE'
AND NOT EXISTS
(
    SELECT 1
    FROM SALES S
    WHERE S.PRODUCT_ID = P.PRODUCT_ID
    AND S.SALE_DATE >= DATE '2026-09-01'
    AND S.SALE_DATE < DATE '2026-10-01'
    AND S.STATUS = 'COMPLETED'
);

## EXPLANATION:

Your NOT EXISTS structure is present, but the subquery is not correlated with PRODUCT.

You need:

S.PRODUCT_ID = P.PRODUCT_ID

Without this condition, your query asks:

"Does there exist any completed sale anywhere in September?"

But the requirement is:

"Does there exist a completed September sale for this particular product?"

## EXACT MISTAKES:

1. Missing correlation

You wrote:

NOT EXISTS
(
    SELECT 1
    FROM SALES
    WHERE ...
)

Correct:

NOT EXISTS
(
    SELECT 1
    FROM SALES S
    WHERE S.PRODUCT_ID = P.PRODUCT_ID
    AND ...
)

2. Wrong logical scope

Your query checks the entire SALES table rather than the current PRODUCT.

## WHY THIS MISTAKE HAPPENED:

You remembered the NOT EXISTS pattern but missed the parent-child relationship inside the subquery.

## KEY PATTERN / LESSON:

For:

"Find parent records where no child record exists"

use:

WHERE NOT EXISTS
(
    SELECT 1
    FROM CHILD C
    WHERE C.PARENT_ID = P.PARENT_ID
    AND <conditions>
)

Always ask:

"Does the inner query refer back to the current outer row?"


==================================================
Q3 — MULTI-STAGE AGGREGATION
==================================================

RESULT:
🔴 WRONG

## YOUR ANSWER:

WITH CTE AS (
SELECT EMP_ID,
SALARY FROM
(SELECT 
EMP_ID,
SALARY,
ROW_NUMBER() OVER(PARTITION BY EMP_ID ORDER BY EFFECTIVE_DATE DESC)AS RN
FROM EMPLOYEE_SALARY) WHERE RN = 1),

CTE2 AS (
SELECT E.EMP_ID,ES.DEPT_ID,AVG(C.SALARY) AS AVG_LATEST_SALARY ,
COUNT(*) AS EMPLOYEE_COUNT
 FROM EMPLOYEE E LEFT JOIN CTE C 
ON E.EMP_ID = C.EMP_ID
WHERE STATUS = 'ACTIVE'
GROUP BY E.EMP_ID,ES.DEPT_ID)

SELECT DEPT_ID,AVG_LATEST_SALARY,EMPLOYEE_COUNT FROM CTE2 C2 LEFT JOIN CTE C1
ON C2.EMP_ID = C1.EMP_ID
AND C1.AVG_LATEST_SALARY > 80000
;

## CORRECT ANSWER:

WITH LATEST_SALARY AS
(
    SELECT EMP_ID,
           SALARY
    FROM
    (
        SELECT EMP_ID,
               SALARY,
               ROW_NUMBER() OVER
               (
                   PARTITION BY EMP_ID
                   ORDER BY EFFECTIVE_DATE DESC
               ) AS RN
        FROM EMPLOYEE_SALARY
    )
    WHERE RN = 1
),
DEPT_SUMMARY AS
(
    SELECT E.DEPT_ID,
           AVG(L.SALARY) AS AVG_LATEST_SALARY,
           COUNT(*) AS EMPLOYEE_COUNT
    FROM EMPLOYEE E
    JOIN LATEST_SALARY L
      ON L.EMP_ID = E.EMP_ID
    WHERE E.STATUS = 'ACTIVE'
    GROUP BY E.DEPT_ID
)
SELECT DEPT_ID,
       AVG_LATEST_SALARY,
       EMPLOYEE_COUNT
FROM DEPT_SUMMARY
WHERE AVG_LATEST_SALARY > 80000;

## EXPLANATION:

Your first CTE correctly attempts to find the latest salary using ROW_NUMBER(). That is the right first stage.

The second stage has several problems.

## EXACT MISTAKES:

1. Invalid alias:

ES.DEPT_ID

There is no ES alias in the FROM clause.

2. Wrong GROUP BY grain:

GROUP BY E.EMP_ID, ES.DEPT_ID

The required final grain is:

1 row per DEPARTMENT

Therefore the department summary must group by:

GROUP BY E.DEPT_ID

3. Wrong AVG grain:

AVG(C.SALARY) while grouping by employee means the result is not department-level.

4. The final CTE join is unnecessary and incorrect.

5. The condition:

C1.AVG_LATEST_SALARY > 80000

is invalid because AVG_LATEST_SALARY belongs to the department summary, not the latest-salary CTE.

6. The > 80000 condition is a group-level condition and belongs after department aggregation, or in HAVING.

## WHY THIS MISTAKE HAPPENED:

You successfully created the "latest salary per employee" stage, but then lost the required grain during the second aggregation.

## KEY PATTERN / LESSON:

For multi-stage aggregation, explicitly track the grain:

CTE 1:
1 row per EMPLOYEE
→ latest salary

CTE 2:
1 row per DEPARTMENT
→ average latest salary

Final:
1 row per DEPARTMENT
→ keep AVG > 80000

Do not group by EMP_ID when the required result is department-level.


==================================================
Q4 — HAVING + MULTIPLE BUSINESS CONDITIONS
==================================================

RESULT:
🟡 PARTIALLY CORRECT

## YOUR ANSWER:

SELECT S.STORE_ID,S.STORE_NAME
COUNT(*) AS TOTAL_TRANSACTIONS,
SUM(CASE WHEN STATUS = 'COMPLETED' THEN 1 ELSE 0 END) AS COMPLETED_TRANSACTIONS,
SUM(CASE WHEN STATUS = 'CANCELLED' THEN 1 ELSE 0 END) AS COMPLETED_AMOUNT,
SUM(CASE WHEN STATUS = 'COMPLETED' THEN AMOUNT ELSE 0 END) AS CANCELLED_TRANSACTIONS
FROM STORE S LEFT JOIN SALES SC 
ON S.STORE_ID = SC.STORE_ID
WHERE 
SALE_DATE >= DATE'01-SEP-2026' AND
SALE_DATE <= DATE'30-SEP-2026'
GROUP BY 
S.STORE_ID
HAVING 
COUNT(*) >=200
AND SUM(CASE WHEN STATUS = 'COMPLETED' THEN 1 ELSE 0 END) >=150
AND SUM(CASE WHEN STATUS = 'COMPLETED' THEN AMOUNT ELSE 0 END) >2000000
AND SUM(CASE WHEN STATUS = 'CANCELLED' THEN 1 ELSE 0 END) = 0

## CORRECT ANSWER:

SELECT S.STORE_ID,
       S.STORE_NAME,
       COUNT(SC.SALE_ID) AS TOTAL_TRANSACTIONS,
       SUM(CASE WHEN SC.STATUS = 'COMPLETED' THEN 1 ELSE 0 END) AS COMPLETED_TRANSACTIONS,
       SUM(CASE WHEN SC.STATUS = 'COMPLETED' THEN SC.AMOUNT ELSE 0 END) AS COMPLETED_AMOUNT,
       SUM(CASE WHEN SC.STATUS = 'CANCELLED' THEN 1 ELSE 0 END) AS CANCELLED_TRANSACTIONS
FROM STORE S
JOIN SALES SC
  ON S.STORE_ID = SC.STORE_ID
 AND SC.SALE_DATE >= DATE '2026-09-01'
 AND SC.SALE_DATE < DATE '2026-10-01'
GROUP BY S.STORE_ID,
         S.STORE_NAME
HAVING COUNT(SC.SALE_ID) >= 200
   AND SUM(CASE WHEN SC.STATUS = 'COMPLETED' THEN 1 ELSE 0 END) >= 150
   AND SUM(CASE WHEN SC.STATUS = 'COMPLETED' THEN SC.AMOUNT ELSE 0 END) > 2000000
   AND SUM(CASE WHEN SC.STATUS = 'CANCELLED' THEN 1 ELSE 0 END) = 0;

## EXPLANATION:

Your conditional aggregation and HAVING conditions are conceptually on the correct store grain.

The major issue is that two output expressions are swapped.

## EXACT MISTAKES:

1. Wrong alias for cancelled count

You wrote:

SUM(CASE WHEN STATUS = 'CANCELLED' THEN 1 ELSE 0 END)
AS COMPLETED_AMOUNT

This is CANCELLED_TRANSACTIONS, not COMPLETED_AMOUNT.

2. Wrong alias for completed amount

You wrote:

SUM(CASE WHEN STATUS = 'COMPLETED' THEN AMOUNT ELSE 0 END)
AS CANCELLED_TRANSACTIONS

This is COMPLETED_AMOUNT, not CANCELLED_TRANSACTIONS.

3. Missing comma

You wrote:

S.STORE_ID,S.STORE_NAME
COUNT(*)

A comma is required after STORE_NAME.

4. Missing STORE_NAME from GROUP BY

You selected STORE_NAME but grouped only by STORE_ID.

5. LEFT JOIN is unnecessary here

Because SALE_DATE is filtered in WHERE, the LEFT JOIN effectively behaves as an INNER JOIN.

6. Date-range precision

Prefer:

SC.SALE_DATE >= DATE '2026-09-01'
AND SC.SALE_DATE < DATE '2026-10-01'

## WHY THIS MISTAKE HAPPENED:

The conditional aggregation logic was understood, but the output expressions were mapped to the wrong column names.

## KEY PATTERN / LESSON:

TOTAL_TRANSACTIONS
→ COUNT(SALE_ID)

COMPLETED_TRANSACTIONS
→ SUM(CASE WHEN STATUS = 'COMPLETED' THEN 1 ELSE 0 END)

COMPLETED_AMOUNT
→ SUM(CASE WHEN STATUS = 'COMPLETED' THEN AMOUNT ELSE 0 END)

CANCELLED_TRANSACTIONS
→ SUM(CASE WHEN STATUS = 'CANCELLED' THEN 1 ELSE 0 END)


==================================================
Q5 — LEAD-LEVEL RECONCILIATION
==================================================

RESULT:
🔴 WRONG

## YOUR ANSWER:

WITH ORDER_SUMMARY AS (
	SELECT 
		CUSTOMER_ID, 
		SUM(AMOUNT) AS TOTAL_ORDER_AMOUNT , 
		COUNT(*) AS COMPLETED_ORDER_COUNT 
	FROM 
		ORDERS
	WHERE 
		STATUS = 'COMPLETED'
		AND ORDER_DATE >= DATE '01-SEP-2026'
		AND ORDER_DATE <= DATE '30-SEP-2026'
	HAVING 
		SUM(AMOUNT) > 100000
		AND COUNT(*) >=10
),
PAYMENT_SUMMARY AS (
	SELECT 
		O.CUSTOMER_ID,
		SUM(P.PAYMENT_AMOUNT) AS TOTAL_PAID_AMOUNT,
		SUM(O.AMOUNT) AS TOTAL_ORDER_AMOUNT
	FROM ORDERS O LEFT JOIN PAYMENT P
	ON O.ORDER_ID = P.ORDER_ID
	AND P.STATUS = 'SUCCESS'
	WHERE O.STATUS = 'COMPLETED'
	AND O.ORDER_DATE >= DATE '01-SEP-2026'
	AND O.ORDER_DATE <= DATE '30-SEP-2026'	
)

SELECT C.CUSTOMER_ID,
C.CUSTOMER_NAME
OS.COMPLETED_ORDER_COUNT,
OS.TOTAL_ORDER_AMOUNT
PS.TOTAL_PAID_AMOUNT,
(OS.TOTAL_ORDER_AMOUNT -PS.TOTAL_PAID_AMOUNT) OUTSTANDING_AMOUNT FROM CUSTOMER C 
LEFT JOIN ORDER_SUMMARY OS
C.CUSTOMER_ID= OS.CUSTOMER_ID LEFT JOIN PAYMENT_SUMMARY PS 
ON C.CUSTOMER_ID= PS.CUSTOMER_ID ;

## CORRECT ANSWER:

WITH ORDER_SUMMARY AS
(
    SELECT O.CUSTOMER_ID,
           COUNT(*) AS COMPLETED_ORDER_COUNT,
           SUM(O.AMOUNT) AS TOTAL_ORDER_AMOUNT
    FROM ORDERS O
    WHERE O.STATUS = 'COMPLETED'
    AND O.ORDER_DATE >= DATE '2026-09-01'
    AND O.ORDER_DATE < DATE '2026-10-01'
    GROUP BY O.CUSTOMER_ID
    HAVING SUM(O.AMOUNT) > 100000
    AND COUNT(*) >= 10
),
PAYMENT_SUMMARY AS
(
    SELECT O.CUSTOMER_ID,
           SUM(P.PAYMENT_AMOUNT) AS TOTAL_PAID_AMOUNT
    FROM ORDERS O
    JOIN PAYMENT P
      ON P.ORDER_ID = O.ORDER_ID
     AND P.STATUS = 'SUCCESS'
    WHERE O.STATUS = 'COMPLETED'
    AND O.ORDER_DATE >= DATE '2026-09-01'
    AND O.ORDER_DATE < DATE '2026-10-01'
    GROUP BY O.CUSTOMER_ID
)
SELECT C.CUSTOMER_ID,
       C.CUSTOMER_NAME,
       OS.COMPLETED_ORDER_COUNT,
       OS.TOTAL_ORDER_AMOUNT,
       NVL(PS.TOTAL_PAID_AMOUNT, 0) AS TOTAL_PAID_AMOUNT,
       OS.TOTAL_ORDER_AMOUNT - NVL(PS.TOTAL_PAID_AMOUNT, 0) AS OUTSTANDING_AMOUNT
FROM CUSTOMER C
JOIN ORDER_SUMMARY OS
  ON C.CUSTOMER_ID = OS.CUSTOMER_ID
LEFT JOIN PAYMENT_SUMMARY PS
  ON C.CUSTOMER_ID = PS.CUSTOMER_ID
WHERE C.STATUS = 'ACTIVE'
AND NVL(PS.TOTAL_PAID_AMOUNT, 0) < OS.TOTAL_ORDER_AMOUNT;

## EXPLANATION:

This was the Lead-level question, and the biggest problem was choosing the wrong aggregation grain.

## EXACT MISTAKES:

1. Missing GROUP BY in ORDER_SUMMARY

You need:

GROUP BY CUSTOMER_ID

because the required grain is:

1 row = 1 CUSTOMER

2. Missing GROUP BY in PAYMENT_SUMMARY

You need:

GROUP BY O.CUSTOMER_ID

3. Raw ORDERS × PAYMENT multiplication

You calculate:

SUM(O.AMOUNT)

after joining ORDERS to PAYMENT.

If one order has multiple payments, the order amount is repeated.

Example:

ORDER AMOUNT = 1000

PAYMENT 1 = 600
PAYMENT 2 = 400

The join produces:

1000 | 600
1000 | 400

Therefore:

SUM(O.AMOUNT) = 2000

instead of 1000.

4. Missing ACTIVE customer filter

You need:

C.STATUS = 'ACTIVE'

5. Missing final payment condition

You need:

NVL(PS.TOTAL_PAID_AMOUNT, 0) < OS.TOTAL_ORDER_AMOUNT

6. Missing NVL for customers with no successful payment

The requirement says no successful payment should be treated as:

0

Therefore:

NVL(PS.TOTAL_PAID_AMOUNT, 0)

7. SQL syntax errors

You are missing commas and ON keywords in the final joins.

## WHY THIS MISTAKE HAPPENED:

You correctly recognized that ORDERS and PAYMENT need to be connected, but the two sources were joined before being reduced to the required customer-level grain.

The key mistake was calculating order totals and payment totals together from the raw one-to-many relationship.

## KEY PATTERN / LESSON:

For reconciliation:

ORDERS
↓
CUSTOMER-level ORDER_SUMMARY

ORDERS + PAYMENT
↓
CUSTOMER-level PAYMENT_SUMMARY

CUSTOMER
↓
JOIN both summaries
↓
FINAL CUSTOMER-level reconciliation

Most important Lead-level rule:

NEVER SUM a parent/detail amount after joining it to a one-to-many detail table unless the multiplication has already been controlled.


==================================================
DAY 17 FINAL RESULT
==================================================

Q1 → 🟡 PARTIALLY CORRECT
Q2 → 🔴 WRONG
Q3 → 🔴 WRONG
Q4 → 🟡 PARTIALLY CORRECT
Q5 → 🔴 WRONG

FULLY CORRECT:
0

PARTIALLY CORRECT:
2

WRONG:
3

STRICT SCORE:
0 / 5 = 0%

EFFECTIVE ACCURACY:
Correct = 0
Partial = 2 × 0.5 = 1
Wrong = 0

1 / 5 = 20%


==================================================
DAY 17 — CORE LESSON
==================================================

The biggest issue today:

QUERY GRAIN

You understood several individual SQL patterns, but complex questions are still breaking when multiple stages must be combined.

Q1:
Correlated subquery structure → understood

Q2:
NOT EXISTS → missing correlation

Q3:
Latest salary logic → understood
Department aggregation grain → lost

Q4:
Conditional aggregation → mostly understood
Output mapping + syntax → errors

Q5:
Reconciliation concept → understood
Final customer grain + one-to-many multiplication → major issue


==================================================
DAY 17 — PRIORITY LESSONS
==================================================

1. ALWAYS IDENTIFY FINAL GRAIN

Before writing the query:

"What does one final row represent?"

Examples:

1 row = CUSTOMER
1 row = STORE
1 row = DEPARTMENT

2. TRACK GRAIN AFTER EVERY CTE

Example:

LATEST_SALARY
→ 1 row / EMPLOYEE

DEPT_SUMMARY
→ 1 row / DEPARTMENT

3. CORRELATION IS CRITICAL

NOT EXISTS must normally connect child to current parent:

CHILD.PARENT_ID = PARENT.PARENT_ID

4. CONTROL ONE-TO-MANY MULTIPLICATION

ORDERS
→ PAYMENT

One order can have many payments.

Never blindly SUM order-level amounts after that join.

5. CONDITIONAL AGGREGATION

Always map expression → requested output carefully.

6. SQL SYNTAX PRECISION

Recurring issues:

* Missing commas
* Missing GROUP BY
* Missing ON
* Missing outer filters
* Wrong aliases
* Wrong expression aliases
* Date-range precision

7. DATE FILTER PATTERN

Use:

>= DATE '2026-09-01'
AND < DATE '2026-10-01'


==================================================
NO REWRITE PRACTICE
==================================================


==================================================
CUMULATIVE STATUS THROUGH DAY 17
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

### CUMULATIVE

* **Correct: 34**
* **Partial: 34**
* **Wrong: 16**
* **Questions: 85**

> The historical Day 1–7 baseline contains a one-question classification-count inconsistency, so the category counts do not sum to the 85-question total. The historical baseline is preserved rather than silently changed.

### CUMULATIVE STRICT SCORE

**34 / 85 = 40.00%**

### CUMULATIVE EFFECTIVE ACCURACY

**(34 + 34 × 0.5) / 85 = 60.00%**
