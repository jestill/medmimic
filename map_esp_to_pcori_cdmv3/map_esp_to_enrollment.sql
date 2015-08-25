-- Create the ENROLLMENT table
CREATE TABLE PCORI_CDMV3.ENROLLMENT (
  PATID             VARCHAR(50),
  ENR_START_DATE    DATE,
  ENR_END_DATE      DATE,
  CHART             CHAR(1),
  ENR_BASIS         CHAR(1)
);

-- For fake data will enroll everyone at birth
-- and set to an algorithmic basis.

INSERT INTO PCORI_CDMV3.ENROLLMENT (
  PATID,
  ENR_START_DATE,
  CHART,
  ENR_BASIS
)
SELECT
  PATID,
  BIRTH_DATE,
  'Y',
  'A'
FROM PCORI_CDMV3.DEMOGRAPHIC;
