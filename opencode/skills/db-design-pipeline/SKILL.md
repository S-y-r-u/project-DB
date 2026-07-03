cat > .opencode/skills/db-design-pipeline/SKILL.md <<'EOF'
---
name: db-design-pipeline
description: Analyze business requirements and produce conceptual ERD, logical database design, and DDL documents step by step.
compatibility: opencode
---

# Database Design Pipeline Skill

Use this skill when the user asks to transform business requirements into a database design.

## Important behavior

Before assuming anything, inspect the project:

1. Run `ls -la`.
2. Locate requirement files under `req/`, `docs/`, or files passed by the user.
3. Read the relevant requirement files fully before designing.
4. If the requirement is incomplete, continue with explicit assumptions, but also create an unresolved questions section.

## Required output files

Create or update the following files:

1. `outputs/01-business-requirement-analysis-G01.md`
2. `outputs/02-conceptual-design-erd-G01.md`
3. `outputs/03-logical-design-G01.md`
4. `outputs/04-design-validation-G01.md`
5. `outputs/05-db-definition-G01.sql`
6. `outputs/06-sample-data-G01.sql`
7. `outputs/07-query-design-G01.sql`

Do not skip any Markdown file.

---

# Step 1: Business Requirement Analysis

Save to:

`outputs/01-business-requirement-analysis-G01.md`

Analyze the requirements to identify the business purpose, actors, entities, attributes, relationships, cardinalities, and business rules.

# Step 2: Conceptual Design / ERD

Save to:

`outputs/02-conceptual-design-erd-G01.md`

Design an ERD showing the main entities, attributes, relationships, cardinalities, and participation constraints.

# Step 3: Logical Database Design

Save to:

`outputs/03-logical-design-G01.md`

Convert the ERD into a relational schema with relations, attributes, primary keys, foreign keys, candidate keys, and key constraints.

# Step 4: Database Design Validation

Save to:

`outputs/04-design-validation-G01.md`

Evaluate whether the relational schema correctly represents the ERD, satisfies the business rules, and uses appropriate keys, relationships, and constraints.

# Step 5: Database Implementation

Save to:

`outputs/05-db-definition-G01.sql`

Implement the database using SQL DDL with tables, keys, constraints, checks, and default values where appropriate.

# Step 6: Sample Data Preparation

Save to:

`outputs/06-sample-data-G01.sql`

Insert realistic sample data to support testing of normal operations and important exceptional cases.

# Step 7: Query Design

Save to:

`outputs/07-query-design-G01.sql`

Design and execute at least 5 meaningful SQL queries that are valid for the database and useful for answering business questions in the given context. Each query must include:
- Business question
- Target user(s) that would use the query
- Short explanation of why the query is useful
- SQL statement