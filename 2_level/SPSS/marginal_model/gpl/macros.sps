* Encoding: UTF-8.
****************************************************************************************************************.
************** macros ****************************************************************************************.
****************************************************************************************************************.
**** see https://www.ibm.com/support/knowledgecenter/en/SSLVMB_24.0.0/spss/base/syn_define_arguments.html  for more parameters ***.

*** add_baseline **.
DEFINE !add_baseline( var=!ENCLOSE('(',')')   /var_base=!ENCLOSE('(',')')  /id=!ENCLOSE('(',')')
/repeatedmeasure=!ENCLOSE('(',')') /first_repeatedmeasure=!ENCLOSE('(',')' ) /dataset=!ENCLOSE('(',')') )

* this assumes that !repeatedmeasure is numered sequentially within subject, e.g. 1,2,3,4.
* and that each subject has the baseline at the same time point e.g. 1.
* this could 
* that !basevalue is the value for the baseline, and that values > !baseline correspond with after baseline measruements. 
DATASET ACTIVATE !dataset.
* if not possible to calculate the baseline then put it to missing. 
COMPUTE !var_base=$SYSMIS. 
* sort data.
SORT CASES BY !id(A) !repeatedmeasure(A).
IF !repeatedmeasure = !first_repeatedmeasure !var_base=!var.
EXECUTE.
IF !repeatedmeasure > !first_repeatedmeasure !var_base=LAG(!var_base).
EXECUTE.
!ENDDEFINE.


*** describe for measurement in a grid (all patients are measured at the same times).
DEFINE !describe_repmeas_grid(cont_outcome=!ENCLOSE('(',')')  /repeatedmeasure=!ENCLOSE('(',')') 
                        /min_repeatedmeasurement=!ENCLOSE('(',')') /max_repeatedmeasurement=!ENCLOSE('(',')') 
                        /subject=!ENCLOSE('(',')') /subject_is_string=!DEFAULT(0) !ENCLOSE('(',')')
                         /group=!ENCLOSE('(',')')  /dataset=!ENCLOSE('(',')')    )

* describe the available measurements with non-missing outcome **.
**** measurements are in a grid, i.e., in principle the measurement times are the same for all subjects.
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
* make the new variables now by executing.
EXECUTE.
* set the variable level of the repeated measure to nominal without decimals.
VARIABLE LEVEL repmeas (NOMINAL).
FORMATS    repmeas(f10.0).
* set nonmissing and zero to scale to use it in a high-low plot.
VARIABLE LEVEL  nonmissing zero (SCALE).
* copy the variable labels for the outcome with the variable name for the coming output.
APPLY DICTIONARY  from * /SOURCE VARIABLES = !cont_outcome /TARGET VARIABLES =outcome /VARINFO VARLABEL VALLABELS = REPLACE.
APPLY DICTIONARY  from * /SOURCE VARIABLES = !group /TARGET VARIABLES =arm /VARINFO VARLABEL VALLABELS = REPLACE.

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
  /n_nonmissing_meas=SUM(nonmissing)
  /min_outcome=MIN(outcome)
  /max_outcome=MAX(outcome)
  /mean_outcome=MEAN(outcome)
 /median_outcome=MEDIAN(outcome) 
.

DATASET ACTIVATE subject_summaries.
*> calculate range based non-missing data. 
COMPUTE range_outcome=max_outcome -  min_outcome.
EXECUTE.
* variable labels.
VARIABLE LABELS first_meas !QUOTE(!CONCAT("first non-missing measurement of ",!cont_outcome)). 
VARIABLE LABELS last_meas !QUOTE(!CONCAT("last non-missing measurement of ",!cont_outcome)).
VARIABLE LABELS n_nonmissing_meas !QUOTE(!CONCAT("number non-missing measurements of ",!cont_outcome)).
VARIABLE LABELS range_outcome !QUOTE(!CONCAT("range of ",!cont_outcome)).
VARIABLE LABELS mean_outcome !QUOTE(!CONCAT("average of ",!cont_outcome)).
VARIABLE LABELS median_outcome !QUOTE(!CONCAT("median of ",!cont_outcome)).
EXECUTE.



* make a dataset in wide format for the missing value patterns.
*> first make the copy.
DATASET ACTIVATE only_outcome.
DATASET COPY only_outcome_wide.
*> then make wide on the copy.
DATASET ACTIVATE only_outcome_wide.
SORT CASES BY arm subject repmeas.
* suppress output.
        OMS
          /SELECT TABLES
          /IF COMMANDS=['Cases to Variables'] 
          /DESTINATION VIEWER=NO.
CASESTOVARS
  /ID=arm subject
  /INDEX=repmeas
  /GROUPBY=VARIABLE
  /DROP=nonmissing zero.
        OMSEND.



****************describe the available measurements ********.
** patterns of missing data.
DATASET ACTIVATE only_outcome_wide.
SORT CASES BY arm.
SPLIT FILE LAYERED BY arm.
MULTIPLE IMPUTATION  subject !CONCAT("outcome.", !min_repeatedmeasurement) TO !CONCAT("outcome.",!max_repeatedmeasurement)
   /IMPUTE METHOD=NONE 
   /MISSINGSUMMARIES  PATTERNS .
.
SPLIT FILE OFF.
USE ALL.

DATASET ACTIVATE subject_summaries.
******** describe first non-missing measurement.
GRAPH
  /TITLE 'distribution over the subjects of their first measurement with non-missing outcome'
   /BAR(SIMPLE)=COUNT BY first_meas
    /PANEL ROWVAR=arm.
CROSSTABS
  /TABLES=first_meas BY arm
  /FORMAT=AVALUE TABLES
  /CELLS=COLUMN COUNT
  /COUNT ROUND CELL.
****** describe  last non-missing measurement.
GRAPH
  /TITLE 'distribution over the subjects of their last measurement with non-missing outcome'
  /BAR=COUNT BY last_meas
  /PANEL ROWVAR=arm ROWOP=CROSS.
CROSSTABS
  /TABLES=last_meas BY arm
  /FORMAT=AVALUE TABLES
  /CELLS=COLUMN COUNT
  /COUNT ROUND CELL.
*********describe number of non-missing measurements. 
GRAPH
  /TITLE 'distribution over the subjects of their number of non-missing measurements'
  /BAR=COUNT BY n_nonmissing_meas
  /PANEL ROWVAR=arm ROWOP=CROSS.
CROSSTABS
  /TABLES=n_nonmissing_meas BY arm
  /FORMAT=AVALUE TABLES
  /CELLS=COLUMN COUNT
  /COUNT ROUND CELL.



****************** describe the distribution of the outcome **********************.
***distribution of the outcome by subject**********.
DATASET ACTIVATE only_outcome.
SORT CASES BY arm.
SPLIT FILE LAYERED BY arm.
**** panel plot of distribution outcome by subject with a histogram.
title !QUOTE(!CONCAT("outcome is *",!cont_outcome, "*", "; subjects labeled by *",!subject,"*")). 
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=outcome subject
  /GRAPHSPEC SOURCE=GPLFILE("gpl\panel_histogram_outcome.gpl").
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
DATASET CLOSE only_outcome_wide.
DATASET CLOSE subject_summaries.

!ENDDEFINE.

* note the file references to spaghetti_plot.gpl and panelspaghetti_plot.gpl are in the folder called "directory" that has to be defined with a file handle .
DEFINE   !spagplot_panel(cont_outcome=!ENCLOSE('(',')')   /repeatedmeasure=!ENCLOSE('(',')')  
   /subject=!ENCLOSE('(',')') /subject_is_string=!DEFAULT(0) !ENCLOSE('(', ')')
   /dataset=!ENCLOSE('(',')') 
)  
**** provides a spaghetti plot and a panel plot of invidual profiles of all subjects.
*** time axis can be the same or different for all patients and is taken as continuous. 
DATASET ACTIVATE !dataset. 
*auxiliary temporary variables for use in GPL files. 
COMPUTE outcome_=!cont_outcome. 
COMPUTE repeatedmeasure_=!repeatedmeasure.
    !IF (!subject_is_string <> 0) !THEN 
    string subject_(A50).
    !IFEND.
COMPUTE subject_=!subject.
* first an execute to create the temporary variables. 
EXECUTE.
*  then copy the attributes into these tem variables.
APPLY DICTIONARY  from * /SOURCE VARIABLES = !repeatedmeasure /TARGET VARIABLES =repeatedmeasure_ /VARINFO FORMATS LEVEL VARLABEL.
APPLY DICTIONARY  from * /SOURCE VARIABLES = !subject /TARGET VARIABLES =subject_ /VARINFO FORMATS LEVEL VARLABEL.


title !QUOTE(!CONCAT("spaghetti plot for outcome=[",!cont_outcome,"]")).
title !QUOTE(!CONCAT("repeated measure=[",!repeatedmeasure,"]", "  subject=[", !subject,"]") ). 
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=repeatedmeasure_ outcome_ subject_[LEVEL=NOMINAL] 
 /GRAPHSPEC SOURCE=GPLFILE("gpl\spaghetti_plot.gpl")
 
title !QUOTE(!CONCAT("spaghetti plot for [",!cont_outcome,"] by [",!subject,"]")). 
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=repeatedmeasure_ outcome_ subject_[LEVEL=NOMINAL] 
 /GRAPHSPEC SOURCE=GPLFILE("gpl\panelspaghetti_plot.gpl")
 
*clean up for new analysis and graphics of other variable.
* delete the variables made in the macro in the original dataset (=main).
DELETE VARIABLES   outcome_ repeatedmeasure_ subject_.
!ENDDEFINE.


*********************************************************.


DEFINE   !spagplot_bygroup(cont_outcome=!ENCLOSE('(',')')   /repeatedmeasure=!ENCLOSE('(',')')  
/repeatedmeasure_is_continuous=!DEFAULT(0) !ENCLOSE('(',')')
/subject=!ENCLOSE('(',')') /subject_is_string=!DEFAULT(0) !ENCLOSE('(',')') 
/ group=!ENCLOSE('(',')') 
/dataset=!ENCLOSE('(',')')
)

*** by group: a panel with spaghetti plots and the profile of the means at each repeated neasure.
** repeated measure can be continuous then SPSS GPL  determines the tick marks ***.
***repeated measure can be discrete (e.g. 1,2,3,etc). 
***     then use a good format such FORMATS <var> (f4.0) to avoid decimals ***.

DATASET ACTIVATE !dataset.
*auxiliary variables for use in GPL file.
COMPUTE outcome_=!cont_outcome.
COMPUTE group_=!group.
    !IF( !subject_is_string <> 0) !THEN 
    string subject_ (A50). 
    !IFEND.
COMPUTE subject_=!subject.
COMPUTE repeatedmeasure_=!repeatedmeasure.
EXECUTE.
* first do an EXECUTE to create these auxiliary vars, then copy variable properties into them. 
APPLY DICTIONARY  from * /SOURCE VARIABLES = !group /TARGET VARIABLES =group_ /VARINFO FORMATS LEVEL VARLABEL.   
APPLY DICTIONARY  from * /SOURCE VARIABLES = !repeatedmeasure /TARGET VARIABLES =repeatedmeasure_ /VARINFO FORMATS LEVEL VARLABEL.
APPLY DICTIONARY  from * /SOURCE VARIABLES = !subject /TARGET VARIABLES =subject_ /VARINFO FORMATS LEVEL VARLABEL.
   
title !QUOTE(!CONCAT("spaghetti plot by group=[",!group,"]") ).
title !QUOTE(!CONCAT("for outcome=[",!cont_outcome,"]") ).
title !QUOTE(!CONCAT("repeated measure=[",!repeatedmeasure,"] and", " subject=[", !subject,"]") ). 
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=repeatedmeasure_ outcome_
    subject_ group_ MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=GPLFILE("gpl\groupedspaghetti.gpl").

* clean up auxiliary variables.
DELETE VARIABLES outcome_ group_ subject_ repeatedmeasure_.

!ENDDEFINE.



**** analysis of repeated measures in a grid .
**** (i.e. repeated measure at the same moment for all patients.
DEFINE   !marginal_2level(cont_outcome=!ENCLOSE('(',')')   
/repeatedmeasure=!ENCLOSE('(',')')  
/subject=!ENCLOSE('(',')')  /subject_is_string=!DEFAULT(0) !ENCLOSE('(',')')  
/fixed=!ENCLOSE('(',')') /random=!ENCLOSE('(',')') /covars=!ENCLOSE('(',')') /cofactors=!ENCLOSE('(',')') 
/covtype=!DEFAULT(UN) !ENCLOSE('(',')') /method=!DEFAULT(reml) !ENCLOSE('(',')')
/dataset=!ENCLOSE('(',')')  
/extra=!DEFAULT('') !ENCLOSE('(',')')   )

** needs that repeatedmeasure is a nonnegative integer.
** assumes that intervention is randomized at subject-level (level 2) and repeated measurements (level 1) are at repeatedmeasure-level.
** min and max take the range of the vertical axis in the plots of the outcome variable.
** a generalized linear model is fit, with a covariance structure (which is default unstructured). 
** an additional random effect can be specified.

title !QUOTE(!CONCAT("continuous outcome is ",!cont_outcome)). 

DATASET ACTIVATE !dataset.
******* analyse the continuous outcome variable **********.
MIXED !cont_outcome WITH !covars BY !subject !cofactors
   /FIXED= !fixed
  /REPEATED=!repeatedmeasure | SUBJECT(!subject) COVTYPE(!covtype)
  /METHOD=!method
   /PRINT=SOLUTION R
   /SAVE=PRED(pred_) RESID(resid_)
   !extra
.

* temporary variables for use in the gpl files.
COMPUTE outcome_=!cont_outcome. 
COMPUTE repeatedmeasure_=!repeatedmeasure.
    !IF (!subject_is_string <> 0) !THEN 
    string subject_(A50).
    !IFEND.
COMPUTE subject_=!subject.
COMPUTE zeroline_=0.
EXECUTE.

* note that GPL code blocks cannot be within in macro, so are specified in GPLFIlES: .
* https://www.ibm.com/support/pages/gpl-blocks-will-not-run-my-macro-or-production-job.

************** observed vs predicted plot **********************************.
title !QUOTE(!CONCAT("observed (dots) vs predicted (line) for ",!cont_outcome)). 
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=repeatedmeasure_ outcome_ pred_ subject_[LEVEL=NOMINAL] 
 /GRAPHSPEC SOURCE=GPLFILE("gpl\observed_predicted.gpl")



************* residuals plot (by subjects so different colors per subject) ********************************.
title "residual plot (symmetric around 0?)". 
GGRAPH
 /GRAPHDATASET NAME="graphdataset" VARIABLES=pred_ resid_ subject_ zeroline_ MISSING=LISTWISE 
   REPORTMISSING=NO
 /GRAPHSPEC SOURCE=GPLFILE("gpl\residuals_subject.gpl")
 .

*** histogram of residuals by repeated measure **.
title "histograms of residuals (symmetric around 0?)".
title !QUOTE(!CONCAT("at different repeated measure=[",!repeatedmeasure,"]")).  
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=resid_ repeatedmeasure_ MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=GPLFILE("gpl\panel_histogram_residuals.gpl")
  .

*********** scatterplot of the residuals at different combinations of repeatedmeasures***********.
* make a copy of the daset that can be removed later.
DATASET COPY scatterplot.
DATASET ACTIVATE scatterplot.

* keep only the relevant variables.
MATCH FILES 
/FILE *
/KEEP subject_ repeatedmeasure_ resid_.

* sort the data before aggregating.
SORT CASES  BY subject_ repeatedmeasure_.


* make repeatedmeasure_ nonnegative integer for CASESTOVARS to work.
VARIABLE LEVEL repeatedmeasure_(nominal).
FORMATS repeatedmeasure_(f7.0).

* from long to wide format.
CASESTOVARS
  /ID=subject_
  /INDEX=repeatedmeasure_
  /GROUPBY=VARIABLE.

* to use the 'all' statement first remove the subject index.  
DELETE VARIABLES subject_.

title "scatter plot of residuals".
title !QUOTE(!CONCAT("at different repeated measure=[",!repeatedmeasure,"]")). 
title "cigare around regression line?".
GRAPH
  /SCATTERPLOT(MATRIX)= all 
  /MISSING=LISTWISE.


*clean up for new analysis and graphics of other variable.
* delete the variables made in the macro in the original dataset  !dataset.
DATASET ACTIVATE !dataset.
DELETE VARIABLES   outcome_ repeatedmeasure_ pred_ resid_ subject_  zeroline_.

* activate the main dataset again close the temporary one.
DATASET ACTIVATE !dataset.
DATASET CLOSE scatterplot.

!ENDDEFINE.






 

*** note the file references to residuals_subject.gpl and linear_profile.gpl  are in the folder called "directory" that has to be defined with a file handle .
DEFINE   !linear_2level(cont_outcome=!ENCLOSE('(',')')   /repeatedmeasure=!ENCLOSE('(',')')  /subject=!ENCLOSE('(',')')   
/fixed=!ENCLOSE('(',')') /random=!ENCLOSE('(',')') /covars=!ENCLOSE('(',')') /cofactors=!ENCLOSE('(',')') /covtype=!DEFAULT(UN) !ENCLOSE('(',')') )

** assumes that intervention is randomized at subject-level (level 2) and repeated measurements (level 1) are at repeatedmeasure-level.
** min and max take the range of the vertical axis in the plots of the outcome variable.

title !QUOTE(!CONCAT("continuous outcome is ",!cont_outcome)). 

******* analyse the continuous outcome variable **********.
MIXED !cont_outcome WITH !covars BY !subject !cofactors
   /FIXED= !fixed
  /RANDOM=!random | SUBJECT(!subject) COVTYPE(!covtype)
   /PRINT=SOLUTION TESTCOV
   /SAVE=PRED(pred_) RESID(resid_)
.

************* residuals plot (by subjects so different colors per subject) ********************************.
title !QUOTE(!CONCAT("residual plot for ",!cont_outcome," (symmetric around 0?)")). 
* temporary variables for use in the gpl files.
COMPUTE outcome_=!cont_outcome. 
COMPUTE repeatedmeasure_=!repeatedmeasure.
COMPUTE subject_=!subject.
COMPUTE zeroline_=0.
EXECUTE.
* note that GPL code blocks cannot be within in macro: .
* https://www.ibm.com/support/pages/gpl-blocks-will-not-run-my-macro-or-production-job.
GGRAPH
 /GRAPHDATASET NAME="graphdataset" VARIABLES=pred_ resid_ subject_ zeroline_ MISSING=LISTWISE 
   REPORTMISSING=NO
 /GRAPHSPEC SOURCE=GPLFILE("gpl\residuals_subject.gpl")
 .

title !QUOTE(!CONCAT("observed (dots) vs predicted (line) for ",!cont_outcome)). 
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=repeatedmeasure_ outcome_ pred_ subject_[LEVEL=NOMINAL] 
 /GRAPHSPEC SOURCE=GPLFILE("gpl\observed_predicted.gpl")


*clean up for new analysis and graphics of other variable.
* delete the variables made in the macro in the original dataset (=main).
DELETE VARIABLES   outcome_ repeatedmeasure_ pred_ resid_ subject_  zeroline_.

!ENDDEFINE.



