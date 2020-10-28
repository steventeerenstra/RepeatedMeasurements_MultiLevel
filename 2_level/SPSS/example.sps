
* FIRST code that opens a dataset (in long format), eg. GET FILE=....

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
 /GRAPHSPEC SOURCE=GPLFILE("directory\spaghetti_plot.gpl")
 
title !QUOTE(!CONCAT("spaghetti plot for *",!cont_outcome,"* by *",!subject,"*")). 
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=repeatedmeasure cont_outcome subject[LEVEL=NOMINAL] 
 /GRAPHSPEC SOURCE=GPLFILE("directory\panelspaghetti_plot.gpl")
 
*clean up for new analysis and graphics of other variable.
* delete the variables made in the macro in the original dataset (=main).
DELETE VARIABLES   cont_outcome repeatedmeasure subject.
!ENDDEFINE.


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
 /GRAPHSPEC SOURCE=GPLFILE("directory\residuals_subject.gpl")
 .

*** panel plot of observed versus predicted profiles by subject.
COMPUTE cont_outcome_pred=pred1.
EXECUTE.

title !QUOTE(!CONCAT("observed (dots) vs predicted (line) for ",!cont_outcome)). 
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=repeatedmeasure cont_outcome cont_outcome_pred subject[LEVEL=NOMINAL] 
 /GRAPHSPEC SOURCE=GPLFILE("directory\linear_profile.gpl")


*clean up for new analysis and graphics of other variable.
* delete the variables made in the macro in the original dataset (=main).
DELETE VARIABLES   cont_outcome repeatedmeasure pred1 resid1 subject cont_outcome_pred zeroline.

!ENDDEFINE.


* Example: tijd = repeated measure, gh_vas= outcome, studienummer=subject identifier. 

* provide the directory path where the gpl files are stored (these are used in the !spagplots_2level !linear_2level_cont_outcome macros).
FILE HANDLE directory /NAME ="C:\Users\st\Desktop\shortcuts\Actief\20 Julia Weijers".

******** gh_vas ***************************************************************************************.
** show the profiles..
!spagplots_2level cont_outcome=(gh_vas) repeatedmeasure=(tijd) subject=(studienummer).

* fit several models:.

* alleen random intercept model (covtype = ID).
!linear_2level cont_outcome=(gh_vas) repeatedmeasure=(tijd) subject=(studienummer)   
fixed=(tijd) random=(intercept)  covars=(tijd) cofactors=( ) covtype=(ID).

* random intercept en slope, covariance between them DIAG. 
!linear_2level cont_outcome=(gh_vas) repeatedmeasure=(tijd) subject=(studienummer)   
fixed=(tijd) random=(intercept tijd)  covars=(tijd) cofactors=( ) covtype=(DIAG).

* random intercept en slope, with correlation allowed: covtype=UN.
!linear_2level cont_outcome=(gh_vas) repeatedmeasure=(tijd) subject=(studienummer)   
fixed=(tijd) random=(intercept tijd)  covars=(tijd) cofactors=( ) covtype=(UN).


** by defining dummy variables for time etc, also marginal models are possible .
** then only a random effect for subject.









