
import pymysql
import pymysql.cursors
from pymongo import MongoClient
from dotenv import load_dotenv
import os

# load env variables from .env into os.environ
load_dotenv()

def get_mysql():
    # creates a MySQL connection obj
    return pymysql.connect(
        unix_socket='/tmp/mysql.sock',
        user=os.getenv('MYSQL_USER'),
        password=os.getenv('MYSQL_PASSWORD'),
        db=os.getenv('MYSQL_DB'),
        cursorclass=pymysql.cursors.DictCursor,
        charset='utf8mb4'
    )

def get_mongo():
    # connects to MongoDB using a URI 
    client = MongoClient(os.getenv('MONGO_URI'))
    return client[os.getenv('MONGO_DB')]


# convert any non-serializable types (dates etc) to string
def serialize(row):
    if row is None:
        return None
    result = {}
    for k, v in row.items():
        if v is None:
            # skip nulls here 
            continue
        # normalize column names to lowercase 
        result[k.lower()] = str(v) if hasattr(v, 'isoformat') else v
    return result

def fetch_diagnoses(cursor, hadm_id):
    # get all diagnosis codes for a specific hospital admission (hadm_id)
    # we also join the dictionary table to get readable titles
    cursor.execute("""
        SELECT 
            d.seq_num,
            d.icd9_code,
            i.short_title,
            i.long_title
        FROM DIAGNOSES_ICD d
        LEFT JOIN D_ICD_DIAGNOSES i 
            ON d.icd9_code = i.icd9_code
        WHERE d.hadm_id = %s
        ORDER BY d.seq_num
    """, (hadm_id,))
    return [serialize(r) for r in cursor.fetchall()]

def fetch_icustays(cursor, hadm_id):
    # get ICU stay rows for a specific hospital admission (hadm_id)
    cursor.execute("""
        SELECT 
            icustay_id, dbsource,
            first_careunit, last_careunit,
            first_wardid, last_wardid,
            intime, outtime, los
        FROM ICUSTAYS
        WHERE hadm_id = %s
        ORDER BY intime
    """, (hadm_id,))
    return [serialize(r) for r in cursor.fetchall()]

def fetch_notes(cursor, hadm_id, subject_id):
    """
    Some notes have NULL hadm_id in the data — 
    we grab by subject_id too just in case.
    """
    # get clinical notes
    cursor.execute("""
        SELECT 
            row_id, chartdate, charttime, storetime,
            category, description, cgid, iserror, `text`
        FROM NoteEvents
        WHERE hadm_id = %s OR (hadm_id IS NULL AND subject_id = %s)
        ORDER BY chartdate
    """, (hadm_id, subject_id))
    return [serialize(r) for r in cursor.fetchall()]

def fetch_admissions(cursor, subject_id):
    # get all hospital admissions for one patient (subject_id)
    cursor.execute("""
        SELECT *
        FROM Admissions
        WHERE subject_id = %s
        ORDER BY admittime
    """, (subject_id,))
    return cursor.fetchall()

def migrate():
    # connect to both databases
    mysql = get_mysql()
    mongo_db = get_mongo()
    
    # # drop existing collection incase of re-runs 
    # mongo_db.patients.drop()
    # print("Dropped existing collection")

    # Get all patients from MySQL
    cursor = mysql.cursor()
    cursor.execute("SELECT * FROM Patients ORDER BY subject_id")
    patients = cursor.fetchall()

    total = len(patients)
    print(f"Found {total} patients to migrate\n")

    for i, patient in enumerate(patients, 1):
        # each patient row becomes 1 MongoDB document
        subject_id = patient['SUBJECT_ID']

        # build patient document
        doc = {
            "subject_id":   subject_id,
            "gender":       patient['GENDER'],
            "dob":          str(patient['DOB'])  if patient['DOB']      else None,
            "dod":          str(patient['DOD'])  if patient['DOD']      else None,
            "dod_hosp":     str(patient['DOD_HOSP']) if patient['DOD_HOSP'] else None,
            "dod_ssn":      str(patient['DOD_SSN'])  if patient['DOD_SSN']  else None,
            "expire_flag":  patient['EXPIRE_FLAG'],
            "admissions":   []
        }

        #  loop through admissions
        admissions = fetch_admissions(cursor, subject_id)

        for adm in admissions:
            hadm_id = adm['HADM_ID']

            # this admission becomes a sub-document in the patient document
            adm_doc = {
                "hadm_id":            hadm_id,
                "admittime":          str(adm['ADMITTIME'])  if adm['ADMITTIME']  else None,
                "dischtime":          str(adm['DISCHTIME'])  if adm['DISCHTIME']  else None,
                "deathtime":          str(adm['DEATHTIME'])  if adm['DEATHTIME']  else None,
                "admission_type":     adm['ADMISSION_TYPE'],
                "admission_location": adm['ADMISSION_LOCATION'],
                "discharge_location": adm['DISCHARGE_LOCATION'],
                "insurance":          adm['INSURANCE'],
                "language":           adm['LANGUAGE'],
                "religion":           adm['RELIGION'],
                "marital_status":     adm['MARITAL_STATUS'],
                "ethnicity":          adm['ETHNICITY'],
                "diagnosis":          adm['DIAGNOSIS'],
                "hospital_expire_flag": adm['HOSPITAL_EXPIRE_FLAG'],
                "has_chartevents_data": adm['HAS_CHARTEVENTS_DATA'],

                # these helper functions each run a SQL query and return a list
                "diagnoses_icd": fetch_diagnoses(cursor, hadm_id),
                "icustays":      fetch_icustays(cursor, hadm_id),
                "notes":         fetch_notes(cursor, hadm_id, subject_id),
            }

            # remove none values from admission doc
            adm_doc = {k: v for k, v in adm_doc.items() if v is not None}
            doc['admissions'].append(adm_doc)

        # insert the patient document into MongoDB
        mongo_db.patients.insert_one(doc)

        # progress every 10 patients
        if i % 10 == 0 or i == total:
            print(f"  Migrated {i}/{total} patients")

    print(f"\n{total} patient documents inserted into MongoDB Atlas")
    # close DB connections when done
    mysql.close()

if __name__ == '__main__':
    migrate()
