* Encoding: UTF-8.

*** note reference is made to GPL files in the gpl directory.
** so these GPL files must be present in the GPL directory.
** and with a FILE HANDLE that GPL directory path has to be defined in the main program.



DEFINE !describe_repmeas(cont_outcome=!ENCLOSE('(',')')  /repeatedmeasure=!ENCLOSE('(',')') 
                        /subject=!ENCLOSE('(',')') /subject_is_string=!DEFAULT(0) !ENCLOSE('(',')')
                         /group=!ENCLOSE('(',')')  /dataset=!ENCLOSE('(',')')    )

* describe the available measurements with non-missing outcome **.
* and the distribution for subjects and overall of the outcome **.
* option subject_is_string=0 for numerical subject identifier variable.
*       and = < otherwise> for categorical subject indentifier variable.

************ prepare the needed datasets *******************************.
**** make a copy of the db with only cont_outcome.
DATASET ACTIVATE !dataset.
DATASET COPY only_outcome.
* the copy only contains with only the outcome.
* with the relevant variables for the GPL files.
DATASET ACTIVATE only_outcome.
COMPUTE arm=!group.
COMPUTE outcome=!cont_outcome.
COMPUTE repmeas =!repeatedmeasure.
COMPUTE nonmissing=1-MISSING(outcome).
COMPUTE zero=0.
* make a copy of a categorical subject or numeric subject identifier.
    !IF( !subject_is_string <> 0) !THEN 
    STRING subject (A50). 
    !IFEND.
COMPUTE subject=!subject.
EXECUTE.
* set the variable level of the repeated measure to nominal without decimals.
VARIABLE LEVEL repmeas (NOMINAL).
FORMATS    repmeas(f10.0).
* set nonmissing and zero to scale to use it in a high-low plot.
VARIABLE LEVEL  nonmissing zero (SCALE).
* label the outcome with the variable name for the coming output.
VARIABLE LABELS outcome !QUOTE(!cont_outcome).
VARIABLE LABELS arm !QUOTE(!group).
* keep only the desired outcome and the repeated measurement.
*> first sort.
DATASET ACTIVATE only_outcome.
SORT CASES    subject   repmeas.   
* > trick: merge dataset to itself to keep only the desired variables. 
DATASET ACTIVATE only_outcome.
MATCH FILES /FILE=*
  /TABLE='only_outcome'
  /BY subject    repmeas    
  /KEEP=arm subject   repmeas outcome nonmissing zero
.

* make a dataset with only the nonmissing outcomes.
DATASET ACTIVATE only_outcome.
DATASET COPY only_outcome_nonmissing.
DATASET ACTIVATE only_outcome_nonmissing.
SELECT IF nonmissing=1.
EXECUTE.

* make a dataset of summaries of nonmissing outcomes.
DATASET ACTIVATE only_outcome_nonmissing.
DATASET DECLARE subject_summaries.
AGGREGATE
  /OUTFILE='subject_summaries'
  /BREAK=arm subject 
  /last_meas=MAX(repmeas)
  /first_meas=MIN(repmeas)
  /min_outcome=MIN(outcome)
  /max_outcome=MAX(outcome)
  /mean_outcome=MEAN(outcome)
 /median_outcome=MEDIAN(outcome) 
.
DATASET ACTIVATE subject_summaries.
*> calculate follow-up and range based non-missing data. 
COMPUTE fu=last_meas - first_meas.
COMPUTE range_outcome=max_outcome -  min_outcome.
EXECUTE.
* variable labels.
VARIABLE LABELS first_meas !QUOTE(!CONCAT("first non-missing measurement of ",!cont_outcome)). 
VARIABLE LABELS last_meas !QUOTE(!CONCAT("last non-missing measurement of ",!cont_outcome)).
VARIABLE LABELS fu !QUOTE(!CONCAT("follow-up of ",!cont_outcome)).
VARIABLE LABELS range_outcome !QUOTE(!CONCAT("range of ",!cont_outcome)).
VARIABLE LABELS mean_outcome !QUOTE(!CONCAT("average of ",!cont_outcome)).
VARIABLE LABELS median_outcome !QUOTE(!CONCAT("median of ",!cont_outcome)).
EXECUTE.


************** describe available measurements ***********************************************.
* panel plot of the measurements with non-missing outcome by subject in a needle plot.
DATASET ACTIVATE only_outcome_nonmissing.
SORT CASES BY arm.
SPLIT FILE LAYERED BY arm.
title !QUOTE(!CONCAT("outcome is *",!cont_outcome, "*", "; subjects labeled by *",!subject,"*")). 
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=repmeas nonmissing zero subject  
 /GRAPHSPEC  SOURCE=GPLFILE("gpl\panel_needleplot.gpl") 
.
SPLIT FILE OFF.
USE ALL.

* show follow-up and range of outcomes by subject.
* if a grouping variable is given, split the file else not.
DATASET ACTIVATE subject_summaries.
******** describe first non-missing measurement.
GRAPH
  /TITLE 'distribution over the subjects of their first measurement with non-missing outcome'
  /HISTOGRAM=first_meas
  /PANEL ROWVAR=arm ROWOP=CROSS.
MEANS TABLES=first_meas BY arm
  /CELS=COUNT MEAN STDDEV MEDIAN MIN MAX.
****** describe  last non-missing measurement.
GRAPH
  /TITLE 'distribution over the subjects of their last measurement with non-missing outcome'
  /HISTOGRAM=last_meas
  /PANEL ROWVAR=arm ROWOP=CROSS.
MEANS TABLES=last_meas BY arm
  /CELS=COUNT MEAN STDDEV MEDIAN MIN MAX.
*********describe duration of follow-up non-missing measurements. 
GRAPH
  /TITLE 'distribution over the subjects of their follow-up (last-first measurement)'
  /HISTOGRAM=fu
  /PANEL ROWVAR=arm ROWOP=CROSS.
MEANS TABLES=fu BY arm
  /CELS=COUNT MEAN STDDEV MEDIAN MIN MAX.


************** describe distribution of the outcome by subject**********.
DATASET ACTIVATE only_outcome.
SORT CASES BY arm.
SPLIT FILE LAYERED BY arm.
**** panel plot of distribution outcome by subject with a histogram.
title !QUOTE(!CONCAT("outcome is *",!cont_outcome, "*", "; subjects labeled by *",!subject,"*")). 
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=outcome subject
  /GRAPHSPEC SOURCE=GPLFIlE("gpl\panel_histogram.gpl").
***summaries of subjects.
DATASET ACTIVATE subject_summaries.
GRAPH
  /TITLE='distribution over subjects of their average outcome'
  /HISTOGRAM=mean_outcome
  /PANEL ROWVAR=arm ROWOP=CROSS.
MEANS TABLES=mean_outcome BY arm
  /CELS=COUNT MEAN STDDEV MEDIAN MIN MAX.
GRAPH
  /TITLE='distribution over subjects of their median outcome'
  /HISTOGRAM=median_outcome
  /PANEL ROWVAR=arm ROWOP=CROSS.
MEANS TABLES=median_outcome BY arm
  /CELS=COUNT MEAN STDDEV MEDIAN MIN MAX.
GRAPH
  /TITLE='distribution over subjects of their range of outcome'
  /HISTOGRAM=range_outcome
  /PANEL ROWVAR=arm ROWOP=CROSS.
MEANS TABLES=range_outcome BY arm
  /CELS=COUNT MEAN STDDEV MEDIAN MIN MAX.

* describe the distribution over the subjects, including missings.
DATASET ACTIVATE only_outcome.
SPLIT FILE OFF.
*use panel and by options to split by arm.
GRAPH
  /TITLE=!QUOTE(!CONCAT("distribution of all measurements of all subjects of ", !cont_outcome))
  /HISTOGRAM=outcome
  /PANEL ROWVAR=arm ROWOP=CROSS..
MEANS TABLES=outcome BY arm
  /CELS=COUNT MEAN STDDEV MEDIAN MIN MAX.
title !QUOTE(!CONCAT("outcome is *",!cont_outcome,"*")).
EXAMINE VARIABLES=outcome BY arm
  /PLOT NONE
  /PERCENTILES(5,10,25,50,75,90,95) HAVERAGE
  /STATISTICS EXTREME
  /MISSING LISTWISE
  /NOTOTAL.


* clean up.
DATASET ACTIVATE !dataset.
DATASET CLOSE only_outcome.
DATASET CLOSE only_outcome_nonmissing.
DATASET CLOSE subject_summaries.
!ENDDEFINE.






DEFINE   !spagplots_2level(cont_outcome=!ENCLOSE('(',')')   /repeatedmeasure=!ENCLOSE('(',')')  
                         /subject=!ENCLOSE('(',')') /subject_is_string=!DEFAULT(0) !ENCLOSE('(',')') /dataset=!ENCLOSE('(',')')  )


* option subject_is_string=0 for numerical subject identifier variable.
*       and = < otherwise> for categorical subject indentifier variable.
*auxiliary temporary variables for use in GPL files. 
DATASET ACTIVATE !dataset.
COMPUTE cont_outcome=!cont_outcome. 
COMPUTE repeatedmeasure=!repeatedmeasure.
* make a copy of a categorical subject or numeric subject identifier.
    !IF( !subject_is_string <> 0) !THEN 
    STRING subject (A50). 
    !IFEND.
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








*** note the folder gpl that contains the file references to residuals_subject.gpl and linear_profile.gpl have to be specified in the program calling this macro.
DEFINE   !linear_2level(cont_outcome=!ENCLOSE('(',')')   /repeatedmeasure=!ENCLOSE('(',')')  
/subject=!ENCLOSE('(',')') /subject_is_string=!DEFAULT(0) !ENCLOSE('(',')')   
/fixed=!ENCLOSE('(',')') /random=!ENCLOSE('(',')') /covars=!ENCLOSE('(',')') /cofactors=!ENCLOSE('(',')') /covtype=!DEFAULT(UN) !ENCLOSE('(',')')
/save_pred=!DEFAULT('') !ENCLOSE('(',')') /save_resid=!DEFAULT('') !ENCLOSE('(',')')
/dataset=!ENCLOSE('(',')' )   )

** assumes that intervention is randomized at subject-level (level 2) and repeated measurements (level 1) are at repeatedmeasure-level.
** min and max take the range of the vertical axis in the plots of the outcome variable.

title !QUOTE(!CONCAT("continuous outcome is ",!cont_outcome)). 
* first make the levels of the multi level regression nomimal variables.
* define the continuous outcome variable and the repeated measurement variable.
DATASET ACTIVATE !dataset.
COMPUTE cont_outcome=!cont_outcome. 
COMPUTE repeatedmeasure=!repeatedmeasure.
* make a copy of a categorical subject or numeric subject identifier.
    !IF( !subject_is_string <> 0) !THEN 
    STRING subject (A50). 
    !IFEND.
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

* if requested save predicted value. 
!IF( !save_pred <> '') !THEN  
    COMPUTE !save_pred=pred1.
!IFEND.
* if requested save the residual.
!IF( !save_resid <> '') !THEN  
    COMPUTE !save_resid=resid1.
!IFEND.
EXECUTE.

*clean up for new analysis and graphics of other variable.
* delete the variables made in the macro in the original dataset (=main).
DELETE VARIABLES  cont_outcome repeatedmeasure subject cont_outcome_pred zeroline pred1 resid1.

!ENDDEFINE.


