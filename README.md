# NOVA Pharmacy Database (Oracle SQL/PLSQL)

Relational database project for **NOVA**, a pharmacy chain that sells drugs from multiple pharmaceutical companies. The schema tracks pharmacies, companies, drugs, doctors, patients, prescriptions, contracts, and pharmacy-specific drug pricing. Business rules are enforced using constraints, triggers, and stored procedures.

## Contents
- `DBS Project Specifications.pdf` — project/problem specification.
- `create_tables.sql` — drops existing tables in the current schema, creates tables + triggers.
- `insert_data.sql` — inserts sample/dummy data.
- `procedures.sql` — stored procedures for inserts/updates/reports.
- `demo.sql` — example procedure calls.
- `project_idea.md` / `implementation.md` — write-ups and implementation notes.

## Prerequisites
- Oracle Database (or Oracle-compatible SQL/PLSQL environment)
- SQL*Plus or Oracle SQL Developer

## Quick start (recommended order)
Run these in the **same Oracle user/schema**:
1. `@create_tables.sql`
2. `@insert_data.sql`
3. `@procedures.sql`
4. `@demo.sql`

If using SQL Developer, use **Run Script (F5)** (not “Run Statement”) and enable **DBMS Output**.

## Notes
- `create_tables.sql` drops **all** tables in the current schema (`user_tables`) before recreating them.
- `insert_data.sql` temporarily disables the “pharmacy sells at least 10 drugs” trigger during load, then re-enables it.
- `demo.sql` may include plain `SELECT * ...` statements inside a `BEGIN ... END;` block; that is not valid PL/SQL. Run `SELECT` statements as standalone SQL statements outside PL/SQL blocks (or change them to `SELECT ... INTO ...`).

## Key rules enforced
- Each patient has exactly one primary physician (`PatientDoctor` with PK on patient).
- A doctor cannot lose their last patient (trigger on `PatientDoctor` delete).
- Each pharmacy must sell at least 10 drugs (trigger on `PharmacyDrugs`).

