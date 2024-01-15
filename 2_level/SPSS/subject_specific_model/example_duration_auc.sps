* Encoding: UTF-8.

* set the folder where the data and the pre-programmed analyses and graphics (gpl) are. 
FILE HANDLE data /NAME= "C:\Users\st\surfdrive\Actief\2401 AFFECT-2 (Eva Molendijk)".
FILE HANDLE gpl /NAME= "C:\Users\st\surfdrive\Actief\2401 AFFECT-2 (Eva Molendijk)\gpl".


** open the database with replicates.
GET
  FILE="data\Database_vertical_CIT CRP Fever repl.sav".
DATASET NAME replicates WINDOW=FRONT.


***************** derived VARIABLES needed for the analysis if needed *******.
COMPUTE logplus_CRP=ln(CRP+1).
EXECUTE.

* show that the variable studyday has now much more decimals.
FORMATS  studyday (f8.3).
EXECUTE.

*******************  DATASETS (subsets) ****************************.

* other db (for subsets) are defined as follows.

* > activate the source db .
DATASET ACTIVATE  replicates.
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


*use  the replicates dataset.
* in this dataset the original records are present (replicate=0).
*  but also extra record are present (replicates=1) that have the repeated measurement (studyday).
* with more resolution: so also repeated measurement  values in between the original ones, see the dataset.


* fit the best model determined earlier but now to replicates dataset.
* and save the predicted CRP as pred_crp.
* see the dataset: now also predicted crp for in between original measurements.
!linear_2level cont_outcome=(logplus_CRP) repeatedmeasure=(Studyday) 
    subject=(participant_id) subject_is_string=(1)   
    fixed=(rand studyday studyday*studyday studyday*studyday*studyday) 
    random=(intercept studyday studyday*studyday studyday*studyday*studyday) 
    covars=(rand studyday) cofactors=() covtype=(UN)
    dataset=(replicates)
    save_pred=(pred_crp)
 .

* check the predicted profiles with what was analysed.
* but only within the observed range.
* so make a separate dataset with only the replicates .
*   and up to the last measurement with CRP.
DATASET ACTIVATE replicates.
DATASET COPY observed_range_CRP.
DATASET ACTIVATE observed_range_CRP.
SELECT IF (studyday <=last_CRP) AND (replicate=1). 
EXECUTE.

SORT CASES BY rand.
SPLIT FILE BY rand.
!spagplots_2level cont_outcome=(pred_crp) repeatedmeasure=(Studyday)  
            subject=(participant_id) subject_is_string=(1)
            dataset=(observed_range_CRP).
SPLIT FILE OFF.

******************************************** define for which variable we want to calculate duration and AUC. 
* if necessary also avoid that values have values below 0. 
* here logplus crp cannot be below 0 because CRP >=0, so rp +1 >= 1, so ln(CRP+1) >0. 
COMPUTE predicted=pred_crp.
* we truncate values for pred (=predicted crp) < 0 to 0.
IF predicted <0    predicted=0.
EXECUTE.
    




********duration*******************
* calculate by subject his/her duration above threshold CRP =50, i.e., logplus >= ln(50 + 1) ~ 3.93.
* the logic is: 
*    if a measurement has logplus >=ln(51) and the previous measurement (lag(..)) has logplus >=ln(51) as well.
*    then the entire interval from the previous to the current measurement counts as above ln(51).
*   (note that we exclude the first study day (i.e. studyday=1), because that has no previous one).
*    and the variable above_ln51 gets the duration of the interval.
*    then (later) we aggregate by patient to get her/his entire duration of logplus_crp > ln(51). 

* first make sure that the data is ordered by subject and by studyday.
DATASET ACTIVATE observed_range_CRP.
SORT CASES  BY participant_id    Studyday.
EXECUTE.


COMPUTE above_ln51 = 0. 
IF (studyday > 1) AND (  predicted > ln(51)  ) AND (  lag(predicted) > ln(51) )      above_ln51=( studyday-lag(studyday) ).
EXECUTE. 

*******AUC (area under the curve) *****.
* calculate by subject his/her area under the logplus_CRP curve. 
* the logic is: 
*    the area under the current and previous measurement of logplus_CRP. 
*   is approximated by the areau trapezoid spanned by the current and previous measurement.
*   the area of this trapezoid is ( https://en.wikipedia.org/wiki/Trapezoidal_rule): 
*  1/2*(current logplus_CRP value + previous logplus CRP value) x (length from current to previous measurement). 
*   (again note that we exclude the first study day (i.e. studyday=1), because that has no previous one).

COMPUTE area = 0.
IF (studyday>1)     area=1/2 * ( predicted + lag(predicted)  ) *  ( studyday-lag(studyday) ). 
EXECUTE. 


*** check what values we got.
MEANS TABLES= above_ln51 area   
    /CELLS=MEAN COUNT STDDEV MIN MAX. 

** now sum up by subject in put in the dataset crp_summaries.
DATASET DECLARE crp_summaries.
AGGREGATE
  /OUTFILE='crp_summaries'
  /BREAK=rand participant_id
  /logplusCRP_above_ln51_duration=SUM(above_ln51) 
  /logplusCRP_AUC=SUM(area).

*compare distributions.
* duration.
DATASET ACTIVATE crp_summaries.
GRAPH
  /HISTOGRAM=logplusCRP_above_ln51_duration
  /PANEL ROWVAR=rand ROWOP=CROSS.
T-TEST GROUPS=rand(1 2)
  /MISSING=ANALYSIS
  /VARIABLES=logplusCRP_above_ln51_duration
  /ES DISPLAY(TRUE)
  /CRITERIA=CI(.95).
NPAR TESTS
  /M-W= logplusCRP_above_ln51_duration BY rand(1 2)
  /MISSING ANALYSIS.

*AUC.
DATASET ACTIVATE crp_summaries.
GRAPH
  /HISTOGRAM=logplusCRP_AUC
  /PANEL ROWVAR=rand ROWOP=CROSS.
T-TEST GROUPS=rand(1 2)
  /MISSING=ANALYSIS
  /VARIABLES=logplusCRP_AUC
  /ES DISPLAY(TRUE)
  /CRITERIA=CI(.95).
NPAR TESTS
  /M-W= logplusCRP_AUC BY rand(1 2)
  /MISSING ANALYSIS.


