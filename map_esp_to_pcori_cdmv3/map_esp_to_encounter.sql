CREATE TABLE PCORI_CDMV3.ENCOUNTER (
  ENCOUNTERID                 VARCHAR(50),
  PATID                       VARCHAR(50),
  ADMIT_DATE                  DATE,
  ADMIT_TIME                  CHAR(5),
  DISCHARGE_DATE              DATE,
  DISCHARGE_TIME              CHAR(5),
  PROVIDERID                  VARCHAR(50),
  FACILITY_LOCATION           VARCHAR,
  ENC_TYPE                    CHAR(2),
  FACILITYID                  VARCHAR,
  DISCHARGE_DISPOSITION       VARCHAR(2),
  DISCHARGE_STATUS            CHAR(2),
  DRG                         VARCHAR(3),
  DRG_TYPE                    CHAR(2),
  ADMITTING_SOURCE            CHAR(2),
  RAW_SITEID                  VARCHAR,  /*   */
  RAW_ENC_TYPE                VARCHAR,  /* raw_encounter_type  */
  RAW_DISCHARGE_DISPOSITION   VARCHAR,
  RAW_DISCHARGE_STATUS        VARCHAR,
  RAW_DRG_TYPE                VARCHAR,
  RAW_ADMITTING_SOURCE        VARCHAR
);


-- Transfer over from esp data model
INSERT INTO PCORI_CDMV3.ENCOUNTER (
  ENCOUNTERID,
  PATID,
  ADMIT_DATE,
  DISCHARGE_DATE,
  PROVIDERID,
  FACILITYID,
  RAW_ENC_TYPE 
)
SELECT
  ID,                  /*pcroi.encounterid*/
  MRN,                 /*pcori.patid */
  DATE,                /*pcori.admit_date*/
  DATE,                /*pcori.discharge_date*/ 
  PROVIDER_ID,         /*prcori.providerid*/  
  SITE_NAME,           /*pcori.facilityid */
  RAW_ENCOUNTER_TYPE  /*pcori.raw*_enc_type*/
FROM PUBLIC.emr_encounter;

-- SET ALL VISITIS TO THE Ambulatory Visit TYPE
UPDATE PCORI_CDMV3.ENCOUNTER
SET ENC_TYPE = 'AV'
WHERE RAW_ENC_TYPE = 'VISIT';
