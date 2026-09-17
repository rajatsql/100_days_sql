============================================================
DAY 11 — SQL CHALLENGE REVIEW
============================================================

TOTAL QUESTIONS: 5

CORRECT: 1
PARTIALLY CORRECT: 3
WRONG: 1

FULLY CORRECT: 20%
PARTIALLY CORRECT: 60%
WRONG: 20%

EFFECTIVE ACCURACY:
1 + (3 × 0.5) = 2.5
2.5 / 5 × 100 = 50%


============================================================
PATTERN 1 — MULTIPLE JOIN + FILTERING LOGIC
============================================================

QUESTION:

Find all ACTIVE customers from the NORTH region who placed
at least one COMPLETED order during September 2026.

Return:

CUSTOMER_ID
CUSTOMER_NAME
REGION_NAME
ORDER_COUNT
TOTAL_ORDER_AMOUNT

Requirements:

JOIN
GROUP BY
HAVING

Only COMPLETED orders should be counted.
Only September 2026 orders should be considered.


------------------------------------------------------------
MY ANSWER:
------------------------------------------------------------

SELECT C.CUSTOMER_ID,C.CUSTOMER_NAME,R.REGION_NAME,
COUNT(*) AS ORDER_COUNT
SUM(ORDER_AMOUNT) AS TOTAL_ORDER_AMOUNT
FROM CUSTOMER C
JOIN REGION R ON C.REGION_ID
JOIN ORDER O ON C.CUSTOMER_ID = O.CUSTOMER_ID
WHERE
C.STATUS = 'ACTIVE'
AND R.REGION_NAME = 'NORTH'
AND TO_CHAR(ORDER_DATE,'MON-RRRR') = 'SEP-2026'
AND ORDER_STATUS = 'COMPLETED';


------------------------------------------------------------
RESULT:
------------------------------------------------------------

WRONG


------------------------------------------------------------
MISTAKES:
------------------------------------------------------------

1. Missing join condition:

JOIN REGION R ON C.REGION_ID

must compare both columns:

C.REGION_ID = R.REGION_ID


2. Missing comma after:

COUNT(*) AS ORDER_COUNT


3. ORDER is problematic as a table name in many SQL contexts.
Use the actual table name as provided by the question,
ORDERS, and alias it.


4. GROUP BY is missing.

The result is one row per customer, so the customer-level
columns must be grouped.


5. HAVING is missing.

The question explicitly requires GROUP BY + HAVING.


------------------------------------------------------------
WHY I MADE THIS MISTAKE:
------------------------------------------------------------

I identified the correct tables and filters, but I did not
complete the full query structure.

The main thinking problem is:

I focused on WHERE conditions before identifying the
complete aggregation structure.

The required flow was:

JOIN
↓
WHERE
↓
GROUP BY
↓
HAVING


------------------------------------------------------------
KEY PATTERN:
------------------------------------------------------------

For reporting queries, identify the output grain first.

Here:

ONE ROW = ONE CUSTOMER


Therefore:

GROUP BY
C.CUSTOMER_ID,
C.CUSTOMER_NAME,
R.REGION_NAME


------------------------------------------------------------
CORRECT ANSWER:
------------------------------------------------------------

SELECT C.CUSTOMER_ID,
       C.CUSTOMER_NAME,
       R.REGION_NAME,
       COUNT(*) AS ORDER_COUNT,
       SUM(O.ORDER_AMOUNT) AS TOTAL_ORDER_AMOUNT
FROM CUSTOMER C
JOIN REGION R
    ON C.REGION_ID = R.REGION_ID
JOIN ORDERS O
    ON C.CUSTOMER_ID = O.CUSTOMER_ID
WHERE C.STATUS = 'ACTIVE'
  AND R.REGION_NAME = 'NORTH'
  AND TO_CHAR(O.ORDER_DATE,'MON-RRRR') = 'SEP-2026'
  AND O.ORDER_STATUS = 'COMPLETED'
GROUP BY C.CUSTOMER_ID,
         C.CUSTOMER_NAME,
         R.REGION_NAME
HAVING COUNT(*) >= 1;


------------------------------------------------------------
LESSON:
------------------------------------------------------------

For multi-table reporting:

1. Identify the driving/business entity.
2. Identify relationships.
3. Apply row-level filters.
4. Identify result grain.
5. GROUP BY the grain.
6. Use HAVING for aggregate conditions.


------------------------------------------------------------
REWRITE PRACTICE:
------------------------------------------------------------

REWRITE THIS QUERY YOURSELF WITHOUT LOOKING AT THE
CORRECT ANSWER.

STATUS:
PENDING REWRITE


============================================================
PATTERN 2 — LEFT JOIN + ON VS WHERE
============================================================

QUESTION:

Generate a report for ALL products showing their total
COMPLETED sales quantity during September 2026.

Products with no completed sales must still appear with:

TOTAL_QUANTITY = 0


------------------------------------------------------------
MY ANSWER:
------------------------------------------------------------

SELECT PRODUCT_ID,PRODUCT_NAME,
NVL(TOTAL_QUANTITY,0) AS TOTAL_QUANTITY
FROM
(
SELECT P.PRODUCT_ID,P.PRODUCT_NAME,
SUM(QUANTITY) AS TOTAL_QUANTITY
FROM PRODUCT P
LEFT JOIN SALES S
    ON P.PRODUCT_ID = S.PRODUCT_ID
   AND STATUS = 'COMPLETED'
WHERE TO_CHAR(SALE_DATE,'MON-RRRR') = 'SEP-2026'
);


------------------------------------------------------------
RESULT:
------------------------------------------------------------

PARTIALLY CORRECT


------------------------------------------------------------
WHAT WAS CORRECT:
------------------------------------------------------------

You correctly understood:

PRODUCT
↓
LEFT JOIN
↓
COMPLETED filter belongs in ON
↓
NVL


You correctly placed:

STATUS = 'COMPLETED'

inside the JOIN condition.


------------------------------------------------------------
MISTAKES:
------------------------------------------------------------

1. September filtering was placed in WHERE:

WHERE TO_CHAR(SALE_DATE,'MON-RRRR') = 'SEP-2026'


This removes products where SALE_DATE is NULL.

Therefore the LEFT JOIN effectively behaves like an
INNER JOIN for products with no matching sale.


The September condition must also be in ON.


2. GROUP BY is missing.

You are using SUM() together with PRODUCT_ID and
PRODUCT_NAME.


3. The outer query is unnecessary.


------------------------------------------------------------
WHY I MADE THIS MISTAKE:
------------------------------------------------------------

I correctly remembered that STATUS must go into ON,
but I treated the date condition separately.

The deeper mistake is not thinking of BOTH conditions as:

"Conditions defining which SALES rows are valid matches."

Therefore both should be part of the LEFT JOIN matching logic.


------------------------------------------------------------
KEY PATTERN:
------------------------------------------------------------

For a LEFT JOIN:

Conditions restricting the optional/matching table
often belong in ON when unmatched rows must survive.


Think:

PRODUCT
   ↓
LEFT JOIN
   ↓
Only matching September + COMPLETED SALES
   ↓
Products with no match remain


------------------------------------------------------------
CORRECT ANSWER:
------------------------------------------------------------

SELECT P.PRODUCT_ID,
       P.PRODUCT_NAME,
       NVL(SUM(S.QUANTITY),0) AS TOTAL_QUANTITY
FROM PRODUCT P
LEFT JOIN SALES S
    ON P.PRODUCT_ID = S.PRODUCT_ID
   AND S.STATUS = 'COMPLETED'
   AND S.SALE_DATE >= DATE '2026-09-01'
   AND S.SALE_DATE < DATE '2026-10-01'
GROUP BY P.PRODUCT_ID,
         P.PRODUCT_NAME;


------------------------------------------------------------
LESSON:
------------------------------------------------------------

With LEFT JOIN, always ask:

"Can this WHERE condition eliminate my unmatched
left-side rows?"

If yes, consider whether it belongs in ON instead.


------------------------------------------------------------
REWRITE PRACTICE:
------------------------------------------------------------

REWRITE THIS QUERY YOURSELF WITHOUT LOOKING AT THE
CORRECT ANSWER.

STATUS:
PENDING REWRITE


============================================================
PATTERN 3 — AGGREGATION BEFORE JOIN + MULTIPLE METRICS
============================================================

QUESTION:

For September 2026, generate a customer sales summary.

Return every customer, including customers with no
September orders.

Requirements:

CTE
GROUP BY
LEFT JOIN
Conditional aggregation
NVL()


------------------------------------------------------------
MY ANSWER:
------------------------------------------------------------

WITH CTE AS (
SELECT CUSTOMER_ID,
COUNT(*) AS TOTAL_ORDERS
SUM(CASE ORDER_STATUS = 'COMPLETED'
    THEN 1 ELSE 0) END AS COMPLETED_ORDERS
SUM(CASE ORDER_STATUS = 'CANCELLED'
    THEN 1 ELSE 0) END AS CANCELLED_ORDERS
SUM(ORDER_AMOUNT) AS TOTAL_SALES_AMOUNT
FROM ORDERS
WHERE TO_CHAR(ORDER_DATE,'MON-RRRR') = 'SEP-2026'
GROUP BY CUSTOMER_ID)

SELECT CUSTOMER_ID,CUSTOMER_NAME,NVL(TOTAL_ORDERS,0)
NVL(COMPLETED_ORDERS,0),
NVL(CANCELLED_ORDERS,0),
NVL(TOTAL_SALES_AMOUNT,0)
FROM CUSTOMER CU
LEFT JOIN CTE C
ON CU.CUSTOMER_ID = C.CUSTOMER_ID;


------------------------------------------------------------
RESULT:
------------------------------------------------------------

PARTIALLY CORRECT


------------------------------------------------------------
WHAT WAS CORRECT:
------------------------------------------------------------

The overall architecture is correct:

ORDERS
↓
September filter
↓
GROUP BY CUSTOMER_ID
↓
CTE
↓
LEFT JOIN CUSTOMER
↓
NVL()


You correctly understood that aggregation should happen
before joining to CUSTOMER.


------------------------------------------------------------
MISTAKES:
------------------------------------------------------------

1. Missing commas after aggregate expressions.

2. CASE syntax is incorrect.

You wrote:

CASE ORDER_STATUS = 'COMPLETED'
THEN ...

Correct:

CASE
    WHEN ORDER_STATUS = 'COMPLETED'
    THEN 1
    ELSE 0
END


3. Missing commas in the final SELECT.

4. Some calculated columns do not have explicit aliases.


------------------------------------------------------------
WHY I MADE THIS MISTAKE:
------------------------------------------------------------

Again, the query architecture was understood.

The repeated problem is execution precision.

I am identifying the correct building blocks but not
checking each SELECT expression individually before
submitting.


------------------------------------------------------------
KEY PATTERN:
------------------------------------------------------------

Complex SQL should be built in layers:

LAYER 1:
Filter the required data.

LAYER 2:
Aggregate at the correct grain.

LAYER 3:
Join the aggregated result.

LAYER 4:
Handle NULL values.


------------------------------------------------------------
CORRECT ANSWER:
------------------------------------------------------------

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
                   WHEN ORDER_STATUS = 'CANCELLED'
                   THEN 1
                   ELSE 0
               END
           ) AS CANCELLED_ORDERS,
           SUM(ORDER_AMOUNT) AS TOTAL_SALES_AMOUNT
    FROM ORDERS
    WHERE TO_CHAR(ORDER_DATE,'MON-RRRR') = 'SEP-2026'
    GROUP BY CUSTOMER_ID
)
SELECT CU.CUSTOMER_ID,
       CU.CUSTOMER_NAME,
       NVL(C.TOTAL_ORDERS,0) AS TOTAL_ORDERS,
       NVL(C.COMPLETED_ORDERS,0) AS COMPLETED_ORDERS,
       NVL(C.CANCELLED_ORDERS,0) AS CANCELLED_ORDERS,
       NVL(C.TOTAL_SALES_AMOUNT,0) AS TOTAL_SALES_AMOUNT
FROM CUSTOMER CU
LEFT JOIN CTE C
    ON CU.CUSTOMER_ID = C.CUSTOMER_ID;


------------------------------------------------------------
LESSON:
------------------------------------------------------------

Your query design was right.

The next improvement is writing complex queries in
small verified pieces instead of typing the entire
query at once.


------------------------------------------------------------
REWRITE PRACTICE:
------------------------------------------------------------

REWRITE THIS QUERY YOURSELF WITHOUT LOOKING AT THE
CORRECT ANSWER.

STATUS:
PENDING REWRITE


============================================================
PATTERN 4 — DUPLICATE BUSINESS TRANSACTIONS
============================================================

QUESTION:

Find duplicate invoice numbers within each customer.

Only POSTED invoices should be considered.

Return:

CUSTOMER_ID
INVOICE_NO
DUPLICATE_COUNT
FIRST_INVOICE_DATE
LAST_INVOICE_DATE
TOTAL_DUPLICATE_AMOUNT

Requirement:

GROUP BY
HAVING


------------------------------------------------------------
MY ANSWER:
------------------------------------------------------------

SELECT CUSTOMER_ID,INVOICE_NO,
COUNT(*) AS DUPLICATE_COUNT,
MIN(INVOICE_DATE) AS FIRST_INVOICE_DATE,
MAX(INVOICE_DATE) AS LAST_INVOICE_DATE,
SUM(INVOICE_AMOUNT) AS TOTAL_DUPLICATE_AMOUNT
FROM INVOICE
WHERE STATUS = 'POSTED'
GROUP BY CUSTOMER_ID,INVOICE_NO;


------------------------------------------------------------
RESULT:
------------------------------------------------------------

PARTIALLY CORRECT


------------------------------------------------------------
WHAT WAS CORRECT:
------------------------------------------------------------

You correctly identified the business key:

CUSTOMER_ID + INVOICE_NO


You correctly used:

WHERE STATUS = 'POSTED'

You correctly used:

GROUP BY CUSTOMER_ID, INVOICE_NO


You correctly calculated:

COUNT()
MIN()
MAX()
SUM()


------------------------------------------------------------
MISTAKE:
------------------------------------------------------------

The question specifically requires duplicate groups only.

You need:

HAVING COUNT(*) > 1


Without HAVING, your query returns ALL posted invoice
groups, including groups that occur only once.


------------------------------------------------------------
WHY I MADE THIS MISTAKE:
------------------------------------------------------------

I identified the duplicate key and calculated the
duplicate count, but I did not finish the filtering step.

The thinking should be:

GROUP BY
↓
Create one group per business key
↓
HAVING
↓
Keep only groups occurring more than once


------------------------------------------------------------
KEY PATTERN:
------------------------------------------------------------

Duplicate detection:

GROUP BY business_key
HAVING COUNT(*) > 1


------------------------------------------------------------
CORRECT ANSWER:
------------------------------------------------------------

SELECT CUSTOMER_ID,
       INVOICE_NO,
       COUNT(*) AS DUPLICATE_COUNT,
       MIN(INVOICE_DATE) AS FIRST_INVOICE_DATE,
       MAX(INVOICE_DATE) AS LAST_INVOICE_DATE,
       SUM(INVOICE_AMOUNT) AS TOTAL_DUPLICATE_AMOUNT
FROM INVOICE
WHERE STATUS = 'POSTED'
GROUP BY CUSTOMER_ID,
         INVOICE_NO
HAVING COUNT(*) > 1;


------------------------------------------------------------
LESSON:
------------------------------------------------------------

WHERE filters individual rows.

HAVING filters groups after aggregation.

"Find duplicates" usually means:

GROUP BY business key
+
HAVING COUNT(*) > 1


------------------------------------------------------------
REWRITE PRACTICE:
------------------------------------------------------------

REWRITE THIS QUERY YOURSELF WITHOUT LOOKING AT THE
CORRECT ANSWER.

STATUS:
PENDING REWRITE


============================================================
PATTERN 5 — LATEST ACTIVE PRICE + LEFT JOIN
============================================================

QUESTION:

Find the latest ACTIVE price for every product.

Rules:

Every product must appear.
Ignore INACTIVE records.
Return only the latest ACTIVE record.
Products without an ACTIVE price must still appear
with NULL price/date.

Requirements:

ROW_NUMBER()
LEFT JOIN


------------------------------------------------------------
MY ANSWER:
------------------------------------------------------------

WITH CTE AS
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

SELECT P.PRODUCT_ID,
       P.PRODUCT_NAME,
       C.PRICE,
       C.EFFECTIVE_DATE
FROM PRODUCT P
LEFT JOIN CTE C
ON P.PRODUCT_ID = C.PRODUCT_ID;


------------------------------------------------------------
RESULT:
------------------------------------------------------------

CORRECT


------------------------------------------------------------
EXPLANATION:
------------------------------------------------------------

You correctly:

1. Filtered ACTIVE records first.

2. Partitioned by PRODUCT_ID.

3. Ordered by EFFECTIVE_DATE DESC.

4. Selected the latest record using the ranking logic.

5. Used LEFT JOIN from PRODUCT.

Therefore products without an ACTIVE price still appear.


------------------------------------------------------------
CORRECT ANSWER:
------------------------------------------------------------

WITH CTE AS
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
SELECT P.PRODUCT_ID,
       P.PRODUCT_NAME,
       C.PRICE,
       C.EFFECTIVE_DATE
FROM PRODUCT P
LEFT JOIN CTE C
    ON P.PRODUCT_ID = C.PRODUCT_ID
WHERE C.RN = 1 OR C.RN IS NULL;


IMPORTANT NOTE:

Your submitted query is actually missing:

WHERE C.RN = 1

Therefore, if a product has multiple ACTIVE price records,
your query returns ALL ACTIVE price records.

So under strict execution grading, this answer is:

PARTIALLY CORRECT, not fully correct.


CORRECTED RESULT:

PARTIALLY CORRECT


WHY I MADE THIS MISTAKE:

I correctly built the CTE and calculated ROW_NUMBER(),
but forgot the final filtering step:

RN = 1


The pattern is:

FILTER ACTIVE
↓
ROW_NUMBER()
↓
RN = 1
↓
LEFT JOIN PRODUCT


KEY PATTERN:

Calculating ROW_NUMBER() is not enough.

You must also filter the generated ranking value.


REWRITE PRACTICE:

REWRITE THIS QUERY YOURSELF WITHOUT LOOKING AT THE
CORRECT ANSWER.

STATUS:
PENDING REWRITE


============================================================
DAY 11 — FINAL RESULT
============================================================

UPDATED STRICT RESULT:

PATTERN 1:
WRONG

PATTERN 2:
PARTIALLY CORRECT

PATTERN 3:
PARTIALLY CORRECT

PATTERN 4:
PARTIALLY CORRECT

PATTERN 5:
PARTIALLY CORRECT


TOTAL:
0 CORRECT
4 PARTIAL
1 WRONG


FULLY CORRECT:
0 / 5 = 0%

PARTIALLY CORRECT:
4 / 5 = 80%

WRONG:
1 / 5 = 20%

EFFECTIVE ACCURACY:
0 + (4 × 0.5)
= 2

2 / 5 × 100
= 40%


============================================================
IMPORTANT SCORING CORRECTION
============================================================

The initial quick score of:

1 Correct / 3 Partial / 1 Wrong

was too generous because Pattern 5 was initially treated
as complete even though RN = 1 was not applied.

The strict executable-query assessment is:

0 Correct
4 Partial
1 Wrong

Effective Accuracy:
40%


============================================================
DAY 11 MAIN WEAKNESSES
============================================================

1. SQL SYNTAX PRECISION

Repeated issues:
- Missing commas
- Incorrect CASE syntax
- Missing GROUP BY
- Missing HAVING


2. QUERY COMPLETION

You often build 80–90% of the correct structure but
miss the final condition/filter.

Examples:

Pattern 4:
GROUP BY present
but HAVING missing.

Pattern 5:
ROW_NUMBER() present
but RN = 1 filtering missing.


3. QUERY GRAIN

Pattern 1 required:

ONE ROW = ONE CUSTOMER

Pattern 3 required:

ONE ROW = ONE CUSTOMER

This must become automatic.


4. LEFT JOIN FILTERING

Pattern 2 exposed the ON vs WHERE issue.

Remember:

LEFT JOIN + optional table filtering
→ carefully decide whether the condition belongs in ON.


============================================================
MOST IMPORTANT THINKING MISTAKE
============================================================

I am often identifying the correct SQL pattern but
not completing the entire logical pipeline.

I need to think:

REQUIREMENT
↓
DATASET
↓
FILTER
↓
GRAIN
↓
AGGREGATION / WINDOW
↓
FINAL FILTER
↓
OUTPUT


============================================================
DAY 11 REWRITE REQUIREMENT
============================================================

Patterns requiring active rewrite:

Pattern 1 — WRONG
Pattern 2 — PARTIAL
Pattern 3 — PARTIAL
Pattern 4 — PARTIAL
Pattern 5 — PARTIAL

Do not memorize the corrected queries.

Rewrite each query from the requirement.


============================================================
CHALLENGE PROGRESS
============================================================

DAYS COMPLETED:
11 / 100

TOTAL QUESTIONS ATTEMPTED:
55 / 500

DAY 11:
0 CORRECT
4 PARTIAL
1 WRONG

DAY 11 FULL ACCURACY:
0%

DAY 11 EFFECTIVE ACCURACY:
40%


HISTORICAL DAYS 1–10:
UNCHANGED


============================================================
END OF DAY 11
============================================================