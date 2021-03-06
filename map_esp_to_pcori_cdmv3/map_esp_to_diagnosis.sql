--
CREATE TABLE PCORI_CDMV3.DIAGNOSIS (
  DIAGNOSISID     VARCHAR(50),
  PATID           VARCHAR(50),
  ENCOUNTERID     VARCHAR(50),
  ENC_TYPE        CHAR(2),
  ADMIT_DATE      DATE,
  PROVIDERID      VARCHAR(50),
  DX              VARCHAR(18),
  DX_TYPE         CHAR(2),
  DX_SOURCE       CHAR(2),
  PDX             VARCHAR(2),
  RAW_DX          VARCHAR,
  RAW_DX_TYPE     VARCHAR,
  RAW_DX_SOURCE   VARCHAR,
  RAW_PDX         VARCHAR
);


-- Create a staging table
CREATE TABLE ESP_ICD9_STAGE (
  ICD9_ID VARCHAR(10),
  CODE VARCHAR(10)
)

INSERT INTO ESP_ICD9_STAGE (
  ICD9_ID
)
SELECT
  DISTINCT(ICD9_ID)
FROM
PUBLIC.EMR_ENCOUNTER_ICD9_CODES;


-- Get the data from ESP in a usable form
SELECT * 
FROM PUBLIC.EMR_ENCOUNTER_ICD9_CODES;

--GET THE CODE WITHOUT THE PERIOD
UPDATE ESP_ICD9_STAGE
SET CODE = ICD9_ID;

-- Get rid of the period from code column of icd9_stage
UPDATE ESP_ICD9_STAGE
SET CODE = REPLACE( CODE,'.', '' );

-- Add index
CREATE INDEX IDX_ICD9_STAGE_CODE
ON ESP_ICD9_STAGE (CODE);

CREATE INDEX IDX_ICD9_STAGE_ICD9_ID
ON ESP_ICD9_STAGE (ICD9_ID)

--
SELECT *
FROM EMR_ENCOUNTER_ICD9_CODES;






-- THE SELECT TO GET THE DATA
SELECT 
  EMR_ENCOUNTER.MRN                       AS PATID,
  EMR_ENCOUNTER.ID                        AS ENCOUNTERID,
  'AV'                                    AS ENC_TYPE,
  EMR_ENCOUNTER.DATE                      AS ADMIT_DATE,
  EMR_ENCOUNTER.PROVIDER_ID               AS PROVIDERID,
  EMR_ENCOUNTER_ICD9_CODES.ICD9_ID        AS DX,
  '09'                                    AS DX_TYPE,
  'UN'                                    AS DX_SOURCE,
  'X'                                     AS PDX
FROM PUBLIC.EMR_ENCOUNTER_ICD9_CODES
LEFT JOIN ESP_ICD9_STAGE
ON EMR_ENCOUNTER_ICD9_CODES.ICD9_ID = ESP_ICD9_STAGE.ICD9_ID
LEFT JOIN ICD9_DX
ON ESP_ICD9_STAGE.CODE = ICD9_DX.CODE
LEFT JOIN EMR_ENCOUNTER
ON EMR_ENCOUNTER_ICD9_CODES.ENCOUNTER_ID = EMR_ENCOUNTER.ID
WHERE ICD9_DX.CODE IS NOT NULL;


-- INSERT THE INFO AND GENERATE A FAKE KEY
INSERT INTO PCORI_CDMV3.DIAGNOSIS (
  DIAGNOSISID,
  PATID,
  ENCOUNTERID,
  ENC_TYPE,
  ADMIT_DATE,
  PROVIDERID,
  DX,
  DX_TYPE,
  DX_SOURCE,
  PDX
)

SELECT
  CAST ((md5(random()::text || clock_timestamp()::text)::uuid) AS VARCHAR), 
  EMR_ENCOUNTER.MRN                       AS PATID,
  EMR_ENCOUNTER.ID                        AS ENCOUNTERID,
  'AV'                                    AS ENC_TYPE,
  EMR_ENCOUNTER.DATE                      AS ADMIT_DATE,
  EMR_ENCOUNTER.PROVIDER_ID               AS PROVIDERID,
  EMR_ENCOUNTER_ICD9_CODES.ICD9_ID        AS DX,
  '09'                                    AS DX_TYPE,
  'UN'                                    AS DX_SOURCE,
  'X'                                     AS PDX
FROM PUBLIC.EMR_ENCOUNTER_ICD9_CODES
LEFT JOIN ESP_ICD9_STAGE
ON EMR_ENCOUNTER_ICD9_CODES.ICD9_ID = ESP_ICD9_STAGE.ICD9_ID
LEFT JOIN ICD9_DX
ON ESP_ICD9_STAGE.CODE = ICD9_DX.CODE
LEFT JOIN EMR_ENCOUNTER
ON EMR_ENCOUNTER_ICD9_CODES.ENCOUNTER_ID = EMR_ENCOUNTER.ID
WHERE ICD9_DX.CODE IS NOT NULL;








INSERT INTO PCORI_CDMV3.DIAGNOSIS (
  DIAGNOSISID,
  PATID,
  ENCOUNTERID,
  ENC_TYPE,
  ADMIT_DATE,
  PROVIDERID,
  DX,
  DX_TYPE,
  DX_SOURCE,
  PDX
)
SELECT
  CAST ((md5(random()::text || clock_timestamp()::text)::uuid) AS VARCHAR), 
  EMR_ENCOUNTER.MRN                       AS PATID,
  EMR_ENCOUNTER.ID                        AS ENCOUNTERID,
  'AV'                                    AS ENC_TYPE,
  EMR_ENCOUNTER.DATE                      AS ADMIT_DATE,
  EMR_ENCOUNTER.PROVIDER_ID               AS PROVIDERID,
  EMR_ENCOUNTER_ICD9_CODES.ICD9_ID        AS DX,
  '09'                                    AS DX_TYPE,
  'UN'                                    AS DX_SOURCE,
  'X'                                     AS PDX
FROM PUBLIC.EMR_ENCOUNTER_ICD9_CODES
LEFT JOIN
STATIC_ICD9 
ON EMR_ENCOUNTER_ICD9_CODES.ICD9_ID = STATIC_ICD9.CODE
LEFT JOIN ICD9_DX
ON STATIC_ICD9.NAME = ICD9_DX.NAME
LEFT JOIN EMR_ENCOUNTER
ON EMR_ENCOUNTER_ICD9_CODES.ENCOUNTER_ID = EMR_ENCOUNTER.ID
WHERE ICD9_DX.NAME IS NOT NULL;




-- Not that many



