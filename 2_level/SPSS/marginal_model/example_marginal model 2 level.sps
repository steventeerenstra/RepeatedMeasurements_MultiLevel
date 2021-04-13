* Encoding: UTF-8.

* voor Steven.
FILE HANDLE gpl /NAME ="C:\Users\st\Desktop\shortcuts\Actief\21 Carmen Siebers\gpl".
FILE HANDLE data /NAME ="C:\Users\st\Desktop\shortcuts\Actief\21 Carmen Siebers".
* voor Carmen: aangeven waar de map gpl staat en de map waarin de dataset staat.
* these references are used in the macros below.  .
FILE HANDLE gpl  /NAME ="....\gpl".
FILE HANDLE data  /NAME ="....".

* Open data and name it 'original' for use in macros later on.
GET FILE="data\DataSet BUST EQ-5D_totaal_long format.sav".
DATASET NAME original.  
EXECUTE.

* read macros to be used in the analysis.
INSERT   FILE= 'gpl\macros.sps'.


* variables below needed to estimate time effects.
COMPUTE T1=0.
If tijdstip=1 T1=1.
COMPUTE T2=0.
If tijdstip=2 T2=1.
COMPUTE T3=0.
If tijdstip=3 T3=1.
EXECUTE.
* make a variable that captures all cases.
COMPUTE all_records=1.
EXECUTE.

* better name.
VARIABLE LABELS    EQ5D_Waarde 'EQ5D'.
VALUE LABELS tijdstip 1 'T1: voor echo/mammo' 2 'T2: na echo/mamo' 3 'T3: na mammo/echo'. 


* make a copy of the main dataset 'original' for a selection.
* name is free to choose.
DATASET COPY biopsie.

* work on the copied dataset.
DATASET ACTIVATE biopsie.
* select.
* we do not use filter options as this interfereces with one of the macros.FILTER OFF.
USE ALL.
SELECT IF (biopsie=1).
EXECUTE.

* choose a dataset to analyse on.
DATASET ACTIVATE original.

* how many measurements.
SORT CASES  BY Conditie Tijdstip EQ5D_Waarde.
SPLIT FILE SEPARATE BY Conditie Tijdstip.

DESCRIPTIVES VARIABLES=EQ5D_Waarde
  /STATISTICS=MEAN STDDEV MIN MAX.

SPLIT FILE OFF.



* spaghetti plot of all patients.
!spagplot_bygroup_continuoustime 
cont_outcome=(EQ5D_Waarde)   repeatedmeasure=(tijdstip) subject=(id) group=(all_records).
* spaghetti plot by biopsie.
!spagplot_bygroup_continuoustime 
cont_outcome=(EQ5D_Waarde)   repeatedmeasure=(tijdstip) subject=(id) group=(biopsie).
* spaghetti plot by interventie.
!spagplot_bygroup_continuoustime 
cont_outcome=(EQ5D_Waarde)   repeatedmeasure=(tijdstip) subject=(id) group=(conditie).



* analysis of only time effect, note that the corrected dataset (select_monocytes1) is mentioned.
!marginal_2level 
cont_outcome=(EQ5D_Waarde) repeatedmeasure=(tijdstip) subject=(ID)   
fixed=(T2 T3 conditie conditie*T2 conditie*T3)  covars=(T2 T3 conditie) cofactors=(tijdstip) 
covtype=(UN) datasetname=(original).


**********************************************************************************************.
** does the fit improve if we look at changes from baseline? **.



*go back to the original dataset.
DATASET ACTIVATE original.

DATASET COPY change.
DATASET ACTIVATE change.

* sort the measurements by id.
SORT CASES  BY id Tijdstip.

* add a baseline measurement.
!add_baseline var=(EQ5D_Waarde) var_base=(EQ5D_baseline) id=(id) repeatedmeasure=(tijdstip) 
first_repeatedmeasure=(1).

* make the change variable.
COMPUTE EQ5D_change=EQ5D_waarde- EQ5D_baseline.
EXECUTE.

* check.
SUMMARIZE
  /TABLES=id tijdstip EQ5D_waarde EQ5D_baseline EQ5D_change
  /FORMAT=VALIDLIST NOCASENUM TOTAL LIMIT=100
  /TITLE='Case Summaries'
  /MISSING=VARIABLE
  /CELLS=COUNT.

* select only the post-baseline measurements, for the change from baseline analyses.
* else distortion by the forced 0 for the baseline measurement.
USE ALL.
SELECT IF (tijdstip > 1) .
EXECUTE.

* all subjects.
!spagplot_bygroup_continuoustime 
cont_outcome=(EQ5D_change)   repeatedmeasure=(tijdstip) subject=(id) group=(all_records).

* by group.
!spagplot_bygroup_continuoustime 
cont_outcome=(EQ5D_change)   repeatedmeasure=(tijdstip) subject=(id) group=(conditie).


* note: better centering around 0 of the residuals.
* so better model.
!marginal_2level 
cont_outcome=(EQ5D_change) repeatedmeasure=(tijdstip) subject=(ID)   
fixed=(conditie T3 T3*conditie)  covars=(T3 conditie) cofactors=(tijdstip) 
covtype=(UN) datasetname=(change)
extra=(/TEST 'difference (exp - ctl) in change from baseline to T2'  conditie 1
           /TEST 'difference (exp - ctl) in change from baseline to T3' conditie 1 T3*conditie 1
           /TEST 'difference in change baseline to T3 vs change baseline to T2 in exp' T3 1 T3*conditie 1
           /TEST 'difference in change baseline to T3 vs change baseline to T2 in ctl' T3 1
           ).
 








