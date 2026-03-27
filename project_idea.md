# NOVA Pharmacy Database — Project Idea

## Overview
This project models a relational database for **“NOVA”**, a chain of pharmacies that sells drugs produced by multiple pharmaceutical companies. The database captures operational data needed to manage **pharmacies**, **drug catalogs and pricing**, **patients and doctors**, **prescriptions**, and **company–pharmacy contracts**, while enforcing key business rules via constraints, triggers, and PL/SQL stored procedures.

The implementation in this repository targets an **Oracle-style SQL/PLSQL** environment (e.g., SQL*Plus / SQL Developer) and follows the provided specification in `DBS Project Specifications.pdf`.

## Problem Statement
NOVA needs a structured way to:
- Maintain master records for **patients**, **doctors**, **pharmacies**, **pharmaceutical companies**, and **drugs**.
- Track which **pharmacies sell which drugs** (with pharmacy-specific prices).
- Record **prescriptions** issued by doctors to patients, including the set of drugs and quantities per prescription.
- Manage **contracts** between pharmacies and companies, including contract periods, content, and an assigned supervisor (doctor).
- Enforce real-world rules such as *each patient having a primary physician*, *each doctor having at least one patient*, and *each pharmacy selling at least 10 drugs*.

## Core Entities & Relationships (Conceptual)
- **Patient** (`AadharID`, name, address, age)
- **Doctor** (`AadharID`, name, specialty, years of experience)
- **PharmaceuticalCompany** (name, phone)
- **Drug** (trade name, formula) produced by exactly one company; unique per company
- **Pharmacy** (name, address, phone)
- **Primary Physician**: each patient maps to one doctor (primary physician)
- **Pharmacy Stock/Pricing**: many-to-many between pharmacies and drugs with **price**
- **Prescription**: doctor → patient, with date; contains multiple drugs with quantities
- **Contract**: company ↔ pharmacy, with start/end dates, content, supervisor (doctor)

## Key Business Rules (from the spec)
- Each patient has exactly one **primary physician**.
- Every doctor has **at least one patient**.
- Each pharmacy sells **at least 10 drugs**; each pharmacy sets its own price per drug.
- Doctors can prescribe multiple drugs; a patient can have prescriptions from many doctors.
- A doctor can issue **at most one prescription per patient per date**.
- If a doctor issues multiple prescriptions to the same patient over time, **only the latest prescription** for that patient–doctor pair is kept.
- If a pharmaceutical company is deleted, its drugs do **not** need to be retained.

## What This Repo Implements
The SQL/PLSQL scripts implement:
- A normalized schema with primary/foreign keys and checks.
- Triggers to enforce:
  - “pharmacy sells at least 10 drugs”
  - “doctor has at least one patient”
- Stored procedures for:
  - Data entry (add patient/doctor/company/drug/pharmacy/contract/prescription)
  - Updates (change contract supervisor)
  - Deletions (delete patient)
  - Reports required in the spec (prescription history, prescription details, stock, etc.)

## Suggested Extensions (optional ideas)
If you want to extend the project beyond the minimum requirements:
- Add procedures for **delete/update** for all entities (doctor, pharmacy, company, drug, contract).
- Add validation that prescribed drugs are actually stocked by at least one pharmacy (or a chosen pharmacy).
- Add audit/history tables (e.g., contract supervisor change log).
- Add inventory quantities per pharmacy (current model stores price, not inventory count).
- Add indexes for common report filters (patient/date, doctor/patient, company/drug).

