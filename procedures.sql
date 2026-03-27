-- NOVA Pharmacy Database: PL/SQL Procedures
-- CS F212 Mini-Project, End-sem Evaluation
-- Group Members: Rishab Nagota, Devam Chheda, Kanav Sooden, Divyanshu Tomar
-- Date: 23rd April 2025

SET SERVEROUTPUT ON;

-- Add Patient
CREATE OR REPLACE PROCEDURE AddPatient (
    p_AadharID IN VARCHAR2,
    p_Name IN VARCHAR2,
    p_Address IN VARCHAR2,
    p_Age IN NUMBER,
    p_Result OUT VARCHAR2
) AS
BEGIN
    INSERT INTO Patients (AadharID, Name, Address, Age)
    VALUES (p_AadharID, p_Name, p_Address, p_Age);
    COMMIT;
    p_Result := 'Patient added successfully.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_Result := 'Error: ' || SQLERRM;
END;
/

-- Add Doctor
CREATE OR REPLACE PROCEDURE AddDoctor (
    p_AadharID IN VARCHAR2,
    p_Name IN VARCHAR2,
    p_Specialty IN VARCHAR2,
    p_YearsOfExperience IN NUMBER,
    p_Result OUT VARCHAR2
) AS
BEGIN
    INSERT INTO Doctors (AadharID, Name, Specialty, YearsOfExperience)
    VALUES (p_AadharID, p_Name, p_Specialty, p_YearsOfExperience);
    COMMIT;
    p_Result := 'Doctor added successfully.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_Result := 'Error: ' || SQLERRM;
END;
/

-- Add Pharmaceutical Company
CREATE OR REPLACE PROCEDURE AddPharmaceuticalCompany (
    p_CompanyName IN VARCHAR2,
    p_PhoneNumber IN VARCHAR2,
    p_Result OUT VARCHAR2
) AS
BEGIN
    INSERT INTO PharmaceuticalCompanies (CompanyName, PhoneNumber)
    VALUES (p_CompanyName, p_PhoneNumber);
    COMMIT;
    p_Result := 'Pharmaceutical company added successfully.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_Result := 'Error: ' || SQLERRM;
END;
/

-- Add Drug
CREATE OR REPLACE PROCEDURE AddDrug (
    p_CompanyName IN VARCHAR2,
    p_TradeName IN VARCHAR2,
    p_Formula IN VARCHAR2,
    p_Result OUT VARCHAR2
) AS
BEGIN
    INSERT INTO Drugs (CompanyName, TradeName, Formula)
    VALUES (p_CompanyName, p_TradeName, p_Formula);
    COMMIT;
    p_Result := 'Drug added successfully.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_Result := 'Error: ' || SQLERRM;
END;
/

-- Add Pharmacy
CREATE OR REPLACE PROCEDURE AddPharmacy (
    p_PharmacyName IN VARCHAR2,
    p_Address IN VARCHAR2,
    p_Phone IN VARCHAR2,
    p_Result OUT VARCHAR2
) AS
BEGIN
    INSERT INTO Pharmacies (PharmacyName, Address, Phone)
    VALUES (p_PharmacyName, p_Address, p_Phone);
    COMMIT;
    p_Result := 'Pharmacy added successfully.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_Result := 'Error: ' || SQLERRM;
END;
/

-- Add Contract
CREATE OR REPLACE PROCEDURE AddContract (
    p_ContractID IN NUMBER,
    p_PharmacyName IN VARCHAR2,
    p_CompanyName IN VARCHAR2,
    p_StartDate IN DATE,
    p_EndDate IN DATE,
    p_Content IN VARCHAR2,
    p_SupervisorAadharID IN VARCHAR2,
    p_Result OUT VARCHAR2
) AS
BEGIN
    INSERT INTO Contracts (ContractID, PharmacyName, CompanyName, StartDate, EndDate, Content, SupervisorAadharID)
    VALUES (p_ContractID, p_PharmacyName, p_CompanyName, p_StartDate, p_EndDate, p_Content, p_SupervisorAadharID);
    COMMIT;
    p_Result := 'Contract added successfully.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_Result := 'Error: ' || SQLERRM;
END;
/

-- Add Prescription (Handles latest prescription constraint)
CREATE OR REPLACE PROCEDURE AddPrescription (
    p_PatientAadharID IN VARCHAR2,
    p_DoctorAadharID IN VARCHAR2,
    p_PrescriptionDate IN DATE,
    p_Drugs IN VARCHAR2, -- Format: 'CompanyName1:TradeName1:Quantity1;CompanyName2:TradeName2:Quantity2' or single 'CompanyName:TradeName:Quantity'
    p_Result OUT VARCHAR2
) AS
    v_PrescriptionID NUMBER;
    v_Count NUMBER;
    v_CompanyName VARCHAR2(100);
    v_TradeName VARCHAR2(100);
    v_Quantity NUMBER;
    v_DrugEntry VARCHAR2(500);
    v_DrugsList VARCHAR2(4000) := p_Drugs;
    v_Pos NUMBER := 1;
BEGIN
    -- Validate inputs
    IF p_PatientAadharID IS NULL OR p_DoctorAadharID IS NULL OR p_PrescriptionDate IS NULL THEN
        p_Result := 'Error: Invalid input parameters';
        RETURN;
    END IF;

    -- Check if Prescription exists for Patient-Doctor on same date
    SELECT COUNT(*) INTO v_Count
    FROM Prescriptions
    WHERE PatientAadharID = p_PatientAadharID
    AND DoctorAadharID = p_DoctorAadharID
    AND PrescriptionDate = p_PrescriptionDate;

    IF v_Count > 0 THEN
        p_Result := 'Error: Prescription already exists for this Patient-Doctor on this date.';
        RETURN;
    END IF;

    -- Delete older Prescriptions for same Patient-Doctor
    DELETE FROM PrescriptionDrugs
    WHERE PrescriptionID IN (
        SELECT PrescriptionID
        FROM Prescriptions
        WHERE PatientAadharID = p_PatientAadharID
        AND DoctorAadharID = p_DoctorAadharID
        AND PrescriptionDate < p_PrescriptionDate
    );
    DELETE FROM Prescriptions
    WHERE PatientAadharID = p_PatientAadharID
    AND DoctorAadharID = p_DoctorAadharID
    AND PrescriptionDate < p_PrescriptionDate;

    -- Generate PrescriptionID
    SELECT NVL(MAX(PrescriptionID), 0) + 1 INTO v_PrescriptionID FROM Prescriptions;

    -- Insert Prescription
    INSERT INTO Prescriptions (PrescriptionID, PatientAadharID, DoctorAadharID, PrescriptionDate)
    VALUES (v_PrescriptionID, p_PatientAadharID, p_DoctorAadharID, p_PrescriptionDate);

    -- Parse Drugs
    IF v_DrugsList IS NOT NULL THEN
        -- Ensure trailing semicolon for consistent parsing
        IF NOT REGEXP_LIKE(v_DrugsList, ';$') THEN
            v_DrugsList := v_DrugsList || ';';
        END IF;

        -- Loop through semicolon-separated drugs
        WHILE v_Pos <= LENGTH(v_DrugsList) LOOP
            v_DrugEntry := REGEXP_SUBSTR(v_DrugsList, '[^;]+', 1, v_Pos);
            EXIT WHEN v_DrugEntry IS NULL;

            -- Parse Company:TradeName:Quantity
            v_CompanyName := REGEXP_SUBSTR(v_DrugEntry, '[^:]+', 1, 1);
            v_TradeName := REGEXP_SUBSTR(v_DrugEntry, '[^:]+', 1, 2);
            v_Quantity := TO_NUMBER(REGEXP_SUBSTR(v_DrugEntry, '[^:]+', 1, 3));

            -- Validate drug entry
            IF v_CompanyName IS NULL OR v_TradeName IS NULL OR v_Quantity IS NULL THEN
                RAISE_APPLICATION_ERROR(-20001, 'Invalid drug format near ' || SUBSTR(v_DrugEntry, 1, 5));
            END IF;

            -- Insert into PrescriptionDrugs
            INSERT INTO PrescriptionDrugs (PrescriptionID, CompanyName, TradeName, Quantity)
            VALUES (v_PrescriptionID, v_CompanyName, v_TradeName, v_Quantity);

            v_Pos := v_Pos + 1;
        END LOOP;
    END IF;

    COMMIT;
    p_Result := 'Prescription added successfully.';
EXCEPTION
    WHEN VALUE_ERROR THEN
        ROLLBACK;
        p_Result := 'Error: Invalid quantity format in drug list';
    WHEN OTHERS THEN
        ROLLBACK;
        p_Result := 'Error: ' || SQLERRM;
END AddPrescription;
/

-- Delete Patient
CREATE OR REPLACE PROCEDURE DeletePatient (
    p_AadharID IN VARCHAR2,
    p_Result OUT VARCHAR2
) AS
BEGIN
    DELETE FROM Patients WHERE AadharID = p_AadharID;
    COMMIT;
    p_Result := 'Patient deleted successfully.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_Result := 'Error: ' || SQLERRM;
END;
/

-- Update Contract Supervisor
CREATE OR REPLACE PROCEDURE UpdateContractSupervisor (
    p_ContractID IN NUMBER,
    p_SupervisorAadharID IN VARCHAR2,
    p_Result OUT VARCHAR2
) AS
BEGIN
    UPDATE Contracts
    SET SupervisorAadharID = p_SupervisorAadharID
    WHERE ContractID = p_ContractID;
    
    IF SQL%ROWCOUNT = 0 THEN
        p_Result := 'Error: Contract not found.';
    ELSE
        COMMIT;
        p_Result := 'Contract supervisor updated successfully.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_Result := 'Error: ' || SQLERRM;
END;
/

-- Report: Prescriptions of a Patient in a Period
CREATE OR REPLACE PROCEDURE ReportPatientPrescriptions (
    p_PatientAadharID IN VARCHAR2,
    p_StartDate IN DATE,
    p_EndDate IN DATE
) AS
    CURSOR c_Prescriptions IS
        SELECT p.PrescriptionID, p.PrescriptionDate, p.DoctorAadharID, d.Name AS DoctorName,
               pd.CompanyName, pd.TradeName, pd.Quantity
        FROM Prescriptions p
        JOIN Doctors d ON p.DoctorAadharID = d.AadharID
        JOIN PrescriptionDrugs pd ON p.PrescriptionID = pd.PrescriptionID
        WHERE p.PatientAadharID = p_PatientAadharID
        AND p.PrescriptionDate BETWEEN p_StartDate AND p_EndDate
        ORDER BY p.PrescriptionDate;
    v_PrescriptionID NUMBER;
    v_PrescriptionDate DATE;
    v_DoctorAadharID VARCHAR2(12);
    v_DoctorName VARCHAR2(100);
    v_CompanyName VARCHAR2(100);
    v_TradeName VARCHAR2(100);
    v_Quantity NUMBER;
    v_Count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Prescriptions for Patient ' || p_PatientAadharID || ' from ' || TO_CHAR(p_StartDate, 'YYYY-MM-DD') || ' to ' || TO_CHAR(p_EndDate, 'YYYY-MM-DD'));
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    OPEN c_Prescriptions;
    LOOP
        FETCH c_Prescriptions INTO v_PrescriptionID, v_PrescriptionDate, v_DoctorAadharID, v_DoctorName, v_CompanyName, v_TradeName, v_Quantity;
        EXIT WHEN c_Prescriptions%NOTFOUND;
        v_Count := v_Count + 1;
        DBMS_OUTPUT.PUT_LINE('Prescription ID: ' || v_PrescriptionID || ', Date: ' || TO_CHAR(v_PrescriptionDate, 'YYYY-MM-DD') || 
                             ', Doctor: ' || v_DoctorName || ', Drug: ' || v_CompanyName || ' - ' || v_TradeName || ', Quantity: ' || v_Quantity);
    END LOOP;
    CLOSE c_Prescriptions;
    IF v_Count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No prescriptions found.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Report: Prescription Details for a Patient on a Date
CREATE OR REPLACE PROCEDURE PrintPrescriptionDetails (
    p_PatientAadharID IN VARCHAR2,
    p_PrescriptionDate IN DATE
) AS
    CURSOR c_Prescription IS
        SELECT p.PrescriptionID, p.DoctorAadharID, d.Name AS DoctorName,
               pd.CompanyName, pd.TradeName, pd.Quantity
        FROM Prescriptions p
        JOIN Doctors d ON p.DoctorAadharID = d.AadharID
        JOIN PrescriptionDrugs pd ON p.PrescriptionID = pd.PrescriptionID
        WHERE p.PatientAadharID = p_PatientAadharID
        AND p.PrescriptionDate = p_PrescriptionDate;
    v_PrescriptionID NUMBER;
    v_DoctorAadharID VARCHAR2(12);
    v_DoctorName VARCHAR2(100);
    v_CompanyName VARCHAR2(100);
    v_TradeName VARCHAR2(100);
    v_Quantity NUMBER;
    v_Count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Prescription for Patient ' || p_PatientAadharID || ' on ' || TO_CHAR(p_PrescriptionDate, 'YYYY-MM-DD'));
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    OPEN c_Prescription;
    LOOP
        FETCH c_Prescription INTO v_PrescriptionID, v_DoctorAadharID, v_DoctorName, v_CompanyName, v_TradeName, v_Quantity;
        EXIT WHEN c_Prescription%NOTFOUND;
        v_Count := v_Count + 1;
        DBMS_OUTPUT.PUT_LINE('Prescription ID: ' || v_PrescriptionID || ', Doctor: ' || v_DoctorName || 
                             ', Drug: ' || v_CompanyName || ' - ' || v_TradeName || ', Quantity: ' || v_Quantity);
    END LOOP;
    CLOSE c_Prescription;
    IF v_Count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No prescription found.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Report: Drugs by Pharmaceutical Company
CREATE OR REPLACE PROCEDURE ListCompanyDrugs (
    p_CompanyName IN VARCHAR2
) AS
    CURSOR c_Drugs IS
        SELECT TradeName, Formula
        FROM Drugs
        WHERE CompanyName = p_CompanyName
        ORDER BY TradeName;
    v_TradeName VARCHAR2(100);
    v_Formula VARCHAR2(200);
    v_Count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Drugs by ' || p_CompanyName);
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    OPEN c_Drugs;
    LOOP
        FETCH c_Drugs INTO v_TradeName, v_Formula;
        EXIT WHEN c_Drugs%NOTFOUND;
        v_Count := v_Count + 1;
        DBMS_OUTPUT.PUT_LINE('Trade Name: ' || v_TradeName || ', Formula: ' || v_Formula);
    END LOOP;
    CLOSE c_Drugs;
    IF v_Count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No drugs found.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Report: Pharmacy Stock
CREATE OR REPLACE PROCEDURE PharmacyStock (
    p_PharmacyName IN VARCHAR2
) AS
    CURSOR c_Stock IS
        SELECT pd.CompanyName, pd.TradeName, pd.Price
        FROM PharmacyDrugs pd
        WHERE pd.PharmacyName = p_PharmacyName
        ORDER BY pd.CompanyName, pd.TradeName;
    v_CompanyName VARCHAR2(100);
    v_TradeName VARCHAR2(100);
    v_Price NUMBER;
    v_Count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Stock for Pharmacy ' || p_PharmacyName);
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    OPEN c_Stock;
    LOOP
        FETCH c_Stock INTO v_CompanyName, v_TradeName, v_Price;
        EXIT WHEN c_Stock%NOTFOUND;
        v_Count := v_Count + 1;
        DBMS_OUTPUT.PUT_LINE('Drug: ' || v_CompanyName || ' - ' || v_TradeName || ', Price: ' || v_Price);
    END LOOP;
    CLOSE c_Stock;
    IF v_Count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No drugs found.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Report: Pharmacy-Company Contact Details
CREATE OR REPLACE PROCEDURE PharmacyCompanyContacts (
    p_PharmacyName IN VARCHAR2,
    p_CompanyName IN VARCHAR2
) AS
    v_PharmacyPhone VARCHAR2(15);
    v_CompanyPhone VARCHAR2(15);
BEGIN
    SELECT Phone INTO v_PharmacyPhone
    FROM Pharmacies
    WHERE PharmacyName = p_PharmacyName;
    
    SELECT PhoneNumber INTO v_CompanyPhone
    FROM PharmaceuticalCompanies
    WHERE CompanyName = p_CompanyName;
    
    DBMS_OUTPUT.PUT_LINE('Contact Details for ' || p_PharmacyName || ' and ' || p_CompanyName);
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Pharmacy Phone: ' || v_PharmacyPhone);
    DBMS_OUTPUT.PUT_LINE('Company Phone: ' || v_CompanyPhone);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Pharmacy or Company not found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Report: Patients for a Doctor
CREATE OR REPLACE PROCEDURE DoctorPatients (
    p_DoctorAadharID IN VARCHAR2
) AS
    CURSOR c_Patients IS
        SELECT p.AadharID, p.Name
        FROM Patients p
        JOIN PatientDoctor pd ON p.AadharID = pd.PatientAadharID
        WHERE pd.DoctorAadharID = p_DoctorAadharID
        ORDER BY p.Name;
    v_AadharID VARCHAR2(12);
    v_Name VARCHAR2(100);
    v_Count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Patients for Doctor ' || p_DoctorAadharID);
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    OPEN c_Patients;
    LOOP
        FETCH c_Patients INTO v_AadharID, v_Name;
        EXIT WHEN c_Patients%NOTFOUND;
        v_Count := v_Count + 1;
        DBMS_OUTPUT.PUT_LINE('Patient: ' || v_Name || ' (' || v_AadharID || ')');
    END LOOP;
    CLOSE c_Patients;
    IF v_Count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No patients found.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/