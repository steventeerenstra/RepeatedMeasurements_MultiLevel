* Encoding: UTF-8.

* macro below fits a 3 level model (cluster > subject > repeate measurement) and makes plots to assess fit.

DEFINE   !linear_3level(continu_outcome=!ENCLOSE('(',')')   
/repeatedmeasure=!ENCLOSE('(',')')  /subject=!ENCLOSE('(',')')  /cluster=!ENCLOSE('(',')')
/randomeffects_subject=!DEFAULT(INTERCEPT) !ENCLOSE('(',')') /covtype_subject=!DEFAULT(ID) !ENCLOSE('(',')') 
/randomeffects_cluster=!DEFAULT(INTERCEPT) !ENCLOSE('(',')') /covtype_cluster=!DEFAULT(ID) !ENCLOSE('(',')') 
/covars=!DEFAULT('') !ENCLOSE('(',')') /cofactors=!DEFAULT('') !ENCLOSE('(',')') 
/fixed=!ENCLOSE('(',')')
/extra=!DEFAULT('') !ENCLOSE('(',')')  
)
** assumes that intervention is randomized at subject-level (level 2) and repeated measurements (level 1) are at repeatedmeasure-level.
** min and max take the range of the vertical axis in the plots of the outcome variable.

title !QUOTE(!CONCAT("continuous outcome = ",!continu_outcome)). 
title !QUOTE(!CONCAT("cluster (highest level) =", !cluster)).
title !QUOTE(!CONCAT("subject (middle level) = ", !subject)). 
title !QUOTE(!CONCAT("repeated measure (lowest level) = ", !repeatedmeasure)).

******************************************************************.
******* analyse the continuous outcome variable **********.
******************************************************************.
MIXED !continu_outcome WITH !covars BY !cluster !subject !cofactors
  /FIXED= !fixed
  /RANDOM=!randomeffects_cluster | SUBJECT(!cluster) COVTYPE(!covtype_cluster)
  /RANDOM=!randomeffects_subject | SUBJECT(!subject*!cluster) COVTYPE(!covtype_subject)
  /PRINT=SOLUTION TESTCOV
  /SAVE=PRED(pred_) RESID(resid_)
   !extra
.

******************************************************************.
****** graphs for model checking *************************.
******************************************************************.
* note that GPL 'inline' code blocks cannot be within in macro: .
* https://www.ibm.com/support/pages/gpl-blocks-will-not-run-my-macro-or-production-job.

* therefore fixed name for variables used in the graphs. 
COMPUTE continu_outcome_=!continu_outcome.
COMPUTE cluster_=!cluster. 
COMPUTE subject_=!subject. 
COMPUTE rep_meas_=!repeatedmeasure. 
EXECUTE.

***.
title "** in the graphs below the following notation is used ***".
title !QUOTE(!CONCAT("cluster = ", !cluster)).
title !QUOTE(!CONCAT("repeated measure = ",!repeatedmeasure)).
****residuals vs predicted by cluster.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" 
     VARIABLES=pred_ resid_ cluster_[LEVEL=NOMINAL] 
  /GRAPHSPEC SOURCE=GPLFILE("gpl\residuals_cluster_3level.gpl")
 .

*** residuals vs predicted by cluster x repeated measure.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" 
     VARIABLES=pred_ resid_ rep_meas_[LEVEL=NOMINAL]  cluster_[LEVEL=NOMINAL] 
  /GRAPHSPEC SOURCE=GPLFILE("gpl\residuals_cluster_repmeas_3level.gpl")
 .

***** observed vs predicted profiles taking averages over level 2 units by level3 unit by the level1 repeated measurements ****.
* make aggregated data first.
DATASET ACTIVATE    original.
DATASET DECLARE aggregated.
AGGREGATE
  /OUTFILE=aggregated
  /BREAK=cluster_ rep_meas_  
  /aggr_obs=MEAN(continu_outcome_)
  /aggr_pred=MEAN(pred_)
.

*then do the plot.
*see https://andrewpwheeler.com/2016/08/12/plotting-panel-data-with-many-lines-in-spss/.
DATASET ACTIVATE aggregated.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" 
      VARIABLES=aggr_obs aggr_pred cluster_[LEVEL=NOMINAL]  rep_meas_[LEVEL=NOMINAL]  
  /GRAPHSPEC SOURCE=GPLFILE("gpl/obs_vs_pred_bycluster_3level.gpl")
 .
 
* then remove the aggr_obs_pred dataset, we first need to activate another dataset,else the close will not remove it.
DATASET ACTIVATE original.
DATASET CLOSE aggregated.

*****************************************************.
* clean up for another analysis.
DELETE VARIABLES pred_ resid_ continu_outcome_ cluster_ subject_ rep_meas_.
*****************************************************.
!ENDDEFINE.

