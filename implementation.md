# NOVA Pharmacy Database — Implementation Notes

## Tech Assumptions
The scripts use Oracle-style SQL/PLSQL features (`VARCHAR2`, `DBMS_OUTPUT`, `CREATE OR REPLACE PROCEDURE`, triggers), so the intended runtime is:
- **Oracle Database** (or an Oracle-compatible environment)
- Run via **SQL*Plus** or **Oracle SQL Developer** (Run Script)

## Repository Structure
- `DBS Project Specifications.pdf` — problem statement + required functionality.
- `create_tables.sql` — drops existing tables, creates schema, adds triggers.
- `insert_data.sql` — inserts dummy data (patients, doctors, companies, drugs, pharmacies, etc.).
- `procedures.sql` — stored procedures for CRUD-like operations and reports.
- `demo.sql` — demo script that calls stored procedures.

## Setup / Execution Order
Run the scripts in this order in the same Oracle schema/user:
1. `@create_tables.sql`
2. `@insert_data.sql`
3. `@procedures.sql`
4. `@demo.sql`

If using SQL Developer, prefer **Run Script (F5)** so that `DBMS_OUTPUT` and multiple blocks behave as expected; also enable `DBMS Output`.

## Schema (Tables, Keys, and FKs)
Implemented in `create_tables.sql`.

**Master tables**
- `Patients(AadharID PK, Name, Address, Age CHECK Age>=0)`
- `Doctors(AadharID PK, Name, Specialty, YearsOfExperience CHECK >=0)`
- `PharmaceuticalCompanies(CompanyName PK, PhoneNumber)`
- `Pharmacies(PharmacyName PK, Address, Phone)`

**Dependent/relationship tables**
- `Drugs(CompanyName FK -> PharmaceuticalCompanies, TradeName, Formula, PK(CompanyName, TradeName))`
  - Uses `ON DELETE CASCADE` so drugs are removed when a company is deleted.
- `PatientDoctor(PatientAadharID PK -> Patients, DoctorAadharID FK -> Doctors)`
  - Primary key on patient enforces “one primary physician per patient”.
- `PharmacyDrugs(PharmacyName FK -> Pharmacies, CompanyName+TradeName FK -> Drugs, Price CHECK Price>=0, PK(PharmacyName,CompanyName,TradeName))`
  - Captures “pharmacy sells drug” with pharmacy-specific price.
- `Contracts(ContractID PK, PharmacyName FK -> Pharmacies, CompanyName FK -> PharmaceuticalCompanies, StartDate, EndDate, Content, SupervisorAadharID FK -> Doctors)`
  - Models company–pharmacy contracts with a supervisor.
- `Prescriptions(PrescriptionID PK, PatientAadharID FK -> Patients, DoctorAadharID FK -> Doctors, PrescriptionDate)`
- `PrescriptionDrugs(PrescriptionID FK -> Prescriptions, CompanyName+TradeName FK -> Drugs, Quantity CHECK Quantity>0, PK(PrescriptionID,CompanyName,TradeName))`

## Constraints & Triggers
Implemented in `create_tables.sql`.

### 1) “Each pharmacy sells at least 10 drugs”
Trigger: `CheckPharmacyDrugs` (AFTER INSERT OR DELETE on `PharmacyDrugs`)
- Counts drugs per pharmacy and raises an error if any pharmacy is below 10.

Note: `insert_data.sql` temporarily disables this trigger to allow loading sample data, then re-enables it.

### 2) “Every doctor has at least one patient”
Trigger: `CheckDoctorPatients` (BEFORE DELETE on `PatientDoctor`, FOR EACH ROW)
- Prevents deleting the last patient mapping for a doctor.

## Stored Procedures (PL/SQL)
Implemented in `procedures.sql`.

### Data entry / updates
- `AddPatient`, `AddDoctor`, `AddPharmaceuticalCompany`, `AddDrug`, `AddPharmacy`
- `AddContract` — inserts a contract row.
- `UpdateContractSupervisor` — updates the supervisor for a given contract.

### Prescriptions (with “latest only” rule)
- `AddPrescription(p_PatientAadharID, p_DoctorAadharID, p_PrescriptionDate, p_Drugs, p_Result)`
  - Enforces: **one prescription per patient–doctor per date**.
  - Enforces: keep only the **latest** prescription for a patient–doctor pair by deleting older prescriptions for that pair.
  - Accepts `p_Drugs` as a string like:
    - `Company:TradeName:Quantity` (single drug), or
    - `Company1:Trade1:Qty1;Company2:Trade2:Qty2;...`

### Reports (as required in the spec)
- `ReportPatientPrescriptions(patient, start_date, end_date)` — prescriptions in a period.
- `PrintPrescriptionDetails(patient, date)` — details for a specific date.
- `ListCompanyDrugs(company)` — drugs made by a company.
- `PharmacyStock(pharmacy)` — drug list and prices for a pharmacy.
- `PharmacyCompanyContacts(pharmacy, company)` — phone details.
- `DoctorPatients(doctor)` — list of patients for a doctor.

### Deletion
- `DeletePatient(aadhar, result)` — deletes a patient row (may fail if referenced via FK constraints).

## Demo Script Notes
`demo.sql` demonstrates calling the procedures and printing output.

Important: the current `demo.sql` includes plain `SELECT * ...` statements inside a `BEGIN ... END;` block, which is **not valid PL/SQL** (a `SELECT` inside PL/SQL needs an `INTO`, or the `SELECT` must be executed outside the block in SQL*Plus/SQL Developer scripting).

If you want to inspect tables during the demo, run those `SELECT` statements as separate SQL statements between PL/SQL blocks.

## Known Gaps / Follow-ups (Optional)
If the project needs to fully match “add/delete/update everything via procedures”:
- Add delete/update procedures for `Doctors`, `Pharmacies`, `PharmaceuticalCompanies`, `Drugs`, `Contracts`, and `PharmacyDrugs`.
- Add explicit procedures for assigning/updating `PatientDoctor` (primary physician).

