* Encoding: UTF-8.
****************************************************************************************************************.
************** macros ****************************************************************************************.
****************************************************************************************************************.
**** see https://www.ibm.com/support/knowledgecenter/en/SSLVMB_24.0.0/spss/base/syn_define_arguments.html  for more parameters ***.

*** add_baseline **.
* this assumes that !repeatedmeasure is nummer sequentially within subject.
* that !basevalue is the value for the baseline, and that values > !baseline correspond with after baseline measruements. 
DEFINE !add_baseline( var=!ENCLOSE('(',')')   /var_base=!ENCLOSE('(',')')  /id=!ENCLOSE('(',')')
/repeatedmeasure=!ENCLOSE('(',')') /first_repeatedmeasure=!ENCLOSE('(',')' ) )
* if not possible to calculate the baseline then put it to missing. 
COMPUTE !var_base=$SYSMIS. 
* sort data.
SORT CASES BY !id(A) !repeatedmeasure(A).
IF !repeatedmeasure = !first_repeatedmeasure !var_base=!var.
EXECUTE.
IF !repeatedmeasure > !first_repeatedmeasure !var_base=LAG(!var_base).
EXECUTE.
!ENDDEFINE.






* note the file references to spaghetti_plot.gpl and panelspaghetti_plot.gpl are in the folder called "directory" that has to be defined with a file handle .
DEFINE   !spagplot(cont_outcome=!ENCLOSE('(',')')   /repeatedmeasure=!ENCLOSE('(',')')  /subject=!ENCLOSE('(',')') )
*auxiliary temporary variables for use in GPL files. 
COMPUTE outcome_=!cont_outcome. 
COMPUTE repeatedmeasure_=!repeatedmeasure.
COMPUTE subject_=!subject.

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

***************************************************************************.
DEFINE   !spagplot_bygroup_continuoustime(cont_outcome=!ENCLOSE('(',')')   /repeatedmeasure=!ENCLOSE('(',')')  
/subject=!ENCLOSE('(',')') / group=!ENCLOSE('(',')') )

*** by group a panel with spaghetti plots and the profile of the means at each repeated neasure.
** repeated measure is here taken as a continuous variable, so no value labels on the horizontal x-axis.

*auxiliary variables for use in GPL file.
COMPUTE outcome_=!cont_outcome.
COMPUTE group_=!group.
COMPUTE subject_=!subject.
COMPUTE repeatedmeasure_=!repeatedmeasure.
EXECUTE.
* first execute to create these auxiliary vars, then copy variable properties into them. 
APPLY DICTIONARY  from * /SOURCE VARIABLES = !group /TARGET VARIABLES =group_ .   
*APPLY DICTIONARY  from * /SOURCE VARIABLES = !repeatedmeasure /TARGET VARIABLES =repeatedmeasure_ .
APPLY DICTIONARY  from * /SOURCE VARIABLES = !subject /TARGET VARIABLES =subject_ .
   
title !QUOTE(!CONCAT("spaghetti plot by group=[",!group,"]") ).
title !QUOTE(!CONCAT("for outcome=[",!cont_outcome,"]") ).
title !QUOTE(!CONCAT("repeated measure=[",!repeatedmeasure,"] and", " subject=[", !subject,"]") ). 
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=repeatedmeasure_ outcome_
    subject_ group_ MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=GPLFILE("gpl\groupedspaghetti_continuoustime.gpl").

* clean up auxiliary variables.
DELETE VARIABLES outcome_ group_ subject_ repeatedmeasure_.

!ENDDEFINE.

 
DEFINE   !spagplot_bygroup_categoricaltime(cont_outcome=!ENCLOSE('(',')')   /repeatedmeasure=!ENCLOSE('(',')')  
/subject=!ENCLOSE('(',')') / group=!ENCLOSE('(',')') )

*** by group a panel with spaghetti plots and the profile of the means at each repeated neasure.
** repeated measure is here taken as a categorical variable, so value labels on the horizontal axis if present.


*auxiliary variables for use in GPL file.
COMPUTE outcome_=!cont_outcome.
COMPUTE group_=!group.
COMPUTE subject_=!subject.
COMPUTE repeatedmeasure_=!repeatedmeasure.
EXECUTE.
* first execute to create these auxiliary vars, then copy variable properties into them. 
APPLY DICTIONARY  from * /SOURCE VARIABLES = !group /TARGET VARIABLES =group_ .   
APPLY DICTIONARY  from * /SOURCE VARIABLES = !repeatedmeasure /TARGET VARIABLES =repeatedmeasure_ .
APPLY DICTIONARY  from * /SOURCE VARIABLES = !subject /TARGET VARIABLES =subject_ .
   
title !QUOTE(!CONCAT("spaghetti plot by group=[",!group,"]") ).
title !QUOTE(!CONCAT("for outcome=[",!cont_outcome,"]") ).
title !QUOTE(!CONCAT("repeated measure=[",!repeatedmeasure,"] and", " subject=[", !subject,"]") ). 
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=repeatedmeasure_ outcome_
    subject_ group_ MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=GPLFILE("gpl\groupedspaghetti_categoricaltime.gpl").

* clean up auxiliary variables.
DELETE VARIABLES outcome_ group_ subject_ repeatedmeasure_.

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



DEFINE   !marginal_2level(cont_outcome=!ENCLOSE('(',')')   /repeatedmeasure=!ENCLOSE('(',')')  /subject=!ENCLOSE('(',')')   
/fixed=!ENCLOSE('(',')') /random=!ENCLOSE('(',')') /covars=!ENCLOSE('(',')') /cofactors=!ENCLOSE('(',')') 
/covtype=!DEFAULT(UN) !ENCLOSE('(',')') /method=!DEFAULT(reml) !ENCLOSE('(',')')
/datasetname=!ENCLOSE('(',')')  
/extra=!DEFAULT('') !ENCLOSE('(',')')   )

** needs that repeatedmeasure is a nonnegative integer.
** assumes that intervention is randomized at subject-level (level 2) and repeated measurements (level 1) are at repeatedmeasure-level.
** min and max take the range of the vertical axis in the plots of the outcome variable.

title !QUOTE(!CONCAT("continuous outcome is ",!cont_outcome)). 

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
COMPUTE subject_=!subject.
COMPUTE zeroline_=0.
EXECUTE.

* note that GPL code blocks cannot be within in macro: .
* https://www.ibm.com/support/pages/gpl-blocks-will-not-run-my-macro-or-production-job.

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
  /GRAPHSPEC SOURCE=GPLFILE("gpl\panel_histogram.gpl")
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

* activate the main dataset again close the temporary one.
DATASET ACTIVATE !datasetname.
DATASET CLOSE scatterplot.

*clean up for new analysis and graphics of other variable.
* delete the variables made in the macro in the original dataset (=main).
DELETE VARIABLES   outcome_ repeatedmeasure_ pred_ resid_ subject_  zeroline_.

!ENDDEFINE.

