**** add (intermediate) measurements to a longitudinal dataset (SPSS in this case) 
**** with non-missing covariates but missing outcomes 
**** so that the predicted profiles of each subject can be estimated with high resolution
**** and summary measures can be derived from the profiles of each subject 
**** e.g. where the predicted profile exceeds a threshold
**** e.g. an AUC ****; 

******************* parameters ************************************;
* home directory;
%let dir=C:\Users\st\surfdrive\Actief\2401 AFFECT-2 (Eva Molendijk);
* name of the SPSS dataset to read;
%let long_ds=Database_vertical_CIT CRP Fever.sav;
* name of the SPSS dataset to output;
%let long_ds_replicates=Database_vertical_CIT CRP Fever repl.sav;
* the steps at which the intermediate measurements are added;
* this determines the resolution of the estimated profile;
%let delta=1/24; * one hour precision;
* the outcomes to made missing;
%let list_outcomes=%str(CRP citrulline fever IL1a IL1b);
* subject identifying and repeated measurement identifying variable;
%let subject=participant_id;
%let repmeas=studyday; 

*********** macros ***************************************;
%macro make_missing(varlist=);
%LOCAL i var;
%DO i=1 %TO %sysfunc(countw(&varlist));
	%let var=%TRIM( %SCAN(&varlist,&i) );
	&var=.; 
%END;
%MEND make_missing;


** add the value of the repeated measure when for the first time a criterion is met (hit) 
** and idem for the last time; 
** in a long dataset with a subject identifyer and repeated measure identifier; 
%macro add_firsthit_lasthit(criterion=, first_hit_time=, last_hit_time=,dsin=, dsout=, subject=, repmeas=);
* search the first and last time the criterion is met, called a hit;
proc sort data=&dsin;by &subject &repmeas;run;
data _&dsin._1; set &dsin;
by &subject &repmeas;
retain  _hit _firsthittime _lasthittime;
* before the first measurement of a subject;
* we have not yet a hit ;
if first.&subject then do; _hit=0; _firsthittime=.;_lasthittime=.;end;
* from the first measurement of a subject onwards...;
* ..if we have not already have a hit, i.e. hit=0, we look whether the criterion is met;
* ..if so, we have a hit, hit=1 for all coming measurements;
* ..    and the current measurement gets recorded as the _firstmeas for all subsequent measurements;
* ..    and the last hit is at least the current measurement; 
if _hit=0 and &criterion=1 then do; _hit=1; _firsthittime=&repmeas; _lasthittime=&repmeas; end;
*.. if we have already a hit and we find another hit then last hit time is at least the current measurement;
if _hit=1 and &criterion=1 then do; _lasthittime =&repmeas;end;
run;
*** now add the requested first_hit_time and last_hit_time to all the repeated measurements of a subject;
* (by sorting downwards per subject and then retain);
* in the requested output dataset;
proc sort data=_&dsin._1; by &subject descending &repmeas;run;
data &dsout; set _&dsin._1;
by &subject; retain &first_hit_time &last_hit_time;
if first.&subject then do; &first_hit_time=_firsthittime;&last_hit_time=_lasthittime; end;
drop _firsthittime _lasthittime _hit;
run;
proc sort data=&dsout; by &subject &repmeas;run;
proc delete data=_&dsin._1;run;
%mend add_firsthit_lasthit;

********************************************************************************************;

* import SPSS database;
PROC IMPORT OUT= WORK.source 
            DATAFILE="&dir\&long_ds" 
            DBMS=SPSS REPLACE;
RUN;

* add the first and last measurements with non-missing CRP;
%add_firsthit_lasthit(criterion=%str((CRP ne .)), first_hit_time=first_CRP, last_hit_time=last_CRP,
						dsin=source, dsout=source_crp, subject=participant_id, repmeas=studyday);
* add also the first and last measurements with non-missing citrulline;
%add_firsthit_lasthit(criterion=%str((Citrulline ne .)), first_hit_time=first_citr, last_hit_time=last_citr,
						dsin=source_crp, dsout=source_crp_citr, subject=participant_id, repmeas=studyday);
* possibly also add for other outcomes;

* steps to add the measurements with missing outcome data;
* up to study day 34 now hard coded in the the datastep below;
data source1; set source_crp_citr;
by &subject;
* for each subject;
* for all but the subject's last measurement, output the original outcomes;
if last.&subject=0 then do; replicate=0; output; end; 
* for the subject's last measurement; 
if last.&subject=1 then 
    do; 
	* output the measurement;
	replicate=0; output;
		* and add all measurements in between with missing data;
		do &repmeas=1 to 34 by &delta; 
			replicate=1; %make_missing(varlist=&list_outcomes); output;
		end;     
    end;
* make the measurements in between visible using more decimals;
format studyday 8.2;
run;

proc sort data=source1; by replicate participant_id studyday;run;

** export back to SPSS;
PROC EXPORT DATA= WORK.SOURCE1 
            OUTFILE= "&long_ds_replicates" 
            DBMS=SPSS REPLACE;
RUN;
