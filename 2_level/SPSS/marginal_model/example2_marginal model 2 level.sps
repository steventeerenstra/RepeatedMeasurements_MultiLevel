* Encoding: UTF-8.
* to do.
* ANCOVA analysis on T0 and T2.
* diagnosis has two levels and may have different time trend.




* Encoding: UTF-8.
* provide the folder "directory" where the gpl files are stored (these are used in the macros below.
* provide the folder "data" where the dataset is. 
* >>>> comment out the non-relevant part by preceding with a *.
* voor Steven.
FILE HANDLE gpl /NAME ="S:\gpl".
FILE HANDLE data /NAME ="S:\".
* voor Stacha, probably something like FILE HANDL gpl /NAME="H\tDS CCAS\Analyses_Statistics.
*FILE HANDLE gpl  /NAME ="....\gpl".
*FILE HANDLE data  /NAME ="....".


* Open data and name it for use in macros later on.
GET FILE="data\Data compleet LMM.sav".
DATASET NAME source.  
EXECUTE.

****************MACROS****************************************************************************.
* read macros.
INSERT   FILE= 'gpl\macros.sps'.
**********************************************************************************************************.




***************** derived VARIABLES needed for the analyses *************************.
****** data transformations ***********************.
* make a numeric variable for time points.
* so if T0, T1, etc are string variables, then they have (additionally) to be recoded.
COMPUTE timepoint=stage.
EXECUTE. 
* to get no decimals in output such as tables/ graphs.
FORMATS timepoint (f4.0).

* time in weeks.
COMPUTE time=0.
IF timepoint=1 time=2.
IF timepoint=2 time=6.
IF timepoint=3 time=13.
IF timepoint=4 time=26.
IF timepoint=5 time=52.
EXECUTE.
* no decimals needed for weeks.
FORMATS time(f4.0).

* dummy variabelen voor de tijdspunten.
COMPUTE T1=0.
If timepoint=1 T1=1.
COMPUTE T2=0.
If timepoint=2 T2=1.
COMPUTE T3=0.
If timepoint=3 T3=1.
COMPUTE T4=0.
If timepoint=4 T4=1.
COMPUTE T5=0.
If timepoint=5 T5=1.
EXECUTE.

* groups.
COMPUTE grp=$SYSMIS.
IF (randomized_group="X") grp=0.
IF (randomized_group="Y") grp=1.
EXECUTE.
* when is the intervention, fake at the moment. 
COMPUTE trt=0.
IF (timepoint>=1 AND grp=1) trt=1.
EXECUTE.
* variable / value labels.
VARIABLE LABELS trt 'intervention'.
VALUE LABELS trt 0 'fake sham' 1 'fake intervention'. 
VALUE LABELS grp 0 "fake control arm" 1 "fake interventie arm".



*******************  DATASETS (subsets used in the analyses) ****************************.

* datasets (e.g. for subset analyses or change from baseline or adjustment for baseline covariates) are defined as follows.

*********************************************************.
*** dataset with all measurements and all baseline covariates that you may want to adjust for. 
DATASET ACTIVATE  source.
* > first make a copy of source db with the intended name of the new db..
DATASET COPY withbaseline.
* > activate the copy so that the coming SPSS code applies to it.
DATASET ACTIVATE withbaseline.
!add_baseline
var=(zmem) var_base=(zmem_base) 
id=(participant_id)
repeatedmeasure=(timepoint) first_repeatedmeasure=(0) 
dataset=(withbaseline)
.
** perhaps do this also for other variables that you want to adjust for.
!add_baseline
var=(zflex) var_base=(zflex_base) 
id=(participant_id)
repeatedmeasure=(timepoint) first_repeatedmeasure=(0) 
dataset=(withbaseline)
.


** dataset with change score (and it retains the baseline covariates you want to correct for from the withbaseline dataset).
DATASET ACTIVATE  withbaseline.
* > first make a copy of the db with the intended name of the new db..
DATASET COPY change.
* > activate the copy so that the coming SPSS code applies to it.
DATASET ACTIVATE change.
** calculate changes from baseline.
COMPUTE change_zmem=zmem-zmem_base.
COMPUTE change_zflex=zflex-zflex_base.
EXECUTE.
* no change from baseline for timepoint=baseline, so we select only time point 1,2,3,4,5. 
SELECT IF (timepoint>=1).
EXECUTE.


* dataset for the ancova analysiss on the change score in ther repeated measures model.
* this is the same as ancova on the outcome (i.e. not change from baseline).
DATASET ACTIVATE  change.
* > first make a copy of the db with the intended name of the new db..
DATASET COPY classicalancova.
* > activate the copy so that the coming SPSS code applies to it.
DATASET ACTIVATE classicalancova.
SELECT IF (timepoint=2).
EXECUTE.


**************************ANALYSES **************************************************************************************************.

**********************     ALL TIME POINTS INCLUDING BASELINE:  analysis visualization ***************************************************.
* describe the available measurements and the distribution of the outcome.
* note: the minimal repeatedmeasure (timepoint) is 0. 
* note: the group is here grp.
!describe_repmeas_grid 
cont_outcome=(zmem) repeatedmeasure=(timepoint)
min_repeatedmeasurement=(0) max_repeatedmeasurement=(5)
subject=(participant_id) subject_is_string=(1)
group=(grp) dataset=(source)
.

* spaghetti plot for T0-T5 (timepoint).
!spagplot_bygroup
cont_outcome=(zmem) repeatedmeasure=(timepoint)  
subject=(participant_id) subject_is_string=(1)  
group=(grp) 
dataset=(source).
.

*spaghettiplot in terms of weeks (0,2 weeks etc: time). 
!spagplot_bygroup
cont_outcome=(zmem) repeatedmeasure=(time)  
subject=(participant_id) subject_is_string=(1) 
group=(grp) 
dataset=(source).


*panel plot with the individual profiles in a panel with timepoint.
!spagplot_panel
cont_outcome=(zmem) repeatedmeasure=(timepoint)  
subject=(participant_id) subject_is_string=(1) 
dataset=(source).

* per diagnosis.
DATASET ACTIVATE source.
SORT CASES  BY diagnosis.
SPLIT FILE LAYERED BY diagnosis.
!spagplot_panel
cont_outcome=(zmem) repeatedmeasure=(timepoint)  
subject=(participant_id) subject_is_string=(1) 
dataset=(source).
SPLIT FILE OFF.



*panel plots fit with individual profiles with time (weeks instead of time point).
!spagplot_panel
cont_outcome=(zmem) repeatedmeasure=(time)  
subject=(participant_id) subject_is_string=(1) 
dataset=(source).
 
********************* ALL TIME POINTS INCLUDING BASELINE:  fitting models ****************************************************************************.
* by design trt and timepoint should be in the model.
* residuals not peaked around zero.
* observed valuesmostly  not 'around' predicted profile.
* this seems a bad fit. 
!marginal_2level
cont_outcome=(zmem) repeatedmeasure=(timepoint) 
subject=(participant_id) subject_is_string=(1)  
fixed=(trt timepoint) covars=(trt) cofactors=(timepoint) 
covtype=(UN) method=(reml)
dataset=(withbaseline)
.



*************CHANGE FROM BASELINE : visualzation*******************************************.
**** look at change from baseline, now the min_repeatedmeasure=1***.
* describe the available measurements and the distribution of the outcome.
* change from baseline seems a bit more symmetrically distributed.
* note: group can here be grp or trt (because we left out time point =0). 
!describe_repmeas_grid 
cont_outcome=(change_zmem) repeatedmeasure=(timepoint)
min_repeatedmeasurement=(1) max_repeatedmeasurement=(5)
subject=(participant_id) subject_is_string=(1)
group=(trt) dataset=(change)
.

* profiles seem less wild.
* spaghetti plot for T1-T5 (timepoint).
!spagplot_bygroup
cont_outcome=(change_zmem) repeatedmeasure=(timepoint)  
subject=(participant_id) subject_is_string=(1) 
group=(grp) 
dataset=(change).


*spaghettiplot in terms of weeks (0,2 weeks etc: time). 
!spagplot_bygroup
cont_outcome=(change_zmem) repeatedmeasure=(time)  
subject=(participant_id) subject_is_string=(1) 
group=(grp) 
dataset=(change).
.



********************* CHANGE FROM BASELINE: modeling fitting ***.

*** change: modeling fitting ***.
* the design dictates that  trt and timepoint should be in the model.
* even though time point is not stat.sign. (this is then a finding, not a reason to reduce the model). 
* only trt+ timepoint: AIC=290.
!marginal_2level
cont_outcome=(change_zmem) repeatedmeasure=(timepoint) 
subject=(participant_id) subject_is_string=(1)  
fixed=(trt timepoint) covars=(trt) cofactors=(timepoint) 
covtype=(UN) method=(reml)
dataset=(change)
.

* trt base +timepoint: AIC=284.
* the AIC suggests better fit, but c06 fits worse and c58 better. 
* so it is more a give and take. 
!marginal_2level
cont_outcome=(change_zmem) repeatedmeasure=(timepoint) 
subject=(participant_id) subject_is_string=(1)  
fixed=(trt zmem_base timepoint) covars=(trt zmem_base) cofactors=(timepoint) 
covtype=(UN) method=(reml)
dataset=(change)
.

**trt base +timepoint + trt*timepoint: AIC=289.
* the AIC suggests not really a worse fit than previous (284). 
* it seems more profiles fit somethat better (e.g. c57 and c58).
* some suggestion of treatment * time interaction, but not stat.sign.. 
 !marginal_2level
cont_outcome=(change_zmem) repeatedmeasure=(timepoint) 
subject=(participant_id) subject_is_string=(1)  
fixed=(trt zmem_base timepoint trt*timepoint) covars=(trt zmem_base) cofactors=(timepoint) 
covtype=(UN) method=(reml)
dataset=(change)
.


************ ANCOVA model from the repeatted measurments model using a contrast ******.
* by design there is only one outcome measurement, so only trt and zmem_base in the model. 
* see the Custom Hypothesis Test for the estimated trt effect at T2.
*  esitmate is -0.235 and SE=0.283.
 !marginal_2level
cont_outcome=(change_zmem) repeatedmeasure=(timepoint) 
subject=(participant_id) subject_is_string=(1)  
fixed=(trt zmem_base timepoint trt*timepoint) covars=(trt zmem_base) cofactors=(timepoint) 
covtype=(UN) method=(reml)
extra=(/TEST 'treatment at T2'  trt 1 trt*timepoint 0 1 0 0 0)
dataset=(change)
.




****** CLASSICAL ANOVA: only one time point avaible: T2 and correction on baseline.
* note that some graphs will not be possible to  make since only 1 timepoint.
* note that the estimate is virtually the same: -0.248 and the SE=0.282 (virtually the same).
 !marginal_2level
cont_outcome=(change_zmem) repeatedmeasure=(timepoint) 
subject=(participant_id) subject_is_string=(1)  
fixed=(trt zmem_base ) covars=(trt zmem_base) cofactors=(timepoint) 
covtype=(UN) method=(reml)
dataset=(classicalancova)
.

* as a check: the same values as with linear regression 
DATASET ACTIVATE classicalancova.
REGRESSION
  /MISSING LISTWISE
  /STATISTICS COEFF OUTS R ANOVA
  /CRITERIA=PIN(.05) POUT(.10)
  /NOORIGIN 
  /DEPENDENT change_zmem
  /METHOD=ENTER trt zmem_base.
