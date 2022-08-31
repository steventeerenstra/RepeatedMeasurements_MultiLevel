* Encoding: UTF-8.
* define file handles where the gpl folder is (containing macros.sps and the needed gpl files).
* and the file handle where the dataset is.
* absolute folder paths must be used.
FILE HANDLE gpl /NAME ="C:\Users\st\surfdrive\Actief\18 AB assistent (Annelies Verbon)\2207 analyse ErasmusMC\220830\gpl".
FILE HANDLE data /NAME ="C:\Users\st\surfdrive\Actief\18 AB assistent (Annelies Verbon)\2207 analyse ErasmusMC\220830".


* Open data and name it 'original' for use in macros later on.
GET FILE="data\AB-assistant - SPSS - EMC - 2022-07-12.sav".
DATASET NAME original.  
EXECUTE.

* read macros to be used in the analysis.
INSERT   FILE= 'gpl\macros.sps'.

***************************variables***********************************.
COMPUTE correct=0.
IF Chosen_antimicrobials_correct=1 correct=1.
EXECUTE.


*****************datasets ***************.
* define dataset with a subset of the patients, in this case only the SW part, not the follow-up.
DATASET ACTIVATE  original.
* first make a copy.
DATASET COPY only_SWpart.
* activate it so that the coming SPSS code applies to it.
DATASET ACTIVATE only_SWpart.
* note: 'SELECT IF will permanently delete records in the dataset, therefore we made a copy!.
SELECT IF (meetperiode < 8). 
EXECUTE.
****************.
* define dataset with only indication = pneumonia.
DATASET ACTIVATE original.
DATASET COPY pneumonia_HA.
DATASET ACTIVATE pneumonia_HA.
SELECT IF indication_1=106.
EXECUTE.



*** analyses binary outcome on dataset original: odds ratio and difference in probability (2 models) *****. 
title "Odds ratio for the probability".
!bin_random_intercept_2level
bin_outcome=(correct) level2=(entity) level1=(subjectID) repeated_measure=(meetperiode)
fixed=(interventie meetperiode) intervention=(interventie)
dataset=(original)
.

title "Difference in the probability".
!bin_random_intercept_2level
bin_outcome=(correct) level2=(entity) level1=(subjectID) repeated_measure=(meetperiode)
fixed=(interventie meetperiode) intervention=(interventie)
distribution=(binomial) link=(identity)
dataset=(original)
.

title "Difference in the probability (using linear mixed model)".
!bin_random_intercept_2level
bin_outcome=(correct) level2=(entity) level1=(subjectID) repeated_measure=(meetperiode)
fixed=(interventie meetperiode) intervention=(interventie)
distribution=(normal) link=(identity)
dataset=(original)
.



*** analyses binary outcome on dataset only_SWpartl: odds ratio and difference in probability (2 models) *****. 

title "Odds ratio for the probability".
!bin_random_intercept_2level
bin_outcome=(correct) level2=(entity) level1=(subjectID) repeated_measure=(meetperiode)
fixed=(interventie meetperiode) intervention=(interventie)
dataset=(only_SWpart)
.

title "Difference in the probability".
!bin_random_intercept_2level
bin_outcome=(correct) level2=(entity) level1=(subjectID) repeated_measure=(meetperiode)
fixed=(interventie meetperiode) intervention=(interventie)
distribution=(binomial) link=(identity)
dataset=(only_SWpart)
.

title "Difference in the probability (using linear mixed model)".
!bin_random_intercept_2level
bin_outcome=(correct) level2=(entity) level1=(subjectID) repeated_measure=(meetperiode)
fixed=(interventie meetperiode) intervention=(interventie)
distribution=(normal) link=(identity)
dataset=(only_SWpart)
.


**analysis continuous outcome on dataset original ****.


title "difference in actual duration therapy".
!continu_random_intercept_2level
continu_outcome=(actual_duration_therapy) level2=(entity) level1=(subjectID) repeated_measure=(meetperiode)
fixed=(interventie meetperiode) intervention=(interventie) covars=(interventie) cofactors=(meetperiode)
dataset=(original)
.












