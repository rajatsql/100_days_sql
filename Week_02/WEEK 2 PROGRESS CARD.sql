==================================================
SQL CHALLENGE — WEEK 2 PROGRESS CARD
====================================

DAYS COMPLETED:
7 / 7

DAYS:
8 – 14

TOTAL QUERIES:
35

==================================================
RESULT
======

FULLY CORRECT:
13 / 35 = 37.1%

PARTIALLY CORRECT:
17 / 35 = 48.6%

WRONG:
5 / 35 = 14.3%

EFFECTIVE ACCURACY:
61.43%

==================================================
WEEK 1 vs WEEK 2
================

WEEK 1:

FULLY CORRECT:
17 / 35 = 48.6%

PARTIALLY CORRECT:
12 / 35 = 34.3%

WRONG:
5 / 35 = 14.3%

EFFECTIVE ACCURACY:
65.7%

WEEK 2:

FULLY CORRECT:
13 / 35 = 37.1%

PARTIALLY CORRECT:
17 / 35 = 48.6%

WRONG:
5 / 35 = 14.3%

EFFECTIVE ACCURACY:
61.43%

CHANGE:

FULLY CORRECT:
48.6% → 37.1%
↓ 11.5 percentage points

PARTIALLY CORRECT:
34.3% → 48.6%
↑ 14.3 percentage points

WRONG:
14.3% → 14.3%
NO CHANGE

EFFECTIVE ACCURACY:
65.7% → 61.43%
↓ 4.27 percentage points

==================================================
CURRENT SQL LEVEL
=================

LOWER-INTERMEDIATE
→ DEVELOPING TOWARD INTERMEDIATE

NOT A BEGINNER ANYMORE.

PATTERN KNOWLEDGE IS DEVELOPING WELL.

BUT COMPLEX SQL IMPLEMENTATION
IS STILL NOT CONSISTENT.

==================================================
STRONG AREAS
============

BASIC SQL PATTERN RECOGNITION
GOOD

GROUP BY + HAVING
GOOD

BASIC JOIN
GOOD

WINDOW FUNCTIONS
GOOD

ROW_NUMBER()
GOOD

DENSE_RANK()
GOOD

LEFT JOIN
DEVELOPING

NOT EXISTS
GOOD

CONDITIONAL AGGREGATION
DEVELOPING

CTE
DEVELOPING

==================================================
MEDIUM AREAS
============

COMPLEX JOIN CONDITIONS
DEVELOPING

LEFT JOIN + ON vs WHERE
DEVELOPING

LATEST RECORD LOGIC
DEVELOPING

AGGREGATION BEFORE JOIN
DEVELOPING

DATE FILTERING
DEVELOPING

MULTI-TABLE REPORTING
DEVELOPING

NULL HANDLING
DEVELOPING

==================================================
WEAK AREAS
==========

MULTI-TABLE AGGREGATION
WEAK

QUERY GRAIN
WEAK → DEVELOPING

ROW MULTIPLICATION
WEAK

COMPLEX QUERY COMPOSITION
WEAK → DEVELOPING

SQL SYNTAX PRECISION
WEAK

DATE FILTERING
INCONSISTENT

FINAL QUERY COMPLETION
INCONSISTENT

BUSINESS REQUIREMENT → SQL TRANSLATION
DEVELOPING

==================================================
BIGGEST PROBLEM
===============

I often understand WHAT SQL pattern is required,

but struggle to convert that understanding into
a complete and technically correct query.

Common Week 2 problems:

* Missing commas
* Incorrect aliases
* Incorrect column/status names
* Missing GROUP BY
* Incorrect date conditions
* Incorrect LEFT JOIN filtering
* Missing aggregation
* Incorrect aggregation level
* Missing RN = 1
* Incorrect driving table
* Joining tables before aggregation
* Row multiplication
* NULL handling
* Incomplete JOIN conditions
* Filtering the wrong table
* Correct idea but incomplete final SQL

==================================================
BIGGEST STRENGTH
================

I am increasingly able to recognize
the required SQL pattern.

I can identify and work with:

* GROUP BY
* HAVING
* JOIN
* LEFT JOIN
* EXISTS
* NOT EXISTS
* CASE
* CTE
* ROW_NUMBER
* RANK
* DENSE_RANK
* LAG
* LEAD
* Conditional aggregation
* Latest-record logic
* Aggregation before JOIN
* ON vs WHERE

The main gap is no longer simply:

"Do I know this SQL pattern?"

The bigger gap is:

"Can I implement the pattern completely
without breaking the query logic?"

==================================================
WEEK 2 LEARNING
===============

The most important Week 2 lesson was:

REQUIREMENT
↓
FILTER
↓
AGGREGATION
↓
JOIN
↓
FINAL RESULT

Especially when multiple tables are involved:

DO NOT JOIN DETAIL TABLES FIRST
AND THEN TRY TO FIX THE DUPLICATES.

Instead:

AGGREGATE EACH DETAIL SOURCE
TO THE REQUIRED GRAIN
BEFORE JOINING.

Example:

ORDERS
→ aggregate by CUSTOMER

PAYMENTS
→ aggregate by CUSTOMER

CUSTOMER
→ LEFT JOIN order summary
→ LEFT JOIN payment summary

This prevents:

1 CUSTOMER
× MANY ORDERS
× MANY PAYMENTS

from multiplying rows.

==================================================
WEEK 2 PATTERN PROGRESS
=======================

DAY 8:
4 CORRECT / 1 WRONG

DAY 9:
4 CORRECT / 1 PARTIAL

DAY 10:
3 CORRECT / 2 PARTIAL

DAY 11:
0 CORRECT / 4 PARTIAL / 1 WRONG

DAY 12:
1 CORRECT / 2 PARTIAL / 2 WRONG

DAY 13:
1 CORRECT / 3 PARTIAL / 1 WRONG

DAY 14:
0 CORRECT / 4 PARTIAL / 1 WRONG

WEEK 2 TOTAL:

13 CORRECT
17 PARTIAL
5 WRONG

==================================================
WEEK 2 VERDICT
==============

KNOWLEDGE:
GOOD

PATTERN RECOGNITION:
GOOD

BASIC SQL:
GOOD

QUERY WRITING:
DEVELOPING

SYNTAX ACCURACY:
WEAK → DEVELOPING

COMPLEX QUERY HANDLING:
WEAK → DEVELOPING

MULTI-TABLE SQL:
DEVELOPING

QUERY GRAIN:
DEVELOPING

ROW MULTIPLICATION AWARENESS:
DEVELOPING

BUSINESS SQL:
DEVELOPING

INTERVIEW READINESS:
NOT READY YET

OFFICE SQL:
DEVELOPING

==================================================
WEEK 2 SCORE
============

FULLY CORRECT:
37.1%

EFFECTIVE ACCURACY:
61.43%

WRONG:
14.3%

==================================================
WEEK 1 → WEEK 2
===============

FULLY CORRECT:
48.6% → 37.1%

EFFECTIVE ACCURACY:
65.7% → 61.43%

WRONG:
14.3% → 14.3%

IMPORTANT:

The percentage went down this week,

but the difficulty of the questions
also increased significantly.

The major focus shifted from recognizing
individual SQL patterns toward combining
multiple patterns in business-style queries.

==================================================
MAIN FOCUS FOR WEEK 3
=====================

1. SQL syntax precision

2. Complete query writing

3. Multi-table JOINs

4. Query grain

5. Row multiplication

6. Aggregation before JOIN

7. LEFT JOIN preservation

8. Date filtering

9. NULL handling

10. Real-world ERP/business reporting

11. Combining 2–3 SQL patterns

12. Translating business requirements into SQL

==================================================
WEEK 3 TARGET
=============

FULLY CORRECT:

37.1% → 50%+

EFFECTIVE ACCURACY:

61.43% → 70%+

WRONG:

14.3% → <10%

MAIN OBJECTIVE:

Convert pattern recognition
into reliable query implementation.

==================================================
IMPORTANT CHANGE FROM WEEK 3
============================

The challenge should remain approximately:

20–30 MINUTES PER DAY

I ONLY NEED TO:

1. Read the requirement
2. Identify the SQL pattern
3. Write the SQL
4. Submit the answer

I DO NOT NEED TO WRITE:

PATTERN:
GRAIN:
DRIVING TABLE:
PLAN:

These concepts will be evaluated internally
during review rather than becoming additional
work for every question.

==================================================
END OF WEEK 2
=============
