# AGENTS.md — cs486-demo

CS486 database systems teaching demo. Repository is empty; expect code to be added during sessions.

## Recurring context

- Root directory: `D:\APCS\Introduction to Database Systems\project\project4`
- This is a demo project, not production.
- Run `ls -la` to detect new files before assuming anything exists.

# Database Design Agent Rules

This project transforms business requirements into database design artifacts.

## Workflow Order
Always follow this order:

1. Analyze business requirements.
2. Produce conceptual ERD using Crow's Foot notation.
3. Design logical database.
4. Validate database design.
5. Implement database.
6. Prepare sample data.
7. Design query.

Do not jump directly to DDL. The documents from the prior steps should be followed in the later steps.

## Required Outputs

- `outputs/01-business-requirement-analysis-G01.md`
- `outputs/02-conceptual-design-erd-G01.md`
- `outputs/03-logical-design-G01.md`
- `outputs/04-design-validation-G01.md`
- `outputs/05-db-definition-G01.sql`
- `outputs/06-sample-data-G01.sql`
- `outputs/07-query-design-G01.sql`

## DBMS

Use Microsoft SQL Server unless the user specifies another DBMS.

## Design Rules

- Record assumptions explicitly.
- Record open questions explicitly.
- Preserve traceability from requirement → entity → relationship → table → constraint.
- Use Mermaid `erDiagram` for ERD.
- Do not silently invent business rules.
