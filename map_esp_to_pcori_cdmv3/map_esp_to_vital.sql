
-- Create the PCORI VITAL table
CREATE TABLE PCORI_CDMV3.VITAL(
  VITALID         VARCHAR(50),
  PATID           VARCHAR(50),   /* emr_encounter.mrn*/
  ENCOUNTERID     VARCHAR(50),   /* emr_encounter.id*/
  MEASURE_DATE    DATE,          /* emr_encounter.date*/
  MEASURE_TIME    VARCHAR(5),    /* will be null */
  VITAL_SOURCE    CHAR(2),       /* will set all UN for unknown */
  HT              FLOAT,         /* will calculate from emr_encounter.height */
  WT              FLOAT,         /* will calculate from emr_encounter.weight */
  DIASTOLIC       FLOAT,         /* will calculate from emr_encounter.bp_diastolic*/
  SYSTOLIC        FLOAT,         /* will calculate from bp_systolic */
  ORIGINAL_BMI    FLOAT,         /* from emr_encounter.bmi */
  BP_POSITION     CHAR(2),       /* will set all UN for unknown */
  SMOKING         CHAR(2),
  TOBACCO         CHAR(2),       
  TOBACCO_TYPE    CHAR(2),       /* will inherit from  */
  RAW_DIASTOLIC   VARCHAR,
  RAW_SYSTOLIC    VARCHAR,
  RAW_BP_POSITION VARCHAR,       /* will leave null */
  RAW_SMOKING     VARCHAR,
  RAW_TOBACCO     VARCHAR
);


-- Test of the Required select statement
SELECT 
  emr_encounter.mrn,
  emr_encounter.id,
  emr_encounter.date,
  'UN' as vital_source,
  LEFT(emr_encounter.raw_height, 4) as height,
  LEFT(emr_encounter.raw_weight, 5) as weight,
  emr_encounter.bp_diastolic,
  emr_encounter.bp_systolic,
  emr_encounter.bmi,
  'UN' as bp_position,
  emr_socialhistory.tobacco_use, /*this will go into RAW tobacco */
FROM emr_encounter
LEFT JOIN emr_socialhistory
ON emr_encounter.patient_id = emr_socialhistory.patient_id;


-- need to figure out a UUID
SELECT uuid_in(md5(random()::text || now()::text)::cstring);
-- or
SELECT md5(random()::text || clock_timestamp()::text)::uuid;

-- Then selecting into the model
INSERT INTO PCORI_CDMV3.VITAL (
  VITALID,
  PATID,
  ENCOUNTERID,
  MEASURE_DATE,
  VITAL_SOURCE,
  HT,
  WT,
  DIASTOLIC,
  SYSTOLIC,
  ORIGINAL_BMI,
  BP_POSITION,
  RAW_TOBACCO
)
SELECT 
  (md5(random()::text || clock_timestamp()::text)::uuid)( as vitalid,
  emr_encounter.mrn,
  emr_encounter.id,
  emr_encounter.date,
  'UN' as vital_source,
  LEFT(emr_encounter.raw_height, 4) as height,
  LEFT(emr_encounter.raw_weight, 5) as weight,
  emr_encounter.bp_diastolic,
  emr_encounter.bp_systolic,
  emr_encounter.bmi,
  'UN' as bp_position,
  emr_socialhistory.tobacco_use /*this will go into RAW tobacco */
FROM emr_encounter
LEFT JOIN emr_socialhistory
ON emr_encounter.patient_id = emr_socialhistory.patient_id;


-- The following works

INSERT INTO PCORI_CDMV3.VITAL (
  VITALID,
  PATID,
  ENCOUNTERID,
  MEASURE_DATE,
  VITAL_SOURCE,
  HT,
  WT,
  DIASTOLIC,
  SYSTOLIC,
  ORIGINAL_BMI,
  BP_POSITION,
  RAW_TOBACCO
)
SELECT 
 /* CAST (uuid_in(md5(random()::text || now()::text)::cstring) AS VARCHAR), */
  CAST ((md5(random()::text || clock_timestamp()::text)::uuid) AS VARCHAR),
  emr_encounter.mrn,
  emr_encounter.id,
  emr_encounter.date,
  'UN' as vital_source,
  CAST (LEFT(emr_encounter.raw_height, 4) AS FLOAT ),
  CAST (LEFT(emr_encounter.raw_weight, 5) as FLOAT),
  emr_encounter.bp_diastolic,
  emr_encounter.bp_systolic,
  emr_encounter.bmi,
  'UN' as bp_position,
  emr_socialhistory.tobacco_use /*this will go into RAW tobacco */
FROM emr_encounter
LEFT JOIN emr_socialhistory
ON emr_encounter.patient_id = emr_socialhistory.patient_id;

-- Update tobacco
UPDATE PCORI_CDMV3.VITAL
SET TOBACCO='01'
WHERE RAW_TOBACCO='yes';

UPDATE PCORI_CDMV3.VITAL
SET TOBACCO='01'
WHERE RAW_TOBACCO='no';

UPDATE PCORI_CDMV3.VITAL
SET TOBACCO='NI'
WHERE RAW_TOBACCO='';


-- Update tobacco_type
UPDATE PCORI_CDMV3.VITAL
SET TOBACCO_TYPE='UN'
WHERE RAW_TOBACCO='yes';

UPDATE PCORI_CDMV3.VITAL
SET TOBACCO_TYPE='04'
WHERE RAW_TOBACCO='no';

UPDATE PCORI_CDMV3.VITAL
SET TOBACCO='NI'
WHERE RAW_TOBACCO='';
