==================================================
SQL CHALLENGE — DAY 16
YOUR ANSWER + CORRECT ANSWER
============================

==================================================
Q1 — CTE + GROUP BY + HAVING
============================

RESULT:
🟡 PARTIALLY CORRECT

## YOUR ANSWER:

WITH CTE AS
(
SELECT
O.CUSTOMER_ID,
COUNT(*) AS TOTAL_ORDERS,
SUM(CASE WHEN O.ORDER_STATUS = 'COMPLETED' THEN 1 ELSE 0 END) AS COMPLETED_ORDERS,
SUM(O.AMOUNT) AS TOTAL_AMOUNT
FROM ORDERS O
WHERE ORDER_DATE >= '01-SEP-2026'
AND ORDER_DATE =< '30-SEP-2026'
GROUP BY O.CUSTOMER_ID
HAVING
COUNT(*) >= 5
AND SUM(CASE WHEN O.ORDER_STATUS = 'COMPLETED' THEN 1 ELSE 0 END) >=3
)
SELECT C.CUSTOMER_ID,C.CUSTOMER_NAME
CT.TOTAL_ORDERS,CT.COMPLETED_ORDERS,CT.TOTAL_AMOUNT
FROM CUSTOMER C JOIN CTE CT
ON C.CUSTOMER_ID =CT.CUSTOMER_ID
WHERE C.STATUS = 'ACTIVE';

## CORRECT ANSWER:

WITH CTE AS
(
SELECT O.CUSTOMER_ID,
COUNT(*) AS TOTAL_ORDERS,
SUM(CASE WHEN O.ORDER_STATUS = 'COMPLETED' THEN 1 ELSE 0
END) AS COMPLETED_ORDERS,
SUM(O.AMOUNT) AS TOTAL_AMOUNT
FROM ORDERS O
WHERE O.ORDER_DATE >= DATE '2026-09-01'
AND O.ORDER_DATE < DATE '2026-10-01'
GROUP BY O.CUSTOMER_ID
HAVING COUNT(*) >= 5
AND SUM(CASE WHEN O.ORDER_STATUS = 'COMPLETED' THEN 1 ELSE 0
END) >= 3)

SELECT C.CUSTOMER_ID,
C.CUSTOMER_NAME,
CT.TOTAL_ORDERS,
CT.COMPLETED_ORDERS,
CT.TOTAL_AMOUNT
FROM CUSTOMER C
JOIN CTE CT
ON C.CUSTOMER_ID = CT.CUSTOMER_ID
WHERE C.STATUS = 'ACTIVE';

## EXPLANATION:

Your overall SQL design is correct.

You correctly identified:

ORDERS
→ filter September
→ GROUP BY CUSTOMER_ID
→ calculate totals
→ HAVING business conditions
→ JOIN CUSTOMER
→ filter ACTIVE customers

The problems are mainly SQL syntax and date precision.

## EXACT MISTAKES:

1. Invalid operator

You wrote:

ORDER_DATE =< '30-SEP-2026'

Correct:

ORDER_DATE <= ...

However, the preferred date-range pattern is:

ORDER_DATE >= DATE '2026-09-01'
AND ORDER_DATE < DATE '2026-10-01'

2. Missing comma in final SELECT

You wrote:

C.CUSTOMER_NAME
CT.TOTAL_ORDERS

It must be:

C.CUSTOMER_NAME,
CT.TOTAL_ORDERS

3. Date literals

You used strings:

'01-SEP-2026'

For Oracle, use an explicit DATE literal or TO_DATE.

Preferred:

DATE '2026-09-01'

## WHY THIS MISTAKE HAPPENED:

The business logic was understood.

The failure came from writing the query too quickly and not checking the SQL clause and operator syntax before moving to the next part.

## KEY PATTERN / LESSON:

GROUP BY + HAVING:

WHERE
→ filters rows BEFORE aggregation

GROUP BY
→ creates the required grain

HAVING
→ filters groups AFTER aggregation

For this problem:

WHERE
→ September orders

GROUP BY CUSTOMER_ID
→ one row per customer

HAVING
→ at least 5 orders
→ at least 3 completed orders

==================================================
Q2 — CORRELATED SUBQUERY
========================

RESULT:
🟢 CORRECT

## YOUR ANSWER:

SELECT E.EMP_ID,E.EMP_NAME,E.DEPT_ID,E.SALARY
FROM EMPLOYEE E
WHERE E.SALARY >
(
SELECT AVG(D.SALARY)
FROM EMPLOYEE D
WHERE D.DEPT_ID = E.DEPT_ID
);

## CORRECT ANSWER:

SELECT E.EMP_ID,
E.EMP_NAME,
E.DEPT_ID,
E.SALARY
FROM EMPLOYEE E
WHERE E.SALARY >
(
SELECT AVG(D.SALARY)
FROM EMPLOYEE D
WHERE D.DEPT_ID = E.DEPT_ID
);

## EXPLANATION:

This is exactly the requested correlated-subquery pattern.

Outer query:

EMPLOYEE E

For each employee, the subquery calculates:

AVG(D.SALARY)

for the same department:

D.DEPT_ID = E.DEPT_ID

Then:

E.SALARY > department average

## WHY THIS WORKS:

The inner query depends on the current row of the outer query.

That makes it a correlated subquery.

Outer row:
Employee A, DEPT_ID = 10

Inner query:
Average salary of DEPT_ID = 10

Then compare:

Employee A salary > department average

## KEY PATTERN / LESSON:

CORRELATED SUBQUERY:

SELECT ...
FROM TABLE A
WHERE A.VALUE >
(
SELECT AVG(B.VALUE)
FROM TABLE B
WHERE B.GROUP_ID = A.GROUP_ID
);

The key connection is:

B.GROUP_ID = A.GROUP_ID

==================================================
Q3 — NULL + LEFT JOIN + AGGREGATION
===================================

RESULT:
🟢 CORRECT

## YOUR ANSWER:

SELECT P.PRODUCT_ID,
P.PRODUCT_NAME,
SUM(NVL(S.QUANTITY,0)) AS TOTAL_QUANTITY,
SUM(NVL(S.SALE_AMOUNT,0)) AS TOTAL_SALES_AMOUNT
FROM PRODUCT P
LEFT JOIN SALES S
ON P.PRODUCT_ID = S.PRODUCT_ID
AND S.STATUS = 'COMPLETED'
WHERE P.STATUS = 'ACTIVE'
GROUP BY P.PRODUCT_ID,
P.PRODUCT_NAME;

## CORRECT ANSWER:

SELECT P.PRODUCT_ID,
P.PRODUCT_NAME,
NVL(SUM(S.QUANTITY), 0) AS TOTAL_QUANTITY,
NVL(SUM(S.SALE_AMOUNT), 0) AS TOTAL_SALES_AMOUNT
FROM PRODUCT P
LEFT JOIN SALES S
ON P.PRODUCT_ID = S.PRODUCT_ID
AND S.STATUS = 'COMPLETED'
WHERE P.STATUS = 'ACTIVE'
GROUP BY P.PRODUCT_ID,
P.PRODUCT_NAME;

## EXPLANATION:

Your query correctly satisfies the required logic.

You correctly used PRODUCT as the driving table:

PRODUCT
→ LEFT JOIN
→ SALES

You correctly placed:

S.STATUS = 'COMPLETED'

inside the ON condition.

This is important because putting it in WHERE could eliminate products having no matching sales and effectively turn the LEFT JOIN into an INNER JOIN.

You also correctly grouped at:

PRODUCT_ID + PRODUCT_NAME

which gives:

1 row = 1 product

## WHY THIS WORKS:

For a product with no completed sales:

LEFT JOIN produces the product row with NULL sales columns.

Your:

NVL(S.QUANTITY, 0)
NVL(S.SALE_AMOUNT, 0)

converts those NULL values to zero before aggregation.

## KEY PATTERN / LESSON:

When the requirement says:

"ALL MASTER RECORDS INCLUDING THOSE WITH NO CHILD RECORDS"

use:

MASTER
→ LEFT JOIN
→ CHILD

And if the child filter must not remove the master row:

put the child filter in ON.

Example:

LEFT JOIN SALES S
ON P.PRODUCT_ID = S.PRODUCT_ID
AND S.STATUS = 'COMPLETED'

==================================================
Q4 — MULTI-STAGE CTE + LATEST RECORD
====================================

RESULT:
🟢 CORRECT

## YOUR ANSWER:

WITH LATEST_STATUS AS
(
SELECT CUSTOMER_ID,
STATUS,
EFFECTIVE_DATE,
ROW_NUMBER() OVER(
PARTITION BY CUSTOMER_ID
ORDER BY EFFECTIVE_DATE DESC
) AS RN
FROM CUSTOMER_STATUS_HISTORY
),
LATEST_STATUS_ACT AS
(
SELECT CUSTOMER_ID,
STATUS AS LATEST_STATUS,
EFFECTIVE_DATE
FROM LATEST_STATUS
WHERE RN = 1
AND STATUS = 'ACTIVE'
)
SELECT C.CUSTOMER_ID,
C.CUSTOMER_NAME,
LA.LATEST_STATUS,
LA.EFFECTIVE_DATE
FROM CUSTOMER C
JOIN LATEST_STATUS_ACT LA
ON C.CUSTOMER_ID = LA.CUSTOMER_ID;

## CORRECT ANSWER:

WITH LATEST_STATUS AS
(
SELECT CUSTOMER_ID,
STATUS,
EFFECTIVE_DATE,
ROW_NUMBER() OVER
(
PARTITION BY CUSTOMER_ID
ORDER BY EFFECTIVE_DATE DESC
) AS RN
FROM CUSTOMER_STATUS_HISTORY
),
LATEST_STATUS_ACT AS
(
SELECT CUSTOMER_ID,
STATUS AS LATEST_STATUS,
EFFECTIVE_DATE
FROM LATEST_STATUS
WHERE RN = 1
AND STATUS = 'ACTIVE'
)
SELECT C.CUSTOMER_ID,
C.CUSTOMER_NAME,
LA.LATEST_STATUS,
LA.EFFECTIVE_DATE
FROM CUSTOMER C
JOIN LATEST_STATUS_ACT LA
ON C.CUSTOMER_ID = LA.CUSTOMER_ID;

## EXPLANATION:

Your query correctly uses a two-stage approach.

Stage 1:

CUSTOMER_STATUS_HISTORY
→ ROW_NUMBER()
→ latest record per customer

Stage 2:

RN = 1
→ check latest STATUS = ACTIVE

Then:

CUSTOMER
→ JOIN latest active status

The important part is that you did NOT filter STATUS = 'ACTIVE'
before calculating the latest record.

That is correct.

Example:

Customer 101:

2026-01-01 → ACTIVE
2026-05-01 → INACTIVE
2026-09-01 → ACTIVE

Your query first identifies:

2026-09-01 → RN = 1

Then checks:

STATUS = ACTIVE

That is exactly what the requirement asked for.

## WHY THIS WORKS:

The order of operations is correct:

STATUS HISTORY
↓
ROW_NUMBER()
↓
RN = 1
↓
latest status
↓
STATUS = ACTIVE

## KEY PATTERN / LESSON:

For:

"Find latest record, then apply condition to latest record"

DO:

ROW_NUMBER()
→ RN = 1
→ apply business condition

Do NOT prematurely filter the history table if that would change
which record is considered "latest".

==================================================
Q5 — LEAD-LEVEL BUSINESS SQL
============================

RESULT:
🔴 WRONG

## YOUR ANSWER:

WITH TOL_SAL AS
(
SELECT
SALE_ID,
STORE_ID,
SUM(AMOUNT) AS TOTAL_SALES_AMOUNT,
COUNT(*) AS COMPLETED_TRANSACTIONS,
FROM SALES
WHERE
STATUS = 'COMPLETED'
AND SALE_DATE >= '01-SEP-2026'
SALE_DATE <= '30-SEP-2026'
GROUP BY SALE_ID,STORE_ID
),
TOL_SAL_LAT AS
(
SELECT
SALE_ID,
STORE_ID,
TOTAL_SALES_AMOUNT,
COMPLETED_TRANSACTIONS
FROM TOL_SAL
WHERE
COMPLETED_TRANSACTIONS >= 100
AND TOTAL_SALES_AMOUNT > 1,000,000
),
TOL_PAY AS
(
SELECT SALE_ID,
SUM(PAYMENT_AMOUNT) AS TOT_PAY
FROM PAYMENT
WHERE STATUS = 'SUCCESS'
),
TOL_PAY_LAT AS
(
SELECT TL.SALE_ID AS SALE_ID,
TL.STORE_ID AS STORE_ID,
TL.TOTAL_SALES_AMOUNT AS TOTAL_SALES_AMOUNT,
TL.COMPLETED_TRANSACTIONS AS COMPLETED_TRANSACTIONS,
TP.TOT_PAY AS TOT_PAY,
(TL.TOTAL_SALES_AMOUNT - TP.TOT_PAY) AS OUTSTANDING_AMOUNT
FROM TOL_SAL_LAT TL
JOIN TOL_PAY TP
ON TL.SALE_ID = TP.SALE_ID
WHERE TL.TOTAL_SALES_AMOUNT < TP.TOT_PAY
)
SELECT S.STORE_ID,
S.STORE_NAME,
TPL.TOTAL_SALES_AMOUNT
TPL.COMPLETED_TRANSACTIONS,
TPL.TOT_PAY,
TPL.OUTSTANDING_AMOUNT
FROM STORE S
LEFT JOIN TOL_PAY_LAT TPL
ON S.STORE_ID = TPL.STORE_ID;

## CORRECT ANSWER:

WITH SALES_SUMMARY AS
(
SELECT STORE_ID,
SUM(AMOUNT) AS TOTAL_SALES_AMOUNT,
COUNT(*) AS COMPLETED_TRANSACTIONS
FROM SALES
WHERE STATUS = 'COMPLETED'
AND SALE_DATE >= DATE '2026-09-01'
AND SALE_DATE < DATE '2026-10-01'
GROUP BY STORE_ID
HAVING SUM(AMOUNT) > 1000000
AND COUNT(*) >= 100
),
PAYMENT_SUMMARY AS
(
SELECT S.STORE_ID,
SUM(P.PAYMENT_AMOUNT) AS TOTAL_PAID_AMOUNT
FROM SALES S
JOIN PAYMENT P
ON S.SALE_ID = P.SALE_ID
WHERE S.STATUS = 'COMPLETED'
AND S.SALE_DATE >= DATE '2026-09-01'
AND S.SALE_DATE < DATE '2026-10-01'
AND P.STATUS = 'SUCCESS'
GROUP BY S.STORE_ID
)
SELECT ST.STORE_ID,
ST.STORE_NAME,
SS.TOTAL_SALES_AMOUNT,
SS.COMPLETED_TRANSACTIONS,
NVL(PS.TOTAL_PAID_AMOUNT, 0) AS TOTAL_PAID_AMOUNT,
SS.TOTAL_SALES_AMOUNT
- NVL(PS.TOTAL_PAID_AMOUNT, 0) AS OUTSTANDING_AMOUNT
FROM STORE ST
JOIN SALES_SUMMARY SS
ON ST.STORE_ID = SS.STORE_ID
LEFT JOIN PAYMENT_SUMMARY PS
ON ST.STORE_ID = PS.STORE_ID
WHERE NVL(PS.TOTAL_PAID_AMOUNT, 0) < SS.TOTAL_SALES_AMOUNT;

## EXPLANATION:

This was the Lead-level question, and the biggest problem was
choosing the wrong aggregation grain.

1. WRONG SALES GRAIN

You used:

GROUP BY SALE_ID, STORE_ID

That creates:

1 row = 1 SALE

But the final requirement is:

1 row = 1 STORE

Therefore SALES must be aggregated directly to:

STORE_ID

Correct:

GROUP BY STORE_ID

2. COMPLETED_TRANSACTIONS IS WRONG

Because you grouped by SALE_ID, this:

COUNT(*)

will normally produce 1 for each sale.

It cannot answer:

"Number of COMPLETED sales transactions per store >= 100"

The correct store-level calculation is:

COUNT(*)

after grouping only by STORE_ID and filtering:

STATUS = 'COMPLETED'

3. HAVING CONDITIONS ARE AT THE WRONG LEVEL

You put:

COMPLETED_TRANSACTIONS >= 100
TOTAL_SALES_AMOUNT > 1,000,000

inside a later CTE.

But because the previous CTE is at SALE grain, those conditions are being evaluated per sale rather than per store.

The conditions must be applied after aggregation to STORE grain:

GROUP BY STORE_ID

then:

HAVING SUM(AMOUNT) > 1000000
AND COUNT(*) >= 100

4. MISSING AND IN DATE FILTER

You wrote:

SALE_DATE >= '01-SEP-2026'
SALE_DATE <= '30-SEP-2026'

There is no AND before the second condition.

Correct:

AND SALE_DATE >= DATE '2026-09-01'
AND SALE_DATE < DATE '2026-10-01'

5. INVALID NUMBER LITERAL

You wrote:

1,000,000

In SQL this should be:

1000000

6. PAYMENT SUMMARY IS MISSING GROUP BY

You wrote:

SELECT SALE_ID,
SUM(PAYMENT_AMOUNT)
FROM PAYMENT
WHERE STATUS = 'SUCCESS'

But SUM with SALE_ID requires:

GROUP BY SALE_ID

or, for this business requirement, the payment should eventually
be aggregated to STORE grain.

7. PAYMENT IS AGGREGATED AT THE WRONG GRAIN

The final result is:

1 row = 1 STORE

Therefore payment must eventually become:

STORE_ID
→ TOTAL_PAID_AMOUNT

You cannot leave payment at SALE_ID grain and expect the final
STORE-level result to be correct.

8. WRONG BUSINESS COMPARISON

You wrote:

WHERE TL.TOTAL_SALES_AMOUNT < TP.TOT_PAY

But the requirement says:

TOTAL SUCCESS PAYMENTS is LESS THAN completed sales amount.

Therefore:

TOTAL_PAID_AMOUNT < TOTAL_SALES_AMOUNT

Your comparison is reversed.

9. OUTSTANDING AMOUNT CAN BECOME NEGATIVE

You calculate:

SALES - PAYMENT

which is correct for outstanding amount.

But your WHERE condition selects:

SALES < PAYMENT

That means you are selecting overpaid cases and calculating a
negative outstanding amount.

Correct:

PAYMENT < SALES

10. MISSING COMMA IN FINAL SELECT

You wrote:

TPL.TOTAL_SALES_AMOUNT
TPL.COMPLETED_TRANSACTIONS

A comma is required.

11. FINAL JOIN GRAIN IS NOT CONTROLLED

Because TOL_PAY_LAT remains at SALE grain, joining it to STORE
can produce multiple rows per store.

The final result must be:

1 row = 1 STORE

Therefore both summaries must be:

STORE_ID
→ one row per store

## WHY THIS MISTAKE HAPPENED:

This is the most important lesson from Q5.

You understood that raw SALES and raw PAYMENT should not be
joined directly.

That part was correct.

But you solved the row-multiplication problem only partially.

You moved from:

RAW SALES
→ SALE_ID grain

instead of moving all the way to:

RAW SALES
→ STORE grain

The requirement explicitly said:

Final grain = 1 row per STORE

So every intermediate dataset used in the final calculation
must be compatible with that grain.

## KEY PATTERN / LESSON:

When the final requirement says:

1 ROW = STORE

think:

SALES
↓
filter COMPLETED + September
↓
GROUP BY STORE_ID
↓
SALES SUMMARY

PAYMENT
↓
join to qualifying SALES
↓
filter SUCCESS
↓
GROUP BY STORE_ID
↓
PAYMENT SUMMARY

Then:

STORE
↓
JOIN SALES SUMMARY
↓
LEFT JOIN PAYMENT SUMMARY
↓
calculate OUTSTANDING

The key Lead-level question is:

"At what grain am I right now?"

If the answer is:

SALE

but the final answer requires:

STORE

you are not ready to join the final result yet.

==================================================
DAY 16 FINAL RESULT
===================

Q1 → 🟡 PARTIALLY CORRECT
Q2 → 🟢 CORRECT
Q3 → 🟢 CORRECT
Q4 → 🟢 CORRECT
Q5 → 🔴 WRONG

FULLY CORRECT:
3

PARTIALLY CORRECT:
1

WRONG:
1

STRICT SCORE:
3 / 5 = 60%

EFFECTIVE ACCURACY:
Correct = 3
Partial = 1 × 0.5 = 0.5
Wrong = 0

3.5 / 5 = 70%

==================================================
DAY 16 — CORE LESSON
====================

The biggest improvement today:

Q2 → Correlated subquery: CORRECT
Q3 → LEFT JOIN + NULL + aggregation: CORRECT
Q4 → Multi-stage CTE + latest record: CORRECT

The major remaining weakness is:

QUERY GRAIN

You are beginning to understand the patterns, but in complex
questions you sometimes stop one aggregation level too early.

Day 16 Q5 showed this clearly:

REQUIRED:
1 row = STORE

YOU BUILT:
1 row = SALE

That difference caused multiple downstream problems.

==================================================
DAY 16 — PRIORITY LESSONS
=========================

1. ALWAYS IDENTIFY FINAL GRAIN

Before joining:

"What does one final row represent?"

2. MAKE EACH SUMMARY MATCH THE REQUIRED GRAIN

Final = STORE

Then:

SALES SUMMARY = STORE
PAYMENT SUMMARY = STORE

3. HAVING WORKS AT GROUP GRAIN

If:

GROUP BY STORE_ID

then:

HAVING

evaluates store-level metrics.

4. LATEST RECORD LOGIC IS IMPROVING

Your Q4 correctly used:

ROW_NUMBER()
→ RN = 1
→ latest record
→ business condition

5. LEFT JOIN FILTER PLACEMENT

Child-table conditions can belong in ON when the master
population must be preserved.

6. SQL SYNTAX PRECISION STILL NEEDS WORK

Recurring issues:

* =<
* Missing commas
* Missing AND
* Missing GROUP BY
* Wrong aliases
* Invalid number formatting

==================================================
NO REWRITE PRACTICE
===================
