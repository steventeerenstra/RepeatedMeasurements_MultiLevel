* Encoding: UTF-8.
** based on macroContinuousOutcome180530.sps.



** note: try to find a way to give the file names of the GPL files in syntax instead of in changing it all the time.
** perhaps look at https://stackoverflow.com/questions/14814694/how-can-i-read-in-multiple-excel-files-in-spss-using-a-macro/14817625#14817625. 

** the range on the Y-axis is now subject/cluster  specific and has to be adjusted by adapting in the
* linear_profile.gpl the lines.
*  SCALE: y1 = linear(dim(2), min(0), max(1))
*  SCALE: y2 = linear(dim(2),min(0),max(1))
* open dataset.





**** see https://www.ibm.com/support/knowledgecenter/en/SSLVMB_24.0.0/spss/base/syn_define_arguments.html  for more parameters ***.

DEFINE   !linear_3level(cont_outcome=!ENCLOSE('(',')')   /repeatedmeasure=!ENCLOSE('(',')')  /subject=!ENCLOSE('(',')')  /cluster=!ENCLOSE('(',')') 
/random_cluster=!DEFAULT('INTERCEPT | SUBJECT(temp_cluster) COVTYPE(VC)') !ENCLOSE('(',')')  
/random_subject=!DEFAULT('INTERCEPT | SUBJECT(temp_cluster*temp_subject) COVTYPE(VC)' ) !ENCLOSE('(',')') 
/continuous_vars= !ENCLOSE('(',')') /categorical_vars= !ENCLOSE('(',')')
/clustergroup=!ENCLOSE('(',')')
/fixed=!ENCLOSE('(',')')   
/extra=!DEFAULT('') !ENCLOSE('(',')')   )

** for randomisation at level cluster or level subject.
** plots can be grouped by the variable clustergroup (e.g. intervention when rando at level 2).
** continuous and categorical (apart from cluster and subject variable) have to be given.
** min and max take the range of the vertical axis in the plots of the outcome variable.
** assumes that the cluster, subject and repeated measures is numeric..
**      else declare that these are strings e.g. STRING cluster (A10).

* open dataset: give a name.
DATASET NAME main.


title !QUOTE(!CONCAT("continuous outcome is ",!cont_outcome)). 
* first make the levels of the multi level regression nomimal variables.
* define the continuous outcome variable and the repeated measurement variable.
COMPUTE cont_outcome=!cont_outcome. 
COMPUTE repeatedmeasure=!repeatedmeasure.
COMPUTE temp_cluster=!cluster.
COMPUTE temp_subject=!subject.
EXECUTE.

 
******* analyse the continuous outcome variable **********.
* we make the statements for the MIXED procedure.
!LET !BY_statement=!CONCAT("temp_cluster temp_subject ",!categorical_vars).
* extra sorting variable.

MIXED cont_outcome WITH !continuous_vars BY !BY_statement
   /FIXED= !fixed
   /RANDOM=!random_cluster
   /RANDOM=!random_subject
   /PRINT=SOLUTION 
   /SAVE=PRED(pred1) RESID(resid1)
!extra   
.


**** residuals plot (cluster different colors) ***.
title !QUOTE(!CONCAT("residuals grouped by cluster (=", !cluster, ")  level")). 
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=pred1 resid1 temp_cluster MISSING=LISTWISE 
    REPORTMISSING=NO
  /GRAPHSPEC SOURCE=GPLFILE("J:\OZ-Ouderen-Langdurige-Zorg\OLZ-Stage-Beyond-II\SPSS\Source files\Data management_Lihui Pu\residuals_cluster.gpl")
.

**** residuals plot (subject different colors) ***.
title !QUOTE(!CONCAT("residuals grouped by subject (= ", !subject, ")  level")). 
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=pred1 resid1 temp_subject MISSING=LISTWISE 
    REPORTMISSING=NO
  /GRAPHSPEC SOURCE=GPLFILE("J:\OZ-Ouderen-Langdurige-Zorg\OLZ-Stage-Beyond-II\SPSS\Source files\Data management_Lihui Pu\residuals_subject.gpl")
.


**** observed versus predicted profiles for each cluster the profiles of the *subjects* over time.

* define continuous outcome observed and predicted for subject level.
COMPUTE cont_outcome_obs=cont_outcome.
COMPUTE cont_outcome_pred=pred1.
* variable repeatedmeasure must be nominal for graphs.
VARIABLE LEVEL repeatedmeasure (NOMINAL).

SORT CASES  BY !cluster !clustergroup !subject .
SPLIT FILE LAYERED BY !cluster !clustergroup !subject.
title !QUOTE(!CONCAT("obs. vs pred. profiles of subjects (= ",!subject,").")). 
title !QUOTE(!CONCAT("continuous outcome is ",!cont_outcome)). 
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=repeatedmeasure cont_outcome_obs cont_outcome_pred 
    MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=GPLFILE("J:\OZ-Ouderen-Langdurige-Zorg\OLZ-Stage-Beyond-II\SPSS\Source files\Data management_Lihui Pu\linear_profile.gpl")
.
SPLIT FILE OFF.
* remove these variables as they will be used again in the next step.
DELETE VARIABLES   cont_outcome_obs cont_outcome_pred.



***** observed vs predicted profiles taking averages over level 2 units by level3 unit by the level1 repeated measurements ****.
* note that the time_dummies and intervention can be in the break variables as they are constant by design.
* note that repeatedmeasure is a variable defined in this macro.
DATASET DECLARE aggr_obs_pred.
AGGREGATE
  /OUTFILE=aggr_obs_pred
  /BREAK=!cluster repeatedmeasure  
  /cont_outcome_obs=MEAN(cont_outcome)
  /cont_outcome_pred=MEAN(pred1)
.
DATASET ACTIVATE aggr_obs_pred.
* variable repeatedmeasure must be nominal for graphs.
VARIABLE LEVEL repeatedmeasure (NOMINAL).

SORT CASES  BY !cluster !clustergroup.
SPLIT FILE LAYERED BY !cluster !clustergroup.
title !QUOTE(!CONCAT("obs. vs pred.profiles of clusters (= ",!cluster,").")). 
title !QUOTE(!CONCAT("continuous outcome is ",!cont_outcome)). 
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=repeatedmeasure cont_outcome_obs cont_outcome_pred 
    MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=GPLFILE("J:\OZ-Ouderen-Langdurige-Zorg\OLZ-Stage-Beyond-II\SPSS\Source files\Data management_Lihui Pu\linear_profile.gpl")
.
SPLIT FILE OFF.

*clean up for new analysis and graphics of other variable.
* to remove the aggr_obs_pred dataset, we first need to activate another dataset,els the close will not remove it.
DATASET ACTIVATE main.
DATASET CLOSE aggr_obs_pred.
* delete the variables made in the macro in the original dataset (=main).
DELETE VARIABLES   cont_outcome repeatedmeasure temp_cluster temp_subject pred1 resid1.

!ENDDEFINE.


* rename to variables and make them numeric if needed.
COMPUTE cluster_id=id.

STRING subject_id(a10).
COMPUTE subject_id=IDAA.
ALTER TYPE    subject_id(f10).
descriptives subject_id.
EXECUTE.

COMPUTE meas=Time_measurement_restructured.
EXECUTE.

COMPUTE treatment=Intervention_different_moment.
EXECUTE.

* baseline value add to db.
COMPUTE QUALIDEMTOTALSCORE_base=$sysmis.
IF meas=0 QUALIDEMTOTALSCORE_base=QUALIDEMTOTALSCORE.
IF (meas =1 OR meas=2 OR meas=3) QUALIDEMTOTALSCORE_base=LAG(QUALIDEMTOTALSCORE_base).
EXECUTE.
*check.
SUMMARIZE
  /TABLES=cluster_id subject_id meas QUALIDEMTOTALSCORE_base QUALIDEMTOTALSCORE
  /FORMAT=VALIDLIST NOCASENUM TOTAL LIMIT=150
  /TITLE='Case Summaries'
  /MISSING=VARIABLE
  /CELLS=COUNT.




**** analyses ***.
title "min and max for plots".
DESCRIPTIVES VARIABLES=QUALIDEMTOTALSCORE
  /STATISTICS=MEAN STDDEV MIN MAX.
* can be used to customized the axes in the plots by changing .
*   SCALE: y1 = linear(dim(2), min(0), max(120))
*  SCALE: y2 = linear(dim(2), min(0), max(120))
* in "linear profile.gpl" . 



title "random: cluster>subject> meas".
!linear_3level cont_outcome=(QUALIDEMTOTALSCORE)   repeatedmeasure=(meas)  subject=(subject_id) cluster=(cluster_id) fixed=(QUALIDEMTOTALSCORE_base meas treatment*meas ) continuous_vars=(meas treatment QUALIDEMTOTALSCORE_base ) clustergroup=() .



