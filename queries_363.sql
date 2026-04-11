-- 1.  List all patients who were admitted to the ICU and whose first care unit and last care unit were both “MICU”
SELECT DISTINCT SUBJECT_ID
FROM ICUSTAYS
WHERE FIRST_CAREUNIT = 'MICU' AND LAST_CAREUNIT = 'MICU';

-- 2. Find all patients who had more than 3 hospital admissions in total

SELECT DISTINCT SUBJECT_ID 
FROM Admissions
GROUP BY SUBJECT_ID
HAVING COUNT(*) > 3;

-- 3. Retrieve the names and admission dates of patients who were discharged without any procedures
-- NOTE: Cannot implement as specified: dataset has no procedures table (e.g., Procedures_ICD) and no patient name fields.



-- 4. List all patients who had both radiology exams and surgery during the same admission

SELECT DISTINCT n1.SUBJECT_ID, n1.HADM_ID
FROM NoteEvents n1
JOIN NoteEvents n2
ON n1.SUBJECT_ID = n2.SUBJECT_ID
AND n1.HADM_ID = n2.HADM_ID
WHERE n1.CATEGORY = 'Radiology'
AND (
    LOWER(n2.TEXT) LIKE '%surgery%'
);

-- 5. Find all ICU stays that lasted more than 7 days and the associated patient names

SELECT SUBJECT_ID, ICUSTAY_ID, LOS
FROM ICUSTAYS
WHERE LOS > 7;

-- 6. Count the number of admissions for each patient

SELECT SUBJECT_ID, COUNT(*) AS num_of_admissions
FROM Admissions
GROUP BY SUBJECT_ID;

-- 7. List all patients who were admitted via the emergency department and had at least one ICU stay

SELECT DISTINCT a.SUBJECT_ID
FROM Admissions a
JOIN ICUSTAYS i
ON a.HADM_ID = i.HADM_ID
WHERE a.ADMISSION_TYPE = 'EMERGENCY';

-- 8. Retrieve the most common diagnosis (ICD code) in ICU admissions

SELECT d.ICD9_CODE, COUNT(*) AS most_common_diagnosis
FROM DIAGNOSES_ICD d
JOIN ICUSTAYS i
ON d.HADM_ID = i.HADM_ID
GROUP BY d.ICD9_CODE
ORDER BY most_common_diagnosis DESC
LIMIT 1;

-- 9. Find the average length of stay in the ICU for each ICU type (e.g., MICU, SICU,CCU)

SELECT FIRST_CAREUNIT, AVG(LOS) AS average_los
FROM ICUSTAYS
GROUP BY FIRST_CAREUNIT;

-- 10. List all patients who had surgery before being admitted to the ICU in the same admission

SELECT DISTINCT n.SUBJECT_ID, n.HADM_ID
FROM NoteEvents n
JOIN ICUSTAYS i ON n.HADM_ID = i.HADM_ID
WHERE n.CHARTTIME < i.INTIME
  AND (
        n.CATEGORY = 'Surgery'
     OR LOWER(n.TEXT) LIKE '%surgery%'
      );

-- 11. Retrieve the names of patients and the number of radiology exams they had during all admissions

SELECT SUBJECT_ID, COUNT(*) AS radiology_exams
FROM NoteEvents
WHERE CATEGORY = 'Radiology'
GROUP BY SUBJECT_ID;

-- 12. Find patients who had discharge summaries containing the keyword “recovery”

SELECT DISTINCT SUBJECT_ID
FROM NoteEvents
WHERE CATEGORY = 'Discharge Summary'
AND LOWER(TEXT) LIKE '%recovery%';

-- 13. List all admissions where the patient had no ICU/CCU stay but had radiology exams performed

SELECT DISTINCT n.HADM_ID
FROM NoteEvents n
WHERE n.CATEGORY = 'Radiology'
AND NOT EXISTS (
    SELECT *like 
    FROM ICUSTAYS i
    WHERE i.HADM_ID = n.HADM_ID
);


SELECT DISTINCT HADM_ID
FROM NoteEvents 
WHERE CATEGORY = 'Radiology'

-- 14. Retrieve the patients with the longest hospital stay (admission to discharge)

SELECT SUBJECT_ID, HADM_ID,
TIMESTAMPDIFF(DAY, ADMITTIME, DISCHTIME) AS stay_days
FROM Admissions
ORDER BY stay_days DESC
LIMIT 1;

-- 15. Count the total number of ICU transfers for each patient

SELECT SUBJECT_ID, COUNT(*) AS icu_transfers
FROM ICUSTAYS
WHERE FIRST_CAREUNIT <> LAST_CAREUNIT
GROUP BY SUBJECT_ID;

-- 16. List patients who were admitted to multiple ICU types during the same admission

SELECT SUBJECT_ID, HADM_ID
FROM ICUSTAYS
GROUP BY SUBJECT_ID, HADM_ID
HAVING COUNT(DISTINCT FIRST_CAREUNIT) > 1;

-- 17. Find all patients who had more than one diagnosis coded during a single admission

SELECT SUBJECT_ID, HADM_ID, COUNT(DISTINCT ICD9_CODE) AS diagnosis_count
FROM DIAGNOSES_ICD
GROUP BY SUBJECT_ID, HADM_ID
HAVING COUNT(DISTINCT ICD9_CODE) > 1;

-- 18. Retrieve the latest clinical note for each patient

-- Finds each patient's most recent charted note time, then pulls that full note.
-- Useful for showing the latest clinical context per subject without duplicates.
SELECT n.SUBJECT_ID, n.CHARTTIME, n.TEXT
FROM NoteEvents n
JOIN (
    SELECT SUBJECT_ID, MAX(CHARTTIME) AS latest_note
    FROM NoteEvents
    GROUP BY SUBJECT_ID
) t
ON n.SUBJECT_ID = t.SUBJECT_ID
AND n.CHARTTIME = t.latest_note;

-- 19. List all admissions where the patient died during the stay

SELECT SUBJECT_ID, HADM_ID, ADMITTIME, DISCHTIME
FROM Admissions
WHERE HOSPITAL_EXPIRE_FLAG = 1;

-- 20. Find all patients who had surgery and radiology exams on the same day

SELECT DISTINCT n1.SUBJECT_ID, n1.HADM_ID, DATE(n1.CHARTTIME) AS event_day
FROM NoteEvents n1
JOIN NoteEvents n2
ON n1.SUBJECT_ID = n2.SUBJECT_ID
AND n1.HADM_ID = n2.HADM_ID
AND DATE(n1.CHARTTIME) = DATE(n2.CHARTTIME)
WHERE n1.CATEGORY = 'Radiology'
AND (
    LOWER(n2.TEXT) LIKE '%surgery%'
);

