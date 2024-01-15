* Encoding: UTF-8.

* set the folder where the data and the pre-programmed analyses and graphics (gpl) are. 
FILE HANDLE data /NAME= "C:\Users\st\surfdrive\Actief\2401 AFFECT-2 (Eva Molendijk)".
FILE HANDLE gpl /NAME= "C:\Users\st\surfdrive\Actief\2401 AFFECT-2 (Eva Molendijk)\gpl".


** first db is called original.
GET
  FILE="data\Database_vertical_CIT CRP Fever.sav".
DATASET NAME original WINDOW=FRONT.


***************** derived VARIABLES needed for the analysis if needed *******.
COMPUTE logplus_CRP=ln(CRP+1).
EXECUTE.


*******************  DATASETS (subsets) ****************************.

* other db (for subsets) are defined as follows.

* > activate the source db .
DATASET ACTIVATE  original.
* > first make a copy of source db with the intended name of the new db..
DATASET COPY only_rand2.
* > activate the copy so that the coming SPSS code applies to it.
DATASET ACTIVATE only_rand2.
* note: 'SELECT IF will permanently delete records in the dataset, therefore we made a copy!.
* and do NOT use a select data>select cases in the SPSS menu.
SELECT IF (rand =2). 
EXECUTE.


*********************************************************************************.

* read macros to be used in the analysis.
INSERT   FILE= 'gpl\macros.sps'.

*****************************************************************************.



!describe_repmeas cont_outcome=(CRP) repeatedmeasure=(Studyday) 
         subject=(participant_id) subject_is_string=(1) group=(rand)
         dataset=(original).


* seems up to 3rd or possibly 4th power.
DATASET ACTIVATE original.
SORT CASES BY rand.
SPLIT FILE BY rand.
!spagplots_2level cont_outcome=(CRP) repeatedmeasure=(Studyday)  
            subject=(participant_id) subject_is_string=(1)
            dataset=(original).
SPLIT FILE OFF.


* only intercept on CRP.
* in terms of the residuals bad fit.
!linear_2level cont_outcome=(CRP) repeatedmeasure=(Studyday) 
    subject=(participant_id) subject_is_string=(1)   
    fixed=(rand) random=(intercept) covars=(rand) cofactors=() covtype=(UN)
     dataset=(original)
.

*only intercept on logplus_CRP.
* in terms of the residuals better fit, but in terms of observed vs predicted not.
!linear_2level cont_outcome=(logplus_CRP) repeatedmeasure=(Studyday) 
    subject=(participant_id) subject_is_string=(1)   
    fixed=(rand) random=(intercept) covars=(rand) cofactors=() covtype=(UN)
    dataset=(original)
 .


* up to including 3rd power on logplus_CRP.
!linear_2level cont_outcome=(logplus_CRP) repeatedmeasure=(Studyday) 
    subject=(participant_id) subject_is_string=(1)   
    fixed=(rand studyday studyday*studyday studyday*studyday*studyday) 
    random=(intercept studyday studyday*studyday studyday*studyday*studyday) 
    covars=(rand studyday) cofactors=() covtype=(UN)
    dataset=(original)
 .












 

