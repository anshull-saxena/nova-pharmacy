-- NOVA Pharmacy Database: Demo Script
-- CS F212 Mini-Project, End-sem Evaluation
-- Group Members: Rishab Nagota, Devam Chheda, Kanav Sooden, Divyanshu Tomar
-- Date: 23rd April 2025

SET SERVEROUTPUT ON;

-- Demo Block
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== NOVA Pharmacy Database Demo ===');
    
    -- Add Patient
    DECLARE
        v_Result VARCHAR2(500);
    BEGIN
        AddPatient('987654321098', 'Tom Wilson', '101 Birch St', 50, v_Result);
        DBMS_OUTPUT.PUT_LINE('Add Patient: ' || v_Result);
    END;

    SELECT * FROM PATIENTS;
    
    --Add Doctor
    DECLARE
        v_Result VARCHAR2(500);
    BEGIN
        AddDoctor('111222333444', 'Dr. Virat Sharma', 'Cardiology', 11, v_Result);
        DBMS_OUTPUT.PUT_LINE('Add Patient: ' || v_Result);
    END;

    SELECT * FROM DOCTORS;

    -- Add Prescription
    DECLARE
        v_Result VARCHAR2(500);
    BEGIN
        AddPrescription('987654321098', '111222333444', TO_DATE('2025-04-15', 'YYYY-MM-DD'), 
                        'Pfizer:Lipitor:20', v_Result);
        DBMS_OUTPUT.PUT_LINE('Add Prescription: ' || v_Result);
    END;

    SELECT * FROM PRESCRIPTIONS;
    
    -- Test Invalid Prescription (same date)
    DECLARE
        v_Result VARCHAR2(500);
    BEGIN
        AddPrescription('987654321098', '111222333444', TO_DATE('2025-05-15', 'YYYY-MM-DD'), 
                        'Pfizer:Lipitor:20', v_Result);
        DBMS_OUTPUT.PUT_LINE('Add Duplicate Prescription: ' || v_Result);
    END;
    
    -- Report Patient Prescriptions
    BEGIN
        ReportPatientPrescriptions('987654321098', TO_DATE('2025-04-01', 'YYYY-MM-DD'), TO_DATE('2025-05-30', 'YYYY-MM-DD'));
    END;
    
    -- Print Prescription Details
    BEGIN
        PrintPrescriptionDetails('987654321098', TO_DATE('2025-04-15', 'YYYY-MM-DD'));
    END;
    
    -- List Company Drugs
    BEGIN
        ListCompanyDrugs('Pfizer');
    END;
    
    -- Pharmacy Stock
    BEGIN
        PharmacyStock('Nova Central');
    END;
    
    -- Pharmacy-Company Contacts
    BEGIN
        PharmacyCompanyContacts('Nova Central', 'Pfizer');
    END;
    
    -- Doctor Patients
    BEGIN
        DoctorPatients('581208765432');
    END;
    
    SELECT * FROM CONTRACTS;
    -- Update Contract Supervisor
    DECLARE
        v_Result VARCHAR2(500);
    BEGIN
        UpdateContractSupervisor(7, '781201345678', v_Result);
        DBMS_OUTPUT.PUT_LINE('Update Contract Supervisor: ' || v_Result);
    END;

    SELECT * FROM CONTRACTS;
    
    -- Demonstrate Constraint (Try deleting last Patient for a Doctor)
    DECLARE
        v_Result VARCHAR2(500);
    BEGIN
        DeletePatient('987654321088', v_Result);
        DBMS_OUTPUT.PUT_LINE('Delete Patient: ' || v_Result);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Delete Patient Error: ' || SQLERRM);
    END;
    
    -- Show Sample Data
    BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Sample Data ===');
    DBMS_OUTPUT.PUT_LINE('Prescriptions:');
    FOR rec IN (SELECT * FROM Prescriptions) LOOP
        DBMS_OUTPUT.PUT_LINE('Prescription ID: ' || rec.PrescriptionID || ', Patient: ' || rec.PatientAadharID || ', Date: ' || TO_CHAR(rec.PrescriptionDate, 'YYYY-MM-DD'));
    END LOOP;
    END;
END;
/