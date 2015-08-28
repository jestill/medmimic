### generate_random_biorep_data.pl

The generate_random_biorep_data.pl script is a simple perl program that will simulate a set of biospecimens dervied from medical research projects given: 
* a configuraiton file that defines the experiments and expected specimens 
* an optional list of subject identifiers to pick from


SYNOPSIS

`./generate_random_biorep_data.pl -i input_mrns.txt -o output.txt -c config.txt`

Required Arguments

```
--config        # Path to the config file for studies
--outfile       # Path to the output file, delimited output file
```

Optional Arugments

```
--subjects      # Path to the subjects input file (ie. list of fake MRNs)
```

Program manual available with
`./generate_random_biorep_data.pl --man`

OUTPUT

The output is currently a 12 column table that emulates some of the data that could be dervied from a database view of a biospecimen LIMS such as LabVantage:

1. S_SUBJECT.U_MRN - *Subject or patient identifier*
2. S_SAMPLEFAMILY.COLLECTIONDT - *Collection date of the sample*
3. S_PARTICIPANTEVENT.EVENTDT - *An event data associated with the sample*
4. S_SAMPLE.S_SAMPLEID - *A sample identifier for the sample*
5. S_SAMPLE.SAMPLETYPEID - *An identifier for the type of sample*
6. S_SAMPLEFAMILY.COLLECTMETHODID - *A description of the sample collection method*
7. S_SAMPLEDETAIL.TREATMENT - *A description of sample treatment*
8. S_CLINICALDIAG.S_CLINICALDIAGID - *A clinical diagnosis identifier.*
9. S_CLINICALDIAG.CLINICALDIAGDESC - *A clinical diagnosis description*
10. TRACKITEM.S_TISSUEID - *A sample tissue identifier*
11. TRACKITEM.TISSUEDESC - *A sample tissue description*
11. S_SAMPLE.SSTUDYID - *A sample study identifier*
12. S_STUDY.U_PI - *A study principal investigator*

CONFIG File

Config file is rather ugly since this is a quick and dirty program.

Each study can have mutiple lines. Separated by tab delimited columns of data. The first column gives the short name of the study that will be used on subsequent lines. An example study configuration is below:

```
PAL	Peanut Allergy Biomarkers	Rodney McKay	7/16/2004	1/9/2009	300	1	1	Allergy to peanuts[Z91.010]|control	0.6|0.4
PAL	sample	1	Whole Blood	Whole Blood	Phlebotomy	1	DNAase	null	null
PAL	sample	1	mRNA	mRNA	null	0.98	DNAase	null	null
```
Line 1 gives the study meta data with columns as:
1. The short name of the study (PAL)
2. The longer study name (Peanut Allergy Biomarkers)
3. The study PI (Peanut Allergy Biomarkers)
4. The start date of the study (7/16/2004)
5. The end date of the study (1/9/2009)
6. The number of subjects that will be involved in the study (1/9/2009)
7. The minimum wait in days between research encounters (1)
8. The variance wait time in days between encounters (1)
9. The list of clinical diagnosis that will be picked from. For example *Allergy to peanuts[Z91.010]|control* which gives two names for diagnoses separate by a pipe. The first named diagnosis has an associated diagnosis Id (*Z91.010*)
10. This the probability of picking the diagnoses listed in column 9. ie *0.6|0.4* indicates a 60% chance of the research subject being a patient diagnosed with a peanut allergy and a 40% chance of the research subect being a patient diagnosed as a control subject.

Subsequent lines for the study define the samples that were collected from research participants:

1. The short name of the study
2. Identifies this as a sample line in the config file
3. The encounter number that the sample will be collected on
4. The sample type identifier
5. The sample type description
6. The sample collection method
7. The probabilty that the sample was collected. This must be between 0 and 1. This allows for simulating data sets wil missing samples. For example. a mRNA sampling probability of 0.98 means that 2% of the mRNA samples could not be collected.
8. Sample Treatment. (DNAase for example)
9. Sample tissue identifier (can be null)
10. Sample tissue description (can be null)

Yeah ... not an optimal way to do a config file, but I had to crank this out super fast. A full configuration file example is the file named biorep_studies_config.txt.

The END of the config file is indicated with a study named END.



