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

-- 4. List all patients who had both radiology exams and surgery during the same admission

-- 5. Find all ICU stays that lasted more than 7 days and the associated patient names

-- 6. Count the number of admissions for each patient

-- 7. List all patients who were admitted via the emergency department and had at least one ICU stay

-- 8. Retrieve the most common diagnosis (ICD code) in ICU admissions

-- 9. Find the average length of stay in the ICU for each ICU type (e.g., MICU, SICU,CCU)

-- 10. List all patients who had surgery before being admitted to the ICU in the same admission

-- 11. Retrieve the names of patients and the number of radiology exams they had during all admissions

-- 12. Find patients who had discharge summaries containing the keyword “recovery”

-- 13. List all admissions where the patient had no ICU/CCU stay but had radiology exams performed

-- 14. Retrieve the patients with the longest hospital stay (admission to discharge)

-- 15. Count the total number of ICU transfers for each patient

-- 16. List patients who were admitted to multiple ICU types during the same admission

-- 17. Find all patients who had more than one diagnosis coded during a single admission

-- 18. Retrieve the latest clinical note for each patient

-- 19. List all admissions where the patient died during the stay

-- 20. Find all patients who had surgery and radiology exams on the same day
