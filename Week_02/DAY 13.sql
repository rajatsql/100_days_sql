==================================================
SQL CHALLENGE — DAY 13 REVIEW
==================================================

TOTAL QUESTIONS:
5

RESULT:
--------------------------------------------------

Q1 — QUERY GRAIN + AGGREGATION
RESULT: 🟡 PARTIALLY CORRECT

YOUR ANSWER:
SELECT C.CUSTOMER_ID,C.CUSTOMER_NAME,O.ORDER_COUNT,O.TOTAL_ORDER_AMOUNT
FROM CUSTOMER C
JOIN
(
    SELECT CUSTOMER_ID,
           COUNT(*) AS ORDER_COUNT,
           SUM(ORDER_AMOUNT) AS TOTAL_ORDER_AMOUNT
    FROM ORDERS
    WHERE ORDER_STATUS = 'COMPLETE'
      AND TO_CHAR(ORDER_DATE,'MON-RRRR') = 'SEP-2026'
    GROUP BY CUSTOMER_ID
    HAVING COUNT(*) >= 1
) O
ON C.CUSTOMER_ID = O.CUSTOMER_ID
WHERE C.STATUS = 'ACTIVE';

EXPLANATION:

Your overall structure is good:
- Aggregate ORDERS by CUSTOMER_ID.
- Apply HAVING.
- Join to CUSTOMER.
- Filter ACTIVE customers.

But there are two important requirement mistakes:

1. STATUS value is wrong.

Requirement:
'COMPLETED'

You used:
'COMPLETE'

2. HAVING condition is wrong.

Requirement:
at least 2 orders

You used:
HAVING COUNT(*) >= 1

It must be:

HAVING COUNT(*) >= 2

Your query therefore does not correctly implement the business requirement.

CORRECT ANSWER:
SELECT C.CUSTOMER_ID,
       C.CUSTOMER_NAME,
       O.ORDER_COUNT,
       O.TOTAL_ORDER_AMOUNT
FROM CUSTOMER C
JOIN
(
    SELECT CUSTOMER_ID,
           COUNT(*) AS ORDER_COUNT,
           SUM(ORDER_AMOUNT) AS TOTAL_ORDER_AMOUNT
    FROM ORDERS
    WHERE ORDER_STATUS = 'COMPLETED'
      AND ORDER_DATE >= DATE '2026-09-01'
      AND ORDER_DATE < DATE '2026-10-01'
    GROUP BY CUSTOMER_ID
    HAVING COUNT(*) >= 2
) O
ON C.CUSTOMER_ID = O.CUSTOMER_ID
WHERE C.STATUS = 'ACTIVE';

KEY PATTERN / LESSON:
Translate the requirement into exact predicates before writing SQL.

"At least 2" → COUNT(*) >= 2

"COMPLETED orders" → ORDERS.ORDER_STATUS = 'COMPLETED'

Underlying thinking mistake:
You understood the query structure but did not verify each business condition against the exact requirement before finishing the query.


==================================================
Q2 — LEFT JOIN + CONDITIONAL AGGREGATION
RESULT: 🟡 PARTIALLY CORRECT

YOUR ANSWER:
SELECT P.PRODUCT_ID,
       P.PRODUCT_NAME,
       NVL(S.COMPLETED_QTY,0) AS COMPLETED_QTY,
       NVL(S.CANCELLED_QTY,0) AS CANCELLED_QTY
FROM PRODUCT P
LEFT JOIN
(
    SELECT PRODUCT_ID,
           SUM(CASE WHEN STATUS = 'COMPLETED'
                    THEN QUANTITY ELSE 0 END) AS COMPLETED_QTY,
           SUM(CASE WHEN STATUS = 'CANCELLED'
                    THEN QUANTITY ELSE 0 END) AS CANCELLED_QTY
    FROM SALES
    GROUP BY PRODUCT_ID
) S
ON P.PRODUCT_ID = S.PRODUCT_ID;

EXPLANATION:

Your conditional aggregation is correct.

You correctly:
- Used LEFT JOIN.
- Preserved all products.
- Used CASE for COMPLETED/CANCELLED.
- Used NVL for missing products.

The major missing requirement is:

September 2026 only.

You did not filter SALE_DATE.

Therefore your query calculates sales from ALL dates, not September 2026.

The date filter should be inside the SALES aggregation:

WHERE SALE_DATE >= DATE '2026-09-01'
  AND SALE_DATE < DATE '2026-10-01'

CORRECT ANSWER:
SELECT P.PRODUCT_ID,
       P.PRODUCT_NAME,
       NVL(S.COMPLETED_QTY, 0) AS COMPLETED_QTY,
       NVL(S.CANCELLED_QTY, 0) AS CANCELLED_QTY
FROM PRODUCT P
LEFT JOIN
(
    SELECT PRODUCT_ID,
           SUM(CASE WHEN STATUS = 'COMPLETED'
                    THEN QUANTITY ELSE 0 END) AS COMPLETED_QTY,
           SUM(CASE WHEN STATUS = 'CANCELLED'
                    THEN QUANTITY ELSE 0 END) AS CANCELLED_QTY
    FROM SALES
    WHERE SALE_DATE >= DATE '2026-09-01'
      AND SALE_DATE < DATE '2026-10-01'
    GROUP BY PRODUCT_ID
) S
ON P.PRODUCT_ID = S.PRODUCT_ID;

KEY PATTERN / LESSON:
When aggregating an optional child table before a LEFT JOIN:

FILTER → AGGREGATE → LEFT JOIN → NVL

Underlying thinking mistake:
You focused on the status conditions but forgot the second business dimension: the reporting period.


==================================================
Q3 — AGGREGATION BEFORE JOIN + BUSINESS RULE
RESULT: 🔴 WRONG

YOUR ANSWER:
WITH CTE (
SELECT BRANCH_ID,
       COUNT(*) AS TOTAL_INVOICES,
       SUM(CASE WHEN STATUS ='POSTED'
                THEN 1 ELSE 0 END) AS POSTED_INVOICES,
       ((SUM(CASE WHEN STATUS ='POSTED'
                  THEN 1 ELSE 0 END)/COUNT(*))/100) AS POSTED_PERCENTAGE
FROM INVOICE
WHERE TO_CHAR(INVOICE_DATE,'MON-RRRR') = 'SEP-2026'
HAVING COUNT(*) >= 5
AND ((SUM(CASE WHEN STATUS ='POSTED'
               THEN 1 ELSE 0 END)/COUNT(*))/100) = 80)

SELECT ...

EXPLANATION:

This has multiple structural and logical problems.

1. CTE syntax is incorrect.

It should be:

WITH CTE AS
(
    ...
)

2. Missing GROUP BY BRANCH_ID.

You need one row per branch.

Therefore:

GROUP BY BRANCH_ID

is mandatory.

3. POSTED percentage calculation is incorrect.

You wrote:

(POSTED_COUNT / TOTAL_COUNT) / 100

The percentage should be:

(POSTED_COUNT / TOTAL_COUNT) * 100

4. Requirement is at least 80%.

You used:

= 80

It should be:

>= 80

5. The query therefore does not produce the required branch-level aggregation.

CORRECT ANSWER:
WITH CTE AS
(
    SELECT BRANCH_ID,
           COUNT(*) AS TOTAL_INVOICES,
           SUM(CASE WHEN STATUS = 'POSTED'
                    THEN 1 ELSE 0 END) AS POSTED_INVOICES,
           (SUM(CASE WHEN STATUS = 'POSTED'
                     THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS POSTED_PERCENTAGE
    FROM INVOICE
    WHERE INVOICE_DATE >= DATE '2026-09-01'
      AND INVOICE_DATE < DATE '2026-10-01'
    GROUP BY BRANCH_ID
    HAVING COUNT(*) >= 5
       AND (SUM(CASE WHEN STATUS = 'POSTED'
                     THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) >= 80
)
SELECT B.BRANCH_ID,
       B.BRANCH_NAME,
       C.TOTAL_INVOICES,
       C.POSTED_INVOICES,
       C.POSTED_PERCENTAGE
FROM BRANCH B
JOIN CTE C
  ON B.BRANCH_ID = C.BRANCH_ID;

KEY PATTERN / LESSON:
For a branch-level report:

ONE ROW = ONE BRANCH

Therefore:

GROUP BY BRANCH_ID

Then:

HAVING
    COUNT(*) >= 5
AND
    posted_percentage >= 80

Underlying thinking mistake:
You tried to calculate the final percentage before establishing the correct aggregation grain.


==================================================
Q4 — LATEST RECORD + NULL HANDLING
RESULT: 🟢 CORRECT

YOUR ANSWER:
SELECT C.CUSTOMER_ID,
       C.CUSTOMER_NAME,
       CHH.LATEST_STATUS,
       CHH.STATUS_DATE
FROM CUSTOMER C
LEFT JOIN
(
    SELECT CH.CUSTOMER_ID,
           CH.STATUS AS LATEST_STATUS,
           CH.STATUS_DATE,
           ROW_NUMBER() OVER
           (
               PARTITION BY CH.CUSTOMER_ID
               ORDER BY CH.STATUS_DATE DESC
           ) AS RN
    FROM CUSTOMER_STATUS_HISTORY CH
) CHH
ON C.CUSTOMER_ID = CHH.CUSTOMER_ID
AND CHH.RN = 1;

EXPLANATION:

Correct.

You correctly understood the important LEFT JOIN behavior.

The critical part is:

AND CHH.RN = 1

inside the ON condition.

This means:
- Latest history row is selected.
- Customers with history are matched to their latest record.
- Customers without history remain because CUSTOMER is the LEFT JOIN driving table.

You also correctly used:

ROW_NUMBER()
PARTITION BY CUSTOMER_ID
ORDER BY STATUS_DATE DESC

KEY PATTERN / LESSON:
For "latest record for every master row":

ROW_NUMBER()
→ PARTITION BY business key
→ ORDER BY date DESC
→ RN = 1
→ LEFT JOIN when unmatched master rows must remain.


==================================================
Q5 — LEAD-LEVEL JOIN MULTIPLICATION
RESULT: 🟡 PARTIALLY CORRECT

YOUR ANSWER — EXPLANATION:

"Because if any order has no payment made this query filter out that record and that not show in result."

This identifies ONE problem correctly:

The INNER JOIN to PAYMENT removes orders with no payment.

But the question specifically asked about:

ROW MULTIPLICATION

You did not identify the main problem clearly enough.

Example:

ORDER 101 = ₹500

PAYMENT:
₹200
₹300

After JOIN:

ORDER 101 | ₹500 | ₹200
ORDER 101 | ₹500 | ₹300

Then:

SUM(O.ORDER_AMOUNT)

becomes:

₹500 + ₹500 = ₹1000

instead of:

₹500

So the original query can produce incorrect order totals.

Your grain answers:

ORDERS:
"1 CUSTOMER HAVE MULTIPLE ORDERS, 1 ORDER ONE ROW."

This is essentially correct.

Better definition:

ORDERS grain = 1 row represents 1 ORDER.

PAYMENT:
"ONE PAYMENT 1 ROW, ONE ORDER MANY PAYMENT."

Correct.

PAYMENT grain = 1 row represents 1 PAYMENT.

However, your corrected query still has the same row-multiplication problem.

YOUR QUERY:

SELECT O.CUSTOMER_ID,
       SUM(O.ORDER_AMOUNT),
       SUM(P.PAYMENT_AMOUNT)
FROM ORDERS O
LEFT JOIN PAYMENT P
  ON O.ORDER_ID = P.ORDER_ID
GROUP BY O.CUSTOMER_ID;

This still duplicates ORDER_AMOUNT when an order has multiple payments.

You also missed a comma between:

SUM(O.ORDER_AMOUNT) AS TOTAL_ORDER_AMOUNT
SUM(P.PAYMENT_AMOUNT) AS TOTAL_PAYMENT_AMOUNT

CORRECT APPROACH:

First aggregate ORDERS to CUSTOMER grain.

Then aggregate PAYMENT to CUSTOMER grain.

Then join those two already-aggregated datasets.

CORRECT ANSWER:
WITH ORDER_TOTAL AS
(
    SELECT CUSTOMER_ID,
           SUM(ORDER_AMOUNT) AS TOTAL_ORDER_AMOUNT
    FROM ORDERS
    GROUP BY CUSTOMER_ID
),
PAYMENT_TOTAL AS
(
    SELECT O.CUSTOMER_ID,
           SUM(P.PAYMENT_AMOUNT) AS TOTAL_PAYMENT_AMOUNT
    FROM ORDERS O
    JOIN PAYMENT P
      ON O.ORDER_ID = P.ORDER_ID
    GROUP BY O.CUSTOMER_ID
)
SELECT C.CUSTOMER_ID,
       C.CUSTOMER_NAME,
       NVL(O.TOTAL_ORDER_AMOUNT, 0) AS TOTAL_ORDER_AMOUNT,
       NVL(P.TOTAL_PAYMENT_AMOUNT, 0) AS TOTAL_PAYMENT_AMOUNT
FROM CUSTOMER C
LEFT JOIN ORDER_TOTAL O
  ON C.CUSTOMER_ID = O.CUSTOMER_ID
LEFT JOIN PAYMENT_TOTAL P
  ON C.CUSTOMER_ID = P.CUSTOMER_ID;

KEY PATTERN / LESSON:

When joining multiple child tables:

CUSTOMER
   |
   +--- ORDERS
   |
   +--- PAYMENT

Do NOT blindly join both detail tables and aggregate afterward.

Instead:

ORDERS
→ aggregate to CUSTOMER grain

PAYMENT
→ aggregate to CUSTOMER grain

Then:

CUSTOMER
→ JOIN aggregated results

This prevents row multiplication.

Underlying thinking mistake:
You identified the missing-payment problem but did not yet fully recognize that joining two different grains can duplicate measures even when every order has a payment.


==================================================
DAY 13 RESULT
==================================================

TOTAL QUESTIONS:
5

🟢 FULLY CORRECT:
1

🟡 PARTIALLY CORRECT:
3

🔴 WRONG:
1

STRICT SCORE:
1 / 5 = 20%

EFFECTIVE ACCURACY:
1 Correct = 1.0
3 Partial = 1.5
1 Wrong = 0

TOTAL EFFECTIVE POINTS:
2.5 / 5

EFFECTIVE ACCURACY:
50%


==================================================
DAY 13 MAIN FINDINGS
==================================================

STRONG:
- ROW_NUMBER() latest-record pattern
- LEFT JOIN preservation
- Basic aggregation structure
- Understanding table grain at a basic level
- Conditional aggregation structure

WEAK:
- Exact business-condition translation
- Date filtering
- GROUP BY at the correct grain
- Percentage calculation
- JOIN multiplication
- Aggregating multiple child tables independently

MOST IMPORTANT LEAD-LEVEL LESSON:

Before JOIN:

1. Identify the grain of every table.
2. Identify the required output grain.
3. Check whether the JOIN changes row count.
4. Aggregate each detail table to the required grain BEFORE joining when necessary.

Your biggest issue today was not knowing the SQL patterns.

It was **finishing the logic correctly after identifying the pattern.**


==================================================
WEEK 2 PROGRESS SO FAR
==================================================

DAYS COMPLETED:
13 / 100

WEEK 2:
Days 8–13 = 30 questions

DAY 13:
1 Correct
3 Partial
1 Wrong

NO REWRITE PRACTICE
==================================================