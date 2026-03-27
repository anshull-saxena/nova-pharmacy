-- NOVA Pharmacy Database: Table Creation and Triggers
-- CS F212 Mini-Project, End-sem Evaluation
-- Group Members: Rishab Nagota, Devam Chheda, Kanav Sooden, Divyanshu Tomar
-- Date: 23rd April 2025

SET SERVEROUTPUT ON;

-- Drop Existing Tables (if any, to ensure clean setup)
BEGIN
    FOR t IN (SELECT table_name FROM user_tables) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
    END LOOP;
END;
/

-- Create Tables with Constraints
-- Patients
CREATE TABLE Patients (
    AadharID VARCHAR2(12) PRIMARY KEY,
    Name VARCHAR2(100) NOT NULL,
    Address VARCHAR2(200),
    Age NUMBER CHECK (Age >= 0)
);

-- Doctors
CREATE TABLE Doctors (
    AadharID VARCHAR2(12) PRIMARY KEY,
    Name VARCHAR2(100) NOT NULL,
    Specialty VARCHAR2(50),
    YearsOfExperience NUMBER CHECK (YearsOfExperience >= 0)
);

-- Pharmaceutical Companies
CREATE TABLE PharmaceuticalCompanies (
    CompanyName VARCHAR2(100) PRIMARY KEY,
    PhoneNumber VARCHAR2(15)
);

-- Drugs
CREATE TABLE Drugs (
    CompanyName VARCHAR2(100),
    TradeName VARCHAR2(100),
    Formula VARCHAR2(200),
    PRIMARY KEY (CompanyName, TradeName),
    FOREIGN KEY (CompanyName) REFERENCES PharmaceuticalCompanies(CompanyName) ON DELETE CASCADE
);

-- Pharmacies
CREATE TABLE Pharmacies (
    PharmacyName VARCHAR2(100) PRIMARY KEY,
    Address VARCHAR2(200),
    Phone VARCHAR2(15)
);

-- Patient-Doctor (Primary Physician)
CREATE TABLE PatientDoctor (
    PatientAadharID VARCHAR2(12),
    DoctorAadharID VARCHAR2(12),
    PRIMARY KEY (PatientAadharID),
    FOREIGN KEY (PatientAadharID) REFERENCES Patients(AadharID),
    FOREIGN KEY (DoctorAadharID) REFERENCES Doctors(AadharID)
);

-- Pharmacy-Drugs (Drugs sold at Pharmacies)
CREATE TABLE PharmacyDrugs (
    PharmacyName VARCHAR2(100),
    CompanyName VARCHAR2(100),
    TradeName VARCHAR2(100),
    Price NUMBER CHECK (Price >= 0),
    PRIMARY KEY (PharmacyName, CompanyName, TradeName),
    FOREIGN KEY (PharmacyName) REFERENCES Pharmacies(PharmacyName),
    FOREIGN KEY (CompanyName, TradeName) REFERENCES Drugs(CompanyName, TradeName)
);

-- Contracts
CREATE TABLE Contracts (
    ContractID NUMBER PRIMARY KEY,
    PharmacyName VARCHAR2(100),
    CompanyName VARCHAR2(100),
    StartDate DATE,
    EndDate DATE,
    Content VARCHAR2(500),
    SupervisorAadharID VARCHAR2(12),
    FOREIGN KEY (PharmacyName) REFERENCES Pharmacies(PharmacyName),
    FOREIGN KEY (CompanyName) REFERENCES PharmaceuticalCompanies(CompanyName),
    FOREIGN KEY (SupervisorAadharID) REFERENCES Doctors(AadharID) -- Assumption: Supervisor is a Doctor
);

-- Prescriptions
CREATE TABLE Prescriptions (
    PrescriptionID NUMBER PRIMARY KEY,
    PatientAadharID VARCHAR2(12),
    DoctorAadharID VARCHAR2(12),
    PrescriptionDate DATE,
    FOREIGN KEY (PatientAadharID) REFERENCES Patients(AadharID),
    FOREIGN KEY (DoctorAadharID) REFERENCES Doctors(AadharID)
);

-- Prescription-Drugs (Drugs in a Prescription)
CREATE TABLE PrescriptionDrugs (
    PrescriptionID NUMBER,
    CompanyName VARCHAR2(100),
    TradeName VARCHAR2(100),
    Quantity NUMBER CHECK (Quantity > 0),
    PRIMARY KEY (PrescriptionID, CompanyName, TradeName),
    FOREIGN KEY (PrescriptionID) REFERENCES Prescriptions(PrescriptionID),
    FOREIGN KEY (CompanyName, TradeName) REFERENCES Drugs(CompanyName, TradeName)
);

-- Triggers for Constraint Enforcement
-- Ensure Pharmacy has at least 10 Drugs


CREATE OR REPLACE TRIGGER CheckPharmacyDrugs
AFTER INSERT OR DELETE ON PharmacyDrugs
DECLARE
    v_DrugCount NUMBER;
    CURSOR c_Pharmacies IS SELECT PharmacyName FROM Pharmacies;
BEGIN
    FOR p IN c_Pharmacies LOOP
        SELECT COUNT(*) INTO v_DrugCount
        FROM PharmacyDrugs
        WHERE PharmacyName = p.PharmacyName;
        
        IF v_DrugCount < 10 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Pharmacy ' || p.PharmacyName || ' must sell at least 10 drugs.');
        END IF;
    END LOOP;
END;
/

-- Ensure Doctor has at least one Patient
CREATE OR REPLACE TRIGGER CheckDoctorPatients
BEFORE DELETE ON PatientDoctor
FOR EACH ROW
DECLARE
    v_PatientCount NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_PatientCount
    FROM PatientDoctor
    WHERE DoctorAadharID = :OLD.DoctorAadharID;
    
    IF v_PatientCount <= 1 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Doctor ' || :OLD.DoctorAadharID || ' must have at least one patient.');
    END IF;
END;
/