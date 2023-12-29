* Encoding: UTF-8.
* data has to be open first before the macro is loaded as otherwise the COMPUTE statements in the macro cause errors.
**** see https://www.ibm.com/support/knowledgecenter/en/SSLVMB_24.0.0/spss/base/syn_define_arguments.html  for more parameters ***.

* note the file references to spaghetti_plot.gpl and panelspaghetti_plot.gpl have to be adapted in the macro.
DEFINE   !spagplots_2level(cont_outcome=!ENCLOSE('(',')')   /repeatedmeasure=!ENCLOSE('(',')')  /subject=!ENCLOSE('(',')') )
*auxiliary temporary variables for use in GPL files. 
COMPUTE cont_outcome=!cont_outcome. 
COMPUTE repeatedmeasure=!repeatedmeasure.
COMPUTE subject=!subject.

title !QUOTE(!CONCAT("spaghetti plot for outcome *", !cont_outcome,"*")). 
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=repeatedmeasure cont_outcome subject[LEVEL=NOMINAL] 
 /GRAPHSPEC SOURCE=GPLFILE("gpl\spaghetti_plot.gpl")
 
title !QUOTE(!CONCAT("spaghetti plot for *",!cont_outcome,"* by *",!subject,"*")). 
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=repeatedmeasure cont_outcome subject[LEVEL=NOMINAL] 
 /GRAPHSPEC SOURCE=GPLFILE("gpl\panelspaghetti_plot.gpl")
 
*clean up for new analysis and graphics of other variable.
* delete the variables made in the macro in the original dataset (=main).
DELETE VARIABLES   cont_outcome repeatedmeasure subject.
!ENDDEFINE.


*** random intercept and random slopes at level 2 using MIXED. 
*** note the file references to residuals_subject.gpl and linear_profile.gpl have to be adapted in the macro.
DEFINE   !linear_2level(cont_outcome=!ENCLOSE('(',')')   /repeatedmeasure=!ENCLOSE('(',')')  /subject=!ENCLOSE('(',')')   
/fixed=!ENCLOSE('(',')') /random=!ENCLOSE('(',')') /covars=!ENCLOSE('(',')') /cofactors=!ENCLOSE('(',')') /covtype=!DEFAULT(UN) !ENCLOSE('(',')') )

** assumes that intervention is randomized at subject-level (level 2) and repeated measurements (level 1) are at repeatedmeasure-level.
** min and max take the range of the vertical axis in the plots of the outcome variable.

title !QUOTE(!CONCAT("continuous outcome is ",!cont_outcome)). 
* first make the levels of the multi level regression nomimal variables.
* define the continuous outcome variable and the repeated measurement variable.
COMPUTE cont_outcome=!cont_outcome. 
COMPUTE repeatedmeasure=!repeatedmeasure.
COMPUTE subject=!subject.


******* analyse the continuous outcome variable **********.
MIXED cont_outcome WITH !covars BY !subject !cofactors
   /FIXED= !fixed
  /RANDOM=!random | SUBJECT(!subject) COVTYPE(!covtype)
   /PRINT=SOLUTION TESTCOV
   /SAVE=PRED(pred1) RESID(resid1)
.

************* residuals plot (by subjects so different colors per subject) ********************************.
title !QUOTE(!CONCAT("residual plot for ",!cont_outcome," (symmetric around 0?)")). 
* reference line.
COMPUTE zeroline=0.
EXECUTE.
* note that GPL code blocks cannot be within in macro: .
* https://www.ibm.com/support/pages/gpl-blocks-will-not-run-my-macro-or-production-job.
GGRAPH
 /GRAPHDATASET NAME="graphdataset" VARIABLES=pred1 resid1 subject zeroline MISSING=LISTWISE 
   REPORTMISSING=NO
 /GRAPHSPEC SOURCE=GPLFILE("gpl\residuals_subject.gpl")
 .

*** panel plot of observed versus predicted profiles by subject.
COMPUTE cont_outcome_pred=pred1.
EXECUTE.

title !QUOTE(!CONCAT("observed (dots) vs predicted (line) for ",!cont_outcome)). 
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=repeatedmeasure cont_outcome cont_outcome_pred subject[LEVEL=NOMINAL] 
 /GRAPHSPEC SOURCE=GPLFILE("gpl\linear_profile.gpl")


*clean up for new analysis and graphics of other variable.
* delete the variables made in the macro in the original dataset (=main).
DELETE VARIABLES   cont_outcome repeatedmeasure pred1 resid1 subject cont_outcome_pred zeroline.

!ENDDEFINE.

***************************************************************************************************************************.
****************************** design info 2 level**************************************************************************.
***************************************************************************************************************************.

DEFINE !design_2level(outcome=!ENCLOSE('(',')')
/level2=!ENCLOSE('(',')') 
/intervention=!DEFAULT('') !ENCLOSE('(',')')
/repeated_measure=!DEFAULT('') !ENCLOSE('(',')')
/dataset=!DEFAULT('original') !ENCLOSE('(',')')
                                   )

***************************************************************************************************************************.
*********general information on design: number of patients in each cell (combination level2 x rep.meas.) *****.
DATASET ACTIVATE !dataset.
DATASET DECLARE design.
AGGREGATE
  /OUTFILE='design'
  /BREAK=!level2 !repeated_measure 
  /n_obs=NU(!outcome)
  /allocation=MEAN(!intervention)
  /average=MEAN(!outcome)
  .


** suppress the redundant output of the case processing summary in summarize.
OMS
  /SELECT TABLES
  /IF COMMANDS=['Summarize'] SUBTYPES=['Case Processing Summary']
  /DESTINATION VIEWER=NO
 .
** suppress the case to variables output.
OMS
  /SELECT TABLES
  /IF COMMANDS=['Cases to Variables']
  /DESTINATION VIEWER=NO.

***************** show first the numbers per cell, by deleting the variable allocation and average ***************.
**************************************** so that only the variable n_obs is left ******.
DATASET ACTIVATE design.
DATASET COPY design_n.
DATASET ACTIVATE design_n.
DELETE VARIABLES allocation average.
EXECUTE.


SORT CASES BY !level2 !repeated_measure.
* remove decimals to avoid errors in CASESTOVARS.
FORMAT!level2(f6.0).
FORMAT !repeated_measure(f6.0).

CASESTOVARS
  /ID=!level2
  /INDEX=!repeated_measure
  /GROUPBY=VARIABLE
  .

SUMMARIZE
  /TABLES=ALL
  /FORMAT=NOCASENUM NOTOTAL LIST
  /TITLE='number of observations for each combination of level 2 unit (rows) and repeated measure (columns)'
  /MISSING=VARIABLE
  /CELLS=MEAN
 .

***************** show the design, now by deleting n_obs and average ***************************.
DATASET ACTIVATE design.
DATASET COPY design_allocation.
DATASET ACTIVATE design_allocation.
DELETE VARIABLES n_obs average.
EXECUTE.
SORT CASES BY !level2 !repeated_measure.
* remove decimals to avoid errors in CASESTOVARS.
FORMAT!level2(f6.0).
FORMAT !repeated_measure(f6.0).
CASESTOVARS
  /ID=!level2
  /INDEX=!repeated_measure
  /GROUPBY=VARIABLE
 .

SUMMARIZE
  /TABLES=ALL
  /FORMAT=NOCASENUM NOTOTAL LIST
  /TITLE='allocation for each combination of level 2 unit (rows) and repeated measure (columns)'
  /MISSING=VARIABLE
  /CELLS=MEAN
 .
 
 ***************** show the average of the outcome by cluster-period, now by deleting n_obs and allocation ***************************.
DATASET ACTIVATE design.
DATASET COPY design_average.
DATASET ACTIVATE design_average.
DELETE VARIABLES n_obs allocation.
EXECUTE.
SORT CASES BY !level2 !repeated_measure.
* remove decimals to avoid errors in CASESTOVARS.
FORMAT!level2(f6.0).
FORMAT !repeated_measure(f6.0).
CASESTOVARS
  /ID=!level2
  /INDEX=!repeated_measure
  /GROUPBY=VARIABLE
 .

SUMMARIZE
  /TABLES=ALL
  /FORMAT=NOCASENUM NOTOTAL LIST
  /TITLE='average of the outcome for each combination of level 2 unit (rows) and repeated measure (columns)'
  /MISSING=VARIABLE
  /CELLS=MEAN
 .

*** output all on.
OMSEND.

*clean up.
DATASET ACTIVATE !dataset.
DATASET CLOSE design.
DATASET CLOSE design_n.
DATASET CLOSE design_allocation.
DATASET CLOSE design_average.

!ENDDEFINE.


***************************************************************************************************************************.
****************************** decription overall distribution of a continuous outcome******************************************.
***************************************************************************************************************************.

DEFINE !continu_descrip( outcome=!ENCLOSE('(',')') 
    /intervention=!ENCLOSE('(',')')   )

title !QUOTE(!CONCAT("distribution of ", !outcome)).
title " over all clusters and periods".

GRAPH
  /HISTOGRAM=!outcome
  /PANEL ROWVAR=!intervention ROWOP=CROSS.

EXAMINE VARIABLES=!outcome BY !intervention
   /PLOT NONE
  /STATISTICS DESCRIPTIVES
    /CINTERVAL 95
  /MISSING LISTWISE
  /NOTOTAL.

!ENDDEFINE.


***************************************************************************************************************************.
**** decription distribution of a binary outcome ******************************************.
*****overall and by cluster *************************************************************************************************************.

DEFINE !bin_descrip( outcome=!ENCLOSE('(',')') 
    /intervention=!ENCLOSE('(',')') /level2=!ENCLOSE('(',')') 
)

title !QUOTE(!CONCAT("overall distribution of ", !outcome)).
title " over all clusters and periods".
title " assuming {0,1} coding for outcome".
GRAPH
  /BAR(SIMPLE)=PGT(0)(!outcome) BY !intervention
.

title !QUOTE(!CONCAT("distribution of ", !outcome)).
title " by cluster but over all periods within cluster".
title " assuming {0,1} coding for outcome".
GRAPH
  /BAR(SIMPLE)=PGT(0)(!outcome) BY !intervention
  /PANEL COLVAR=!level2 COLOP=CROSS.

!ENDDEFINE.



***************************************************************************************************************************.
****************************** binary 2 level random intercept**************************************************************************.
***************************************************************************************************************************.

** random intercept at level 2 using GENLINMIXED, so for e.g. binary outcomes***.
** using link=identity also percentage differences can be done .
** also linear mixed model can be done: distribution=normal and link=identity.
** assumes intervention is coded 0 and 1 and bin_outcome is 0, 1 coded.
**with randominterceptlevel2=(no) you can turn of the random intercept ***.
DEFINE !bin_random_intercept_2level(bin_outcome=!ENCLOSE('(',')')
/level2=!ENCLOSE('(',')') 
/level1=!ENCLOSE('(',')')
/fixed=!ENCLOSE('(',')')
/factor_ordering=!DEFAULT('DESCENDING') !ENCLOSE('(',')')
/intervention=!DEFAULT('') !ENCLOSE('(',')')
/repeated_measure=!DEFAULT('') !ENCLOSE('(',')')
/distribution=!DEFAULT('BINOMIAL') !ENCLOSE('(',')') /link=!DEFAULT('LOGIT') !ENCLOSE('(',')')
/randominterceptlevel2=!DEFAULT('YES') !ENCLOSE('(',')')
/dataset=!ENCLOSE('(',')')
                                   )


*** general information on the outcome in this design.
!design_2level
outcome=(!bin_outcome)
level2=(!level2)
intervention=(!intervention)
repeated_measure=(!repeated_measure)
dataset=(!dataset)
.

**** general description ***.
!bin_descrip
outcome=(!bin_outcome)
level2=(!level2)
intervention=(!intervention)
.


**********************************************************************.
********* genlinmixed analysis ***********************************.

DATASET ACTIVATE !dataset.

!IF ( !upcase(!link)='IDENTITY'  ) !THEN title !QUOTE(!CONCAT("difference in outcome=",!bin_outcome)).
!IFEND.
!IF ( !upcase(!link)= 'LOGIT' ) !THEN title !QUOTE(!CONCAT("odds ratio of outcome=",!bin_outcome)).
!IFEND.
title !QUOTE(!CONCAT("in dataset = ", !dataset)). 

* change the variable level according to the distribution used, else GENLINMIXED will not run.
!IF ( !upcase(!distribution) = 'NORMAL' ) !THEN 
VARIABLE LEVEL !bin_outcome (SCALE) 
!IFEND
.
!IF ( !upcase(!distribution) = 'BINOMIAL' ) !THEN 
VARIABLE LEVEL !bin_outcome (NOMINAL) 
!IFEND
.


title " ".
title "for better (tabular) model output use: ".
title "https://www.theanalysisfactor.com".
title "/get-rid-of-spss-genlinmixed-model-viewer/".
* note for normal distribution: predicted_values should be saved.
* for binomial distribution: predicted_probability should be saved.

GENLINMIXED
!IF ( !upcase(!randominterceptlevel2) !EQ 'YES' ) !THEN
            /DATA_STRUCTURE SUBJECTS = !level2
!IFEND
/FIELDS TARGET=!bin_outcome
/TARGET_OPTIONS DISTRIBUTION =!distribution LINK=!link
/FIXED EFFECTS=!fixed
           USE_INTERCEPT = TRUE
!IF ( !upcase(!randominterceptlevel2) !EQ 'YES' ) !THEN /RANDOM USE_INTERCEPT= TRUE
                SUBJECTS=!level2 
                COVARIANCE_TYPE=VARIANCE_COMPONENTS
!IFEND
/BUILD_OPTIONS TARGET_CATEGORY_ORDER=DESCENDING
INPUTS_CATEGORY_ORDER=!factor_ordering 
MAX_ITERATIONS=100
CONFIDENCE_LEVEL=95 DF_METHOD=SATTERTHWAITE COVB=MODEL
!IF ( !upcase(!distribution) = 'NORMAL' ) !THEN /SAVE PREDICTED_VALUES(pred_prob_01)
!ELSE /SAVE PREDICTED_PROBABILITY(pred_prob)
!IFEND
.

************* model checking *************************************************.
*aggregating to level 2.
DATASET ACTIVATE !dataset.
DATASET DECLARE aggregated.
AGGREGATE
  /OUTFILE='aggregated'
  /BREAK=!level2 !repeated_measure !intervention
  /aggr_obs=MEAN(!bin_outcome)
  /aggr_pred=MEAN(pred_prob_01)
  .
  
DATASET ACTIVATE aggregated.
COMPUTE aggr_resid=aggr_obs - aggr_pred.
* the GPL file needs fixed names for the variables.
COMPUTE level2=!level2.
COMPUTE repeated_measure=!repeated_measure.
COMPUTE intervention=!intervention.
EXECUTE.

*observed profiles after aggregation to level 2, for each level 2 unit.
DATASET ACTIVATE aggregated.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=level2 repeated_measure intervention aggr_obs
    MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=GPLFILE("gpl\aggr_observed_profiles_range01.gpl")
.


* observed vs predicted plot after aggregation to level 2, for each level 2 unit.
DATASET ACTIVATE aggregated.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=level2 repeated_measure intervention aggr_obs aggr_pred
    MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=GPLFILE("gpl\aggr_observed_vs_predicted_profiles_range01.gpl")
.

* residuals vs predicted after aggregation to level 2, for each level 2 unit.
DATASET ACTIVATE aggregated.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=level2 aggr_pred aggr_resid 
    MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=GPLFILE("gpl\aggr_residuals_vs_predicted.gpl")
.

* descriptive statistics on the aggregated residuals (useful to compare models).
    ** suppress the case to variables output.
    OMS
      /SELECT TABLES
      /IF COMMANDS=['Means'] SUBTYPES=['Case Processing Summary']
      /DESTINATION VIEWER=NO
     . 
  
title "spread of the residuals (after aggregating) by level2 unit,".
title " and total (i.e. pooled over all level 2 units): ".
MEANS TABLES=aggr_resid BY level2
    /CELLS=COUNT STDDEV MIN MAX RANGE
.
    OMSEND.  

*clean up.
* 1: delete aggregated dataset.
DATASET ACTIVATE !dataset.
DATASET CLOSE aggregated.
* 2: delete auxiliary variables in main dataset original.
DELETE VARIABLES pred_prob_01.

!ENDDEFINE.



***************************************************************************************************************************.
****************************** continuous 2 level random intercept**************************************************************************.
***************************************************************************************************************************.
** random intercept at level 2 using MIXED, so for continuous outcomes***.
** differences are be estimated.
** assumes intervention is coded 0 and 1.
DEFINE !continu_random_intercept_2level(continu_outcome=!ENCLOSE('(',')')
/level2=!ENCLOSE('(',')') /level1=!ENCLOSE('(',')')
/fixed=!ENCLOSE('(',')')
/cofactors=!DEFAULT('') !ENCLOSE('(',')')   
/covars=!DEFAULT('')  !ENCLOSE('(',')')
/intervention=!DEFAULT('') !ENCLOSE('(',')')
/repeated_measure=!DEFAULT('') !ENCLOSE('(',')')
/dataset=!ENCLOSE('(',')')
                                   )


*** general information on the outcome in this design.
!design_2level
outcome=(!continu_outcome)
level2=(!level2)
intervention=(!intervention)
repeated_measure=(!repeated_measure)
dataset=(!dataset)
.

*** overall distribution of the outcome by intervention group.
!continu_descrip
outcome=(!continu_outcome)
intervention=(!intervention)
.

**********************************************************************.
********* MIXED analysis ***********************************.
DATASET ACTIVATE !dataset.

title !QUOTE(!CONCAT("difference in outcome = ", !continu_outcome)). 
title !QUOTE(!CONCAT("in dataset = ", !dataset)). 

MIXED !continu_outcome WITH !covars BY !level2 !cofactors
   /FIXED= !fixed
  /RANDOM=INTERCEPT | SUBJECT(!level2) COVTYPE(VC)
   /PRINT=SOLUTION TESTCOV
   /SAVE=PRED(pred1) 
.

************* model checking *************************************************.
*aggregating to level 2.
DATASET ACTIVATE !dataset.
DATASET DECLARE aggregated.
AGGREGATE
  /OUTFILE='aggregated'
  /BREAK=!level2 !repeated_measure !intervention
  /aggr_obs=MEAN(!continu_outcome)
  /aggr_pred=MEAN(pred1)
  .
  
DATASET ACTIVATE aggregated.
COMPUTE aggr_resid=aggr_obs - aggr_pred.
* the GPL file needs fixed names for the variables.
COMPUTE level2=!level2.
COMPUTE repeated_measure=!repeated_measure.
COMPUTE intervention=!intervention.
EXECUTE.

*observed profiles after aggregation to level 2, for each level 2 unit.
DATASET ACTIVATE aggregated.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=level2 repeated_measure intervention aggr_obs
    MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=GPLFILE("gpl\aggr_observed_profiles.gpl")
.


* observed vs predicted plot after aggregation to level 2, for each level 2 unit.
DATASET ACTIVATE aggregated.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=level2 repeated_measure intervention aggr_obs aggr_pred
    MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=GPLFILE("gpl\aggr_observed_vs_predicted_profiles.gpl")
.

* residuals vs predicted after aggregation to level 2, for each level 2 unit.
DATASET ACTIVATE aggregated.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=level2 aggr_pred aggr_resid 
    MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=GPLFILE("gpl\aggr_residuals_vs_predicted.gpl")
.

* descriptive statistics on the aggregated residuals (useful to compare models).
    ** suppress the case to variables output.
    OMS
      /SELECT TABLES
      /IF COMMANDS=['Means'] SUBTYPES=['Case Processing Summary']
      /DESTINATION VIEWER=NO
     . 
  
title "spread of the residuals (after aggregating) by level2 unit,".
title " and total (i.e. pooled over all level 2 units): ".
MEANS TABLES=aggr_resid BY level2
    /CELLS=COUNT STDDEV MIN MAX RANGE
.
    OMSEND.  

*clean up.
* 1: delete aggregated dataset.
DATASET ACTIVATE !dataset.
DATASET CLOSE aggregated.
* 2: delete auxiliary variables in main dataset original.
DELETE VARIABLES pred1.

!ENDDEFINE.
.

