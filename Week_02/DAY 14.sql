==================================================
SQL CHALLENGE — DAY 14
YOUR ANSWER + CORRECT ANSWER
=================================================


==================================================
Q1 — CUSTOMER + ORDERS + CONDITIONAL BUSINESS RULE
==================================================

RESULT:
🟡 PARTIALLY CORRECT


YOUR ANSWER:
--------------------------------------------------

SELECT C.CUSTOMER_ID,C.CUSTOMER_NAME,
       ORD.TOTAL_ORDERS,
       ORD.COMPLETED_ORDERS,
       ORD.TOTAL_ORDER_AMOUNT
FROM CUSTOMER
LEFT JOIN (
    SELECT O.CUSTOMER_ID AS CUSTOMER_ID,
           COUNT(*) AS TOTAL_ORDERS,
           SUM(CASE WHEN ORDER_STATUS = 'COMPLETED' THEN 1 ELSE 0 END) AS COMPLETED_ORDERS,
           SUM(ORDER_AMOUNT) AS TOTAL_ORDER_AMOUNT
    FROM ORDERS O
    WHERE O.ORDER_DATE = 'SEP-2026'
    GROUP BY O.CUSTOMER_ID
    HAVING COUNT(*) >= 3
       AND SUM(CASE WHEN ORDER_STATUS = 'COMPLETED' THEN 1 ELSE 0 END) >=2
) ORD
ON C.CUSTOMER_ID = ORD.CUSTOMER_ID
WHERE C.STATUS = 'ACTIVE';


CORRECT ANSWER:
--------------------------------------------------

SELECT C.CUSTOMER_ID,
       C.CUSTOMER_NAME,
       ORD.TOTAL_ORDERS,
       ORD.COMPLETED_ORDERS,
       ORD.TOTAL_ORDER_AMOUNT
FROM CUSTOMER C
LEFT JOIN
(
    SELECT O.CUSTOMER_ID,
           COUNT(*) AS TOTAL_ORDERS,
           SUM(
               CASE
                   WHEN O.ORDER_STATUS = 'COMPLETED'
                   THEN 1
                   ELSE 0
               END
           ) AS COMPLETED_ORDERS,
           SUM(O.ORDER_AMOUNT) AS TOTAL_ORDER_AMOUNT
    FROM ORDERS O
    WHERE O.ORDER_DATE >= DATE '2026-09-01'
      AND O.ORDER_DATE < DATE '2026-10-01'
    GROUP BY O.CUSTOMER_ID
    HAVING COUNT(*) >= 3
       AND SUM(
           CASE
               WHEN O.ORDER_STATUS = 'COMPLETED'
               THEN 1
               ELSE 0
           END
       ) >= 2
) ORD
    ON C.CUSTOMER_ID = ORD.CUSTOMER_ID
WHERE C.STATUS = 'ACTIVE';


EXPLANATION:
--------------------------------------------------

Your overall architecture is correct:

ORDERS
→ GROUP BY CUSTOMER_ID
→ calculate TOTAL_ORDERS
→ calculate COMPLETED_ORDERS
→ HAVING conditions
→ JOIN CUSTOMER
→ filter ACTIVE customers

The main implementation problem is the September filter.

You used:

O.ORDER_DATE = 'SEP-2026'

That does not correctly represent all dates in September 2026.

Correct:

O.ORDER_DATE >= DATE '2026-09-01'
AND O.ORDER_DATE < DATE '2026-10-01'


WHY THIS MISTAKE HAPPENED:
--------------------------------------------------

You recognized the business requirement "September 2026", but converted the month directly into a string comparison instead of converting it into a date range.

The thinking should be:

September 2026
↓
01-Sep-2026 inclusive
↓
01-Oct-2026 exclusive


KEY PATTERN / LESSON:
--------------------------------------------------

For month filtering, think in ranges:

DATE >= first_day_of_month
AND DATE < first_day_of_next_month


==================================================
Q2 — PRODUCT SALES + MISSING DATA
==================================================

RESULT:
🟡 PARTIALLY CORRECT


YOUR ANSWER:
--------------------------------------------------

[YOUR ORIGINAL Q2 SQL IS NOT AVAILABLE IN THE COMPLETE
DAY 14 SOURCE, SO I AM NOT INVENTING IT HERE.]

The saved review confirms that your answer contained the
conditional CASE logic:

CASE WHEN STATUS = 'COMPLETED'
     THEN QUANTITY ELSE 0 END

and that you treated SALES as the driving table.


CORRECT ANSWER:
--------------------------------------------------

SELECT P.PRODUCT_ID,
       P.PRODUCT_NAME,
       NVL(S.COMPLETED_QTY, 0) AS COMPLETED_QTY,
       NVL(S.CANCELLED_QTY, 0) AS CANCELLED_QTY
FROM PRODUCT P
LEFT JOIN
(
    SELECT PRODUCT_ID,
           SUM(
               CASE
                   WHEN STATUS = 'COMPLETED'
                   THEN QUANTITY
                   ELSE 0
               END
           ) AS COMPLETED_QTY,
           SUM(
               CASE
                   WHEN STATUS = 'CANCELLED'
                   THEN QUANTITY
                   ELSE 0
               END
           ) AS CANCELLED_QTY
    FROM SALES
    WHERE SALE_DATE >= DATE '2026-09-01'
      AND SALE_DATE < DATE '2026-10-01'
    GROUP BY PRODUCT_ID
) S
    ON P.PRODUCT_ID = S.PRODUCT_ID
WHERE P.STATUS = 'ACTIVE';


EXPLANATION:
--------------------------------------------------

1. CASE expressions were not aggregated.

You used the equivalent of:

CASE WHEN STATUS = 'COMPLETED'
     THEN QUANTITY ELSE 0 END

That gives a value per SALES row.

You need:

SUM(
    CASE WHEN STATUS = 'COMPLETED'
         THEN QUANTITY ELSE 0 END
)


2. ACTIVE products were not filtered.

The requirement is:

Only ACTIVE products.

Therefore:

WHERE P.STATUS = 'ACTIVE'


3. Missing sales must become 0.

Because PRODUCT is the master table and SALES is optional:

NVL(S.COMPLETED_QTY, 0)

and:

NVL(S.CANCELLED_QTY, 0)


4. Driving table was incorrect.

You identified SALES as the driving table.

But the requirement says:

"every ACTIVE product"

Therefore:

PRODUCT = driving/master table
SALES = optional child data


WHY THIS MISTAKE HAPPENED:
--------------------------------------------------

You focused on the table containing the calculation instead of
the table defining the required population.

Always ask:

"Which records must appear even when there is no matching child?"

Here:

Every PRODUCT must appear.

Therefore PRODUCT drives.


KEY PATTERN / LESSON:
--------------------------------------------------

EVERY X INCLUDING X WITH NO Y

means:

X = driving/master table

Example:

PRODUCT
→ LEFT JOIN
→ SALES SUMMARY


==================================================
Q3 — INVOICE RECONCILIATION
==================================================

RESULT:
🔴 WRONG


YOUR ANSWER:
--------------------------------------------------

[THE COMPLETE ORIGINAL Q3 SQL IS NOT AVAILABLE IN THE
SAVED DAY 14 SOURCE.]

The saved review confirms that your query used PAYMENT as
the driving table and grouped using:

P.INVOICE_ID,
P.CUSTOMER_ID

I am deliberately not reconstructing the missing SQL and
calling it your exact answer.


CORRECT ANSWER:
--------------------------------------------------

WITH PAYMENT_SUMMARY AS
(
    SELECT P.INVOICE_ID,
           SUM(P.PAYMENT_AMOUNT) AS TOTAL_PAID
    FROM PAYMENT P
    WHERE P.STATUS = 'SUCCESS'
    GROUP BY P.INVOICE_ID
)
SELECT I.INVOICE_ID,
       I.CUSTOMER_ID,
       I.INVOICE_AMOUNT,
       NVL(P.TOTAL_PAID, 0) AS TOTAL_PAID,
       I.INVOICE_AMOUNT - NVL(P.TOTAL_PAID, 0) AS OUTSTANDING_AMOUNT
FROM INVOICE I
LEFT JOIN PAYMENT_SUMMARY P
    ON I.INVOICE_ID = P.INVOICE_ID
WHERE I.INVOICE_DATE >= DATE '2026-09-01'
  AND I.INVOICE_DATE < DATE '2026-10-01'
  AND NVL(P.TOTAL_PAID, 0) < I.INVOICE_AMOUNT;


EXPLANATION:
--------------------------------------------------

1. WRONG DRIVING TABLE

You used:

PAYMENT

But INVOICE must drive the report.

Why?

Because unpaid invoices must still appear.

Correct:

INVOICE
→ LEFT JOIN
→ PAYMENT SUMMARY


2. INVOICE DATE FILTER IS MISSING

The reporting period is determined by:

I.INVOICE_DATE

not PAYMENT_DATE.


3. PAYMENT IS OPTIONAL

An invoice without payment produces no PAYMENT row.

Therefore payment information must be converted to:

NVL(TOTAL_PAID, 0)


4. PAYMENT MUST BE AGGREGATED FIRST

If an invoice has multiple payment records, joining payment
detail directly can create multiple rows.

Therefore:

PAYMENT
→ GROUP BY INVOICE_ID
→ one payment-summary row per invoice
→ LEFT JOIN INVOICE


5. FINAL GRAIN

The result must be:

1 row = 1 invoice


WHY THIS MISTAKE HAPPENED:
--------------------------------------------------

You focused on the transaction used to calculate payment
instead of the business entity being reconciled.

For reconciliation, first identify:

"What is the thing I am reporting?"

Answer:

INVOICE.


KEY PATTERN / LESSON:
--------------------------------------------------

MASTER TRANSACTION
→ LEFT JOIN
→ AGGREGATED CHILD TRANSACTION

For this problem:

INVOICE
→ PAYMENT SUMMARY


==================================================
Q4 — LATEST VALID BUSINESS RECORD
==================================================

RESULT:
🟡 PARTIALLY CORRECT


YOUR ANSWER:
--------------------------------------------------

SELECT P.PRODUCT_ID,
       P.PRODUCT_NAME,
       PP.PRICE,
       PP.EFFECTIVE_DATE
FROM PRODUCT P
LEFT JOIN
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
) PP
ON P.PRODUCT_ID = PP.PRODUCT_ID
AND RN = 1;


CORRECT ANSWER:
--------------------------------------------------

SELECT P.PRODUCT_ID,
       P.PRODUCT_NAME,
       PP.PRICE,
       PP.EFFECTIVE_DATE
FROM PRODUCT P
LEFT JOIN
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
) PP
    ON P.PRODUCT_ID = PP.PRODUCT_ID
   AND PP.RN = 1
WHERE P.STATUS = 'ACTIVE';


EXPLANATION:
--------------------------------------------------

Your main SQL pattern is correct.

You correctly identified:

PRODUCT
→ LEFT JOIN
→ latest ACTIVE PRODUCT_PRICE

And:

ROW_NUMBER()
PARTITION BY PRODUCT_ID
ORDER BY EFFECTIVE_DATE DESC
RN = 1


Putting:

RN = 1

inside the ON condition is correct.

This preserves products that do not have an ACTIVE price.


The missing requirement is:

Only ACTIVE products.

You did not filter:

P.STATUS = 'ACTIVE'


WHY THIS MISTAKE HAPPENED:
--------------------------------------------------

You correctly applied the validity condition to the child table:

PRODUCT_PRICE.STATUS = 'ACTIVE'

but missed the separate validity condition on the master table:

PRODUCT.STATUS = 'ACTIVE'


KEY PATTERN / LESSON:
--------------------------------------------------

Always check validity at both levels:

MASTER:
PRODUCT.STATUS = 'ACTIVE'

CHILD:
PRODUCT_PRICE.STATUS = 'ACTIVE'


==================================================
Q5 — LEAD-LEVEL CUSTOMER RECONCILIATION
==================================================

RESULT:
🟡 PARTIALLY CORRECT


YOUR ANSWER:
--------------------------------------------------

[THE COMPLETE ORIGINAL Q5 SQL IS NOT AVAILABLE IN THE
SAVED DAY 14 SOURCE.]

The saved review confirms that your query used TOL_ORDER
and TOL_PAY and contained:

GROUP BY ORDER_ID, CUSTOMER_ID

It also confirms that you used a September PAYMENT_DATE
filter and had an incomplete JOIN condition.

I am not going to invent the missing portions of your
original SQL.


CORRECT ANSWER:
--------------------------------------------------

WITH ORDER_SUMMARY AS
(
    SELECT O.CUSTOMER_ID,
           COUNT(*) AS TOTAL_ORDERS,
           SUM(O.ORDER_AMOUNT) AS TOTAL_ORDER_AMOUNT
    FROM ORDERS O
    WHERE O.ORDER_DATE >= DATE '2026-09-01'
      AND O.ORDER_DATE < DATE '2026-10-01'
    GROUP BY O.CUSTOMER_ID
),
PAYMENT_SUMMARY AS
(
    SELECT O.CUSTOMER_ID,
           SUM(P.PAYMENT_AMOUNT) AS TOTAL_PAID_AMOUNT
    FROM ORDERS O
    JOIN PAYMENT P
        ON O.ORDER_ID = P.ORDER_ID
    WHERE O.ORDER_DATE >= DATE '2026-09-01'
      AND O.ORDER_DATE < DATE '2026-10-01'
    GROUP BY O.CUSTOMER_ID
)
SELECT C.CUSTOMER_ID,
       C.CUSTOMER_NAME,
       NVL(O.TOTAL_ORDERS, 0) AS TOTAL_ORDERS,
       NVL(O.TOTAL_ORDER_AMOUNT, 0) AS TOTAL_ORDER_AMOUNT,
       NVL(P.TOTAL_PAID_AMOUNT, 0) AS TOTAL_PAID_AMOUNT,
       NVL(O.TOTAL_ORDER_AMOUNT, 0)
         - NVL(P.TOTAL_PAID_AMOUNT, 0) AS OUTSTANDING_AMOUNT
FROM CUSTOMER C
LEFT JOIN ORDER_SUMMARY O
    ON C.CUSTOMER_ID = O.CUSTOMER_ID
LEFT JOIN PAYMENT_SUMMARY P
    ON C.CUSTOMER_ID = P.CUSTOMER_ID;


EXPLANATION:
--------------------------------------------------

The target grain is:

1 row = 1 CUSTOMER


Your TOL_ORDER was at:

ORDER_ID + CUSTOMER_ID

That is ORDER grain, not CUSTOMER grain.


TOL_PAY was also at ORDER grain.

Therefore both summaries must eventually become:

CUSTOMER_ID


You also filtered:

PAYMENT_DATE = September

But the requirement explicitly says:

ORDER_DATE determines whether the order belongs to September.

Therefore the September filter belongs to:

ORDERS.ORDER_DATE


You also had an incomplete JOIN condition:

O.ORDER_ID = P.ORDER_ID

It needed the JOIN/ON structure.


Your final SELECT was missing commas.


Another problem was:

O.TOTAL_ORDER_AMOUNT - P.TOTAL_PAID_AMOUNT

When there is no payment:

P.TOTAL_PAID_AMOUNT = NULL

Therefore:

amount - NULL = NULL

Use:

NVL(P.TOTAL_PAID_AMOUNT, 0)


WHY THIS MISTAKE HAPPENED:
--------------------------------------------------

The main issue is not knowing the JOIN syntax.

The deeper issue is stopping the aggregation one level too early.

You reached:

CUSTOMER → ORDERS → aggregate

but stopped at:

1 row = ORDER

instead of continuing to:

1 row = CUSTOMER


KEY PATTERN / LESSON:
--------------------------------------------------

If the final requirement says:

1 ROW = CUSTOMER

then every source must eventually be converted to:

CUSTOMER grain.


Think:

ORDERS
→ September filter
→ aggregate CUSTOMER

PAYMENTS
→ September orders determine scope
→ aggregate CUSTOMER

Then:

CUSTOMER
→ LEFT JOIN order summary
→ LEFT JOIN payment summary


==================================================
DAY 14 FINAL RESULT
==================================================

Q1 → 🟡 PARTIALLY CORRECT
Q2 → 🟡 PARTIALLY CORRECT
Q3 → 🔴 WRONG
Q4 → 🟡 PARTIALLY CORRECT
Q5 → 🟡 PARTIALLY CORRECT


FULLY CORRECT:
0

PARTIALLY CORRECT:
4

WRONG:
1


STRICT SCORE:
0 / 5 = 0%


EFFECTIVE ACCURACY:
Correct = 0
Partial = 4 × 0.5 = 2
Wrong = 0

2 / 5 = 40%


==================================================
DAY 14 — CORE LESSON
==================================================

The biggest recurring pattern is:

REQUIREMENT
↓
DATA GRAIN
↓
DRIVING TABLE
↓
FILTER
↓
AGGREGATION
↓
JOIN
↓
FINAL GRAIN


Before writing SQL, ask:

1. What must appear in the final result?
2. What is the final grain?
3. Which table guarantees those rows?
4. Which tables are optional?
5. Do I need LEFT JOIN?
6. What date determines the reporting period?
7. At what grain should each source be aggregated?
8. Can the JOIN multiply rows?
9. Do NULLs need NVL/COALESCE?
10. Does every SELECT expression have a comma?


==================================================
NO REWRITE PRACTICE
==================================================
