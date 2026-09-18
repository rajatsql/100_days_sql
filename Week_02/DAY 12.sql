==================================================
SQL CHALLENGE — DAY 12 REVIEW
==================================================

TOTAL QUESTIONS:
5

RESULT:
--------------------------------------------------

Q1 — LEFT JOIN + ON vs WHERE
RESULT: 🟡 PARTIALLY CORRECT

YOUR ANSWER:
SELECT C.CUSTOMER_ID,C.CUSTOMER_NAME,PP.TOTAL_PAYMENT
FROM CUSTOMER C
LEFT JOIN
(
    SELECT P.CUSTOMER_ID AS CUSTOMER_ID,
           SUM(P.AMOUNT) AS TOTAL_PAYMENT
    FROM PAYMENT P
    WHERE P.STATUS = 'COMPLETED'
      AND TO_CHAR(P.PAYMENT_DATE,'MON-RRRR') ='SEP-2026'
) PP
ON C.CUSTOMER_ID = PP.CUSTOMER_ID
WHERE C.STATUS = 'ACTIVE';

EXPLANATION:
Your overall architecture is correct:
- CUSTOMER is the driving table.
- LEFT JOIN is used.
- Payment filters are inside the payment subquery.
- ACTIVE customer filtering is correctly applied to CUSTOMER.
- Payment data is aggregated before joining.

However, the payment subquery is missing:

GROUP BY P.CUSTOMER_ID

Also, customers without payments will receive NULL, not 0.
The requirement specifically asks for TOTAL_PAYMENT = 0.

CORRECT ANSWER:
SELECT C.CUSTOMER_ID,
       C.CUSTOMER_NAME,
       NVL(PP.TOTAL_PAYMENT, 0) AS TOTAL_PAYMENT
FROM CUSTOMER C
LEFT JOIN
(
    SELECT P.CUSTOMER_ID,
           SUM(P.AMOUNT) AS TOTAL_PAYMENT
    FROM PAYMENT P
    WHERE P.STATUS = 'COMPLETED'
      AND P.PAYMENT_DATE >= DATE '2026-09-01'
      AND P.PAYMENT_DATE < DATE '2026-10-01'
    GROUP BY P.CUSTOMER_ID
) PP
ON C.CUSTOMER_ID = PP.CUSTOMER_ID
WHERE C.STATUS = 'ACTIVE';

KEY PATTERN / LESSON:
LEFT JOIN preserves the driving-table rows.
Aggregate the optional table at the JOIN keys grain.
Use NVL/COALESCE when missing related data must become 0.

Underlying thinking mistake:
You identified the correct architecture but stopped before completing the aggregation/output requirements.


==================================================
Q2 — GROUP BY + HAVING
RESULT: 🔴 WRONG

YOUR ANSWER:
SELECT P.PRODUCT_ID,
       P.PRODUCT_NAME,
       COUNT(*) AS SALE_COUNT,
       SUM(S.QUANTITY) AS TOTAL_QUANTITY,
       SUM(S.AMOUNT)TOTAL_AMOUNT AS
FROM PRODUCT P
JOIN SALES S
ON P.PRODUCT_ID = S.PRODUCT_ID
WHERE P.STATUS = 'COMPLETED'
GROUP BY P.PRODUCT_ID,P.PRODUCT_NAME
HAVING COUNT(*) >=3;

EXPLANATION:
There are several major issues:

1. COMPLETED is a SALES status, not PRODUCT status.
   You used:
   WHERE P.STATUS = 'COMPLETED'

   It should be:
   S.STATUS = 'COMPLETED'

2. September 2026 filtering is completely missing.

3. TOTAL_AMOUNT syntax is invalid:
   SUM(S.AMOUNT)TOTAL_AMOUNT AS

4. The required sales filter is therefore not being applied.

Your GROUP BY and HAVING structure were recognized correctly.

CORRECT ANSWER:
SELECT P.PRODUCT_ID,
       P.PRODUCT_NAME,
       COUNT(*) AS SALE_COUNT,
       SUM(S.QUANTITY) AS TOTAL_QUANTITY,
       SUM(S.AMOUNT) AS TOTAL_AMOUNT
FROM PRODUCT P
JOIN SALES S
  ON P.PRODUCT_ID = S.PRODUCT_ID
WHERE S.STATUS = 'COMPLETED'
  AND S.SALE_DATE >= DATE '2026-09-01'
  AND S.SALE_DATE < DATE '2026-10-01'
GROUP BY P.PRODUCT_ID,
         P.PRODUCT_NAME
HAVING COUNT(*) >= 3;

KEY PATTERN / LESSON:
Always identify which table owns the filtering column.

Business requirement:
"COMPLETED sales in September"

Therefore:
SALES.STATUS
SALES.SALE_DATE

Underlying thinking mistake:
You recognized GROUP BY + HAVING but did not map the business conditions to the correct table/columns before writing the query.


==================================================
Q3 — AGGREGATION BEFORE JOIN
RESULT: 🔴 WRONG

YOUR ANSWER:
WITH CTE AS
(
    SELECT INVOICE_ID,
           COUNT(*) AS TOTAL_INVOICES,
           SUM(CASE WHEN STATUS ='POSTED' THEN 1 ELSE 0 END) AS POSTED_INVOICES,
           SUM(CASE WHEN STATUS ='CANCELLED' THEN 1 ELSE 0 END) AS CANCELLED_INVOICES,
           SUM(CASE WHEN STATUS ='POSTED' THEN INVOICE_AMOUNT ELSE 0 END) AS TOTAL_POSTED_AMOUNT
    FROM INVOICE
    GROUP BY INVOICE_ID
)

SELECT B.BRANCH_ID,
       B.BRANCH_NAME,
       B.REGION
       NVL(C.TOTAL_INVOICES,0),
       NVL(C.POSTED_INVOICES,0),
       NVL(C.CANCELLED_INVOICES,0),
       NVL(C.TOTAL_POSTED_AMOUNT,0)
FROM BRANCH
LEFT JOIN CTE C
ON B.BRANCH_ID = C.BRANCH_ID;

EXPLANATION:
The required pattern was identified, but the CTE has the wrong grain.

The report is:
ONE ROW PER BRANCH

Therefore the CTE must aggregate by:

BRANCH_ID

You grouped by INVOICE_ID, which produces one row per invoice instead of one row per branch.

Other problems:
- BRANCH_ID is not selected in the CTE.
- September filtering is missing.
- B is referenced but BRANCH was not aliased as B.
- Missing comma after B.REGION.
- Missing aliases for the NVL output columns.

CORRECT ANSWER:
WITH CTE AS
(
    SELECT BRANCH_ID,
           COUNT(*) AS TOTAL_INVOICES,
           SUM(CASE WHEN STATUS = 'POSTED' THEN 1 ELSE 0 END) AS POSTED_INVOICES,
           SUM(CASE WHEN STATUS = 'CANCELLED' THEN 1 ELSE 0 END) AS CANCELLED_INVOICES,
           SUM(CASE WHEN STATUS = 'POSTED' THEN INVOICE_AMOUNT ELSE 0 END) AS TOTAL_POSTED_AMOUNT
    FROM INVOICE
    WHERE INVOICE_DATE >= DATE '2026-09-01'
      AND INVOICE_DATE < DATE '2026-10-01'
    GROUP BY BRANCH_ID
)
SELECT B.BRANCH_ID,
       B.BRANCH_NAME,
       B.REGION,
       NVL(C.TOTAL_INVOICES, 0) AS TOTAL_INVOICES,
       NVL(C.POSTED_INVOICES, 0) AS POSTED_INVOICES,
       NVL(C.CANCELLED_INVOICES, 0) AS CANCELLED_INVOICES,
       NVL(C.TOTAL_POSTED_AMOUNT, 0) AS TOTAL_POSTED_AMOUNT
FROM BRANCH B
LEFT JOIN CTE C
  ON B.BRANCH_ID = C.BRANCH_ID;

KEY PATTERN / LESSON:
Before writing GROUP BY, ask:

"WHAT SHOULD ONE ROW REPRESENT?"

Here:
ONE ROW = ONE BRANCH

Therefore:
GROUP BY BRANCH_ID

This is the same query-grain issue that appeared in your earlier challenge.


==================================================
Q4 — DUPLICATE DETECTION + BUSINESS FILTER
RESULT: 🟢 CORRECT

YOUR ANSWER:
SELECT S.PRODUCT_ID,
       S.BRANCH_ID,
       S.TRANSACTION_DATE,
       COUNT(*) AS RECEIPT_COUNT,
       SUM(QUANTITY) AS TOTAL_QUANTITY
FROM STOCK_TRANSACTION S
WHERE S.TRANSACTION_TYPE = 'RECEIPT'
GROUP BY S.PRODUCT_ID,
         S.BRANCH_ID,
         S.TRANSACTION_DATE
HAVING COUNT(*) > 1;

EXPLANATION:
Correct.

You correctly:
- Filtered RECEIPT transactions.
- Used the required business grain.
- Grouped by PRODUCT_ID + BRANCH_ID + TRANSACTION_DATE.
- Counted transactions.
- Summed quantity.
- Used HAVING COUNT(*) > 1.
- Did not use a window function.

KEY PATTERN / LESSON:
For duplicate detection:

1. Define the duplicate key.
2. GROUP BY that key.
3. HAVING COUNT(*) > 1.


==================================================
Q5 — LATEST ACTIVE CREDIT RECORD
RESULT: 🟡 PARTIALLY CORRECT

YOUR ANSWER:
WITH CTE AS
(
    SELECT CC.CUSTOMER_ID AS CUSTOMER_ID,
           CC.CREDIT_LIMIT AS CREDIT_LIMIT,
           CC.EFFECTIVE_DATE AS EFFECTIVE_DATE,
           ROW_NUMBER() OVER
           (
               PARTITION BY CC.CUSTOMER_ID ,
               ORDER BY CC.EFFECTIVE_DATE DESC
           ) AS RN
    FROM CUSTOMER_CREDIT CC
    WHERE STATUS = 'ACTIVE'
)
SELECT CR.CUSTOMER_ID,
       CR.CUSTOMER_NAME,
       C.CREDIT_LIMIT,
       C.EFFECTIVE_DATE
FROM CUSTOMER CR
LEFT JOIN CTE C
ON CR.CUSTOMER_ID = C.CUSTOMER_ID
AND RN = 1;

EXPLANATION:
The main architecture is correct:

CUSTOMER
   ↓ LEFT JOIN
latest ACTIVE CUSTOMER_CREDIT

And putting RN = 1 in the ON condition is appropriate here because it preserves customers who have no matching active credit record.

Problems:

1. ROW_NUMBER syntax is incorrect.

You wrote:
PARTITION BY CC.CUSTOMER_ID ,
ORDER BY ...

There should not be a comma after CUSTOMER_ID.

2. You did not filter ACTIVE customers from CUSTOMER.

The requirement says:
"for every ACTIVE customer"

You need:
WHERE CR.STATUS = 'ACTIVE'

3. STATUS should preferably be qualified as CC.STATUS.

CORRECT ANSWER:
WITH CTE AS
(
    SELECT CC.CUSTOMER_ID,
           CC.CREDIT_LIMIT,
           CC.EFFECTIVE_DATE,
           ROW_NUMBER() OVER
           (
               PARTITION BY CC.CUSTOMER_ID
               ORDER BY CC.EFFECTIVE_DATE DESC
           ) AS RN
    FROM CUSTOMER_CREDIT CC
    WHERE CC.STATUS = 'ACTIVE'
)
SELECT CR.CUSTOMER_ID,
       CR.CUSTOMER_NAME,
       C.CREDIT_LIMIT,
       C.EFFECTIVE_DATE
FROM CUSTOMER CR
LEFT JOIN CTE C
  ON CR.CUSTOMER_ID = C.CUSTOMER_ID
 AND C.RN = 1
WHERE CR.STATUS = 'ACTIVE';

KEY PATTERN / LESSON:
For latest-record problems:

1. Filter valid records.
2. Partition by business key.
3. ORDER BY latest date DESC.
4. Assign ROW_NUMBER().
5. Keep RN = 1.
6. LEFT JOIN if every master record must remain.

Important:
Filtering RN = 1 in the ON clause preserves unmatched customers.


==================================================
DAY 12 RESULT
==================================================

TOTAL QUESTIONS:
5

🟢 FULLY CORRECT:
1

🟡 PARTIALLY CORRECT:
2

🔴 WRONG:
2

STRICT SCORE:
1 / 5 = 20%

EFFECTIVE ACCURACY:
Correct = 1
Partial = 2 × 0.5 = 1

Effective points = 2 / 5

EFFECTIVE ACCURACY = 40%


==================================================
DAY 12 MAIN FINDINGS
==================================================

STRONG:
- Duplicate detection
- GROUP BY + HAVING structure
- Recognizing LEFT JOIN architecture
- Recognizing ROW_NUMBER() latest-record pattern

WEAK:
- Query grain
- Correct table/column for business filters
- Date filtering
- SQL syntax precision
- Completing every requirement
- Tracking all required conditions before writing SQL


MOST IMPORTANT PATTERN TO REMEMBER:

REQUIREMENT
→ TABLE
→ FILTER
→ GRAIN
→ AGGREGATION / WINDOW
→ FINAL FILTER
→ JOIN
→ OUTPUT


==================================================
WEEK 2 PROGRESS SO FAR
==================================================

DAYS COMPLETED:
12 / 100

WEEK 2 QUESTIONS:
25

DAY 12:
1 Correct
2 Partial
2 Wrong

NO REWRITE PRACTICE INCLUDED
==================================================