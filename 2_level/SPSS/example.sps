* Encoding: UTF-8.
* requires a dataset in long format to be open.

**** see https://www.ibm.com/support/knowledgecenter/en/SSLVMB_24.0.0/spss/base/syn_define_arguments.html  for more parameters ***.
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
 /GRAPHSPEC SOURCE=GPLFILE("C:\Users\st\Desktop\20 Julia Weijers\residuals_subject.gpl")
 .

*** panel plot of observed versus predicted profiles by subject.
COMPUTE cont_outcome_pred=pred1.
EXECUTE.

title !QUOTE(!CONCAT("observed (dots) vs predicted (line) for ",!cont_outcome)). 
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=repeatedmeasure cont_outcome cont_outcome_pred subject[LEVEL=NOMINAL] 
 /GRAPHSPEC SOURCE=GPLFILE("C:\Users\st\Desktop\20 Julia Weijers\linear_profile.gpl")


*clean up for new analysis and graphics of other variable.
* delete the variables made in the macro in the original dataset (=main).
DELETE VARIABLES   cont_outcome repeatedmeasure pred1 resid1 subject cont_outcome_pred zeroline.

!ENDDEFINE.


* Example: tijd = repeated measure, gh_vas= outcome, studienummer=subject identifier. 

******** gh_vas ***************************************************************************************.
** show the profiles..
title "all profiles in one".
DATASET ACTIVATE DataSet1.
* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=tijd gh_vas Studienummer[LEVEL=NOMINAL] 
    MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: tijd=col(source(s), name("tijd"))
  DATA: gh_vas=col(source(s), name("gh_vas"))
  DATA: Studienummer=col(source(s), name("Studienummer"), unit.category())
  GUIDE: axis(dim(1), label("tijd"))
  GUIDE: axis(dim(2), label("vas general health"))
  GUIDE: legend(aesthetic(aesthetic.color.interior), label("Studienummer"))
  GUIDE: text.title(label("Multiple Line of vas general health at T0 by tijd by Studienummer"))
  ELEMENT: line(position(tijd*gh_vas), color.interior(Studienummer), missing.wings(),transparency(transparency."0.5"))
END GPL.

title "profile per subject".
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=tijd gh_vas Studienummer[LEVEL=NOMINAL] 
  /GRAPHSPEC SOURCE=INLINE.
BEGIN GPL
  PAGE: begin(scale(1000px,1000px))
  SOURCE: s=userSource(id("graphdataset"))
  DATA: tijd=col(source(s), name("tijd"))
  DATA: gh_vas=col(source(s), name("gh_vas"))
  DATA: Studienummer=col(source(s), name("Studienummer"), unit.category())
  COORD: rect(dim(1,2), wrap())
  GUIDE: axis(dim(1) )
  GUIDE: axis(dim(2))
  GUIDE: axis(dim(3), opposite())
  SCALE: linear(dim(1))
  ELEMENT: point(position(tijd*gh_vas*Studienummer))
  ELEMENT: line(position(tijd*gh_vas*Studienummer))
  PAGE: end()
END GPL.

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









