**** as the trajectories etc are already investigated *****;
**** we only assess the models fit and provide estimates ***;
%macro sw_cont_infer(ds=ds,outcome=, cluster=cluster, subcluster=subcluster, period=period, trt=trt,
period_min=1,period_max=14,covars_cat=, covars=, interaction=,
dseff=, random_statement=%str(random intercept /subject=&cluster;random intercept /subject=&subcluster(&cluster); ),
repeated_statement=%str( ), estimate_statement=%str( ), contrast_statement=%str( )
);
* to do: ITS analyse by cluster;
* to do: Hooper-Girling, exponential decay model;
* to do: different size for observed vs predicted? GTL scatter plot has an option for that;

*get outcome label;
data _null_; set &ds; call symput('outcome_label', vlabel(&outcome));run;
title3 "analysis   **** &outcome: &outcome_label ****";
title4 "modeling categorical time trend, random effect cluster (Hussey & Hughes)";
* if dseff asked then save effects for &trt and possibly estimate from estimate statement;
%IF &dseff ne %THEN
%DO;
ods output SolutionF=_solutions;
    %IF &estimate_statement ne %THEN ods output Estimates=_estimates;;
    %IF &contrast_statement ne %THEN ods output Contrasts=_contrasts;;
%END;
    * if interaction asked then also make interaction term;
    %local interaction_term; %let interaction_term=;
    %IF &interaction ne %THEN %DO;%let interaction_term=&trt*&interaction; %END;
****** Hussey and Hughes model ****;
proc mixed data=&ds;
class &cluster &subcluster &period &covars_cat ;
model &outcome= &trt &period &covars &interaction_term/ solution cl outpred=_respred ;
&random_statement;;
&repeated_statement;;
&estimate_statement;;
&contrast_statement;;
run;
* process the effects;
%IF &dseff ne %THEN
%DO;
ods output close;
data _solutions;
    length effect $50;length outcome $30;length outcome_label $100;length model $100;
    set _solutions;
    if index(effect,"&trt")>0;
    outcome="&outcome";outcome_label="&outcome_label";
    * get the name of the level of the interaction variable from the format;
    %IF &interaction ne %THEN effect=catx(' : ',effect,&interaction, vvalue(&interaction));;
    model="&trt &period &covars &interaction_term // &random_statement &repeated_statement";
    rename effect=label;
    keep outcome outcome_label effect estimate stderr probt lower upper model ;
    run;
    proc append force base=&dseff data=_solutions ;run;
%IF &estimate_statement ne %THEN %DO;
    data _estimates;
    length label $50;length outcome $30;length outcome_label $100; length model $100;
    set _estimates;
    outcome="&outcome";outcome_label="&outcome_label";
    model="&trt &period &covars &interaction_term // &random_statement &repeated_statement";
    keep outcome outcome_label label estimate stderr probt lower upper model;
    run;
    proc append force base=&dseff data=_estimates;run;
    %END;
%IF &contrast_statement ne %THEN %DO;
    data _contrasts;
    length label $50;length outcome $30;length outcome_label $100; length model $100;
    set _contrasts;
    outcome="&outcome";outcome_label="&outcome_label";
    model="&trt &period &covars &interaction_term // &random_statement &repeated_statement";
    probt=probf; estimate=.;stderr=.;lower=.;upper=.;
    keep outcome outcome_label label estimate stderr probt lower upper model;
    run;
    proc append force base=&dseff data=_contrasts;run;
    %END;
%END;
*** end Hussey & Hughes model**;

title6 "residual plot: all values";
proc sgplot data=_respred; scatter x=pred y=resid ; refline 0/axis=y;run;
title6 "residual plot: by cluster";
proc sgpanel data=_respred; panelby &cluster /onepanel; scatter x=pred y=resid; refline 0 / axis=y;run;
title6 "residual plot: by period";
proc sgpanel data=_respred; panelby &period /onepanel; scatter x=pred y=resid; refline 0 / axis=y;run;
/* too much detail
title6 "residual plot: by cluster-period";
proc sgpanel data=_respred; panelby &cluster &period ; scatter x=pred y=resid; refline 0 / axis=y;run;
*/
* fit, residuals and observed by cluster;
proc means data=_respred noprint; class &cluster &period; id &trt;
output out=_pred1 mean(pred &outcome )=mean_pred mean_obs ;run;
data _pred1; set _pred1; mean_resid=mean_obs-mean_pred;run;
title6 "observed vs predicted plot of clusters: by cluster";
proc sgpanel data=_pred1; panelby &cluster /onepanel;
series x=&period y=mean_pred;
scatter x=&period y=mean_obs;
rowaxis integer;
run;
title6 "residual vs predicted plot of clusters: by cluster";
proc sgpanel data=_pred1; panelby &cluster /onepanel;
scatter x=mean_pred y=mean_resid; refline 0 / axis=y;
run;
title6 "residual vs predicted plot of *all* clusters";
proc sgplot data=_pred1;
scatter x=mean_pred y=mean_resid; refline 0 / axis=y;
run;
%mend sw_cont_infer;


%macro sw_bin_infer(ds=ds, outcome=,cluster=cluster, subcluster=subcluster, period=period, trt=trt,period_min=1, period_max=14,
random_statement=%str( ),repeated_statement=%str( ),
estimate_statement=%str( ), 
contrast_statement=%str( ),dseff=,covars_cat=, covars=, interaction=,
refcat=first
);
** reference category for outcome is &refcat
** works if variable is {0,1} coded;
** error is printed if &outcome is 0 in both arms of is 1 in both arms, but this is handled ;

data &ds; set &ds;
pct_&outcome=100*&outcome;* for calculating percentages via a means-operator;
run;
*get outcome label;
data _null_; set &ds; call symput('outcome_label', vlabel(&outcome));run;

title3 "analysis   **** &outcome: &outcome_label ****";
title4 "percent point difference (linear mixed model)";
* if dseff asked then save effects for &trt and possibly estimate from estimate statement;
%IF &dseff ne %THEN
%DO;
ods output SolutionF=_solutions;
    %IF &estimate_statement ne %THEN ods output Estimates=_estimates;;
    %IF &contrast_statement ne %THEN ods output Contrasts=_contrasts;;
%END;
    * if interaction asked then also make interaction term;
    %local interaction_term; %let interaction_term=;
    %IF &interaction ne %THEN %DO;%let interaction_term=&trt*&interaction; %END;


****** % difference: Hussey and Hughes model ****;
title5 "LMM: model &outcome =&trt  &period &covars &interaction_term; class &cluster &period &covars_cat";
ods output ConvergenceStatus=_converged;*update convergence status;
proc mixed data=&ds;
class &cluster &subcluster &period &covars_cat ;
model pct_&outcome= &trt &period &covars &interaction_term/ solution cl outpred=_respred ;
random intercept / subject=&cluster;
random intercept / subject=&subcluster(&cluster);
&repeated_statement;;
&estimate_statement;;
&contrast_statement;;
run;
ods output close; * close the ods for at least the convergence checking;

* depending on convergence status, status=0 means convergenced, estimates, plots etc are set missing;
* first assume that the model did not convergence;
%local nonconverged; %let nonconverged=1;
* update that after running the model, provided the model was able to run;
data _null_;  call symput('exist', exist("_converged") ); run; 
%IF &exist %THEN %DO; data _null_; set _converged; call symput('nonconverged', status);run;%END;

* process the effects;
%IF &dseff ne %THEN
%DO;
	%IF &nonconverged ne 0 %THEN %DO; 
	data _solutions; length label $50;length outcome $30;length outcome_label $100;length model $100;
	outcome="&outcome"; outcome_label="&outcome_label";label="no &trt (model not converged)"; 
	estimate=.;stderr=.;probt=.;lower=.;upper=.;
	model="LMM: &trt &period &covars &interaction_term | &random_statement &repeated_statement";run;
	%END;
	%IF &nonconverged eq 0 %THEN %DO;
	data _solutions;
    length effect $50;length outcome $30;length outcome_label $100;length model $100;
    set _solutions;
    if index(effect,"&trt")>0;
    outcome="&outcome";outcome_label="&outcome_label";
    * get the name of the level of the interaction variable from the format;
    	%IF &interaction ne %THEN effect=catx(' : ',effect,&interaction, vvalue(&interaction));;
    model="LMM: &trt &period &covars &interaction_term | &random_statement &repeated_statement";
    rename effect=label;
    keep outcome outcome_label effect estimate stderr probt lower upper model ;
    run;
	%END;
    proc append force base=&dseff data=_solutions ;run;
%END;

%IF &estimate_statement ne %THEN 
%DO;
	%IF &nonconverged ne 0 %THEN %DO; 
	data _estimates;length label $50;length outcome $30;length outcome_label $100; length model $100;
	outcome="&outcome"; outcome_label="&outcome_label";label="no estimate (model not converged)"; 
	estimate=.;stderr=.;probt=.;lower=.;upper=.;
	model="LMM: &trt &period &covars &interaction_term | &random_statement &repeated_statement";
	run;
	%END;
	%IF &nonconverged eq 0 %THEN %DO;
	data _estimates;
    length label $50;length outcome $30;length outcome_label $100; length model $100;
    set _estimates;
    outcome="&outcome";outcome_label="&outcome_label";
    model="LMM: &trt &period &covars &interaction_term | &random_statement &repeated_statement";
    keep outcome outcome_label label estimate stderr probt lower upper model;
    run;
    %END;
    proc append force base=&dseff data=_estimates;run;
%END;

%IF &contrast_statement ne %THEN 
%DO;
	%IF &nonconverged ne 0 %THEN %DO; 
	data _contrasts;length label $50;length outcome $30;length outcome_label $100; length model $100;
	outcome="&outcome"; outcome_label="&outcome_label";label="no contrast (model not converged)"; 
	estimate=.;stderr=.;probt=.;lower=.;upper=.;
	model="LMM: &trt &period &covars &interaction_term | &random_statement &repeated_statement";
	run;
	%END;
	%IF &nonconverged eq 0 %THEN %DO;
	data _contrasts;
    length label $50;length outcome $30;length outcome_label $100; length model $100;
    set _contrasts;
    outcome="&outcome";outcome_label="&outcome_label";
    model="LMM: &trt &period &covars &interaction_term // &random_statement &repeated_statement";
    probt=probf; estimate=.;stderr=.;lower=.;upper=.;
    keep outcome outcome_label label estimate stderr probt lower upper model;
    run;
	%END;
    proc append force base=&dseff data=_contrasts;run;
%END;


* only if model converged, provide plots;
%IF &nonconverged eq 0 %THEN %DO;
title6 "residual plot: all values";
proc sgplot data=_respred; scatter x=pred y=resid ; refline 0/axis=y;run;
title6 "residual plot: by cluster";
proc sgpanel data=_respred; panelby &cluster /onepanel; scatter x=pred y=resid; refline 0 / axis=y;run;
title6 "residual plot: by period";
proc sgpanel data=_respred; panelby &period /onepanel; scatter x=pred y=resid; refline 0 / axis=y;run;

* calculate residuals, observed and fitted for cluster x time averages;
proc means data=_respred noprint; class &cluster &period; id &trt;
output out=_pred1 mean(pred pct_&outcome)=mean_pred mean_obs;run;
data _pred1; set _pred1; mean_resid=mean_obs-mean_pred;run;
title6 "observed vs predicted plot of clusters: by cluster";
proc sgpanel data=_pred1; panelby &cluster /onepanel;
series x=&period y=mean_pred;
scatter x=&period y=mean_obs;
rowaxis integer;
run;
title6 "residual vs predicted plot of clusters: by cluster";
proc sgpanel data=_pred1; panelby &cluster /onepanel;
scatter x=mean_pred y=mean_resid; refline 0 / axis=y;
run;
title6 "residual vs predicted plot of *all* clusters";
proc sgplot data=_pred1;
scatter x=mean_pred y=mean_resid; refline 0 / axis=y;
run;
%END;
*** end % difference: Hussey & Hughes model**;

title4 "** odds ratio ** (generalized linear mixed model)";
* first remove the convergence status from the previous model;
proc delete data=_converged; run;

%IF &dseff ne %THEN
%DO;
ods output ParameterEstimates=_solutions;
    %IF &estimate_statement ne %THEN ods output Estimates=_estimates;;
    %IF &contrast_statement ne %THEN ods output Contrasts=_contrasts;;
%END;
    * if interaction asked then also make interaction term;
    %local interaction_term; %let interaction_term=;
    %IF &interaction ne %THEN %DO;%let interaction_term=&trt*&interaction; %END;
*model;
title5 "GLMM: model &outcome(reference=&refcat)=&trt  &period &covars &interaction_term; class &cluster &period &covars_cat";
ods output ConvergenceStatus=_converged;*check on convergence status;
proc glimmix data=&ds;
class &cluster &subcluster &period &covars_cat;
model &outcome(reference=first)=&trt  &period &covars &interaction_term
/solution cl distribution=binary oddsratio; *&period &covars oddsratio;
random intercept / subject=&cluster;
random intercept / subject=&subcluster(&cluster);
&estimate_statement;;
&contrast_statement;;
output out=_respred pred=lp;
run;
ods output close; * close at least convergence checking;

* depending on convergence status, status=0 means convergenced, estimates, plots etc are set missing;
* assume first the model did not converge;
%let nonconverged=1;
* update that after running the model, provided the model was able to run;
data _null_;  call symput('exist', exist("_converged") ); run; 
%IF &exist %THEN %DO; data _null_; set _converged; call symput('nonconverged', status);run;%END;

* process the effects;
%IF &dseff ne %THEN
%DO;
	%IF &nonconverged ne 0 %THEN %DO; 
	data _solutions;length label $50;length outcome $30;length outcome_label $100;length model $100;
	outcome="&outcome"; outcome_label="log(odds) &outcome_label";label="no &trt (model not converged)"; 
	estimate=.;stderr=.;probt=.;lower=.;upper=.;
	model="GLMM: &trt &period &covars &interaction_term | &random_statement ";run;
	%END;
	%IF &nonconverged eq 0 %THEN %DO; 
	data _solutions;
    length effect $50;length outcome $30;length outcome_label $100;length model $100;
    set _solutions;
    if index(effect,"&trt")>0;
    outcome="&outcome";outcome_label="log(odds) &outcome_label";
    * get the name of the level of the interaction variable from the format;
    	%IF &interaction ne %THEN effect=catx(' : ',effect,&interaction, vvalue(&interaction));;
    model="GLMM: &trt &period &covars &interaction_term | &random_statement ";
    rename effect=label;
    keep outcome outcome_label effect estimate stderr probt lower upper model ;
    run;
	%END;
    proc append force base=&dseff data=_solutions ;run;
%END;

%IF &estimate_statement ne %THEN 
%DO;
	%IF &nonconverged ne 0 %THEN %DO; 
	data _estimates;length label $50;length outcome $30;length outcome_label $100; length model $100;
	outcome="&outcome"; outcome_label="log(odds) &outcome_label";label="no estimate (model not converged)"; 
	estimate=.;stderr=.;probt=.;lower=.;upper=.;
	model="GLMM: &trt &period &covars &interaction_term | &random_statement ";run;
	%END;  
	%IF &nonconverged eq 0 %THEN %DO; 
	data _estimates;
    length label $50;length outcome $30;length outcome_label $100; length model $100;
    set _estimates;
    outcome="&outcome";outcome_label="log(odds) &outcome_label";
    model="GLMM: &trt &period &covars &interaction_term | &random_statement ";
    keep outcome outcome_label label estimate stderr probt lower upper model;
    run;
	%END;
    proc append force base=&dseff data=_estimates;run;
%END;

%IF &contrast_statement ne %THEN %DO;
	%IF &nonconverged ne 0 %THEN %DO; 
	data _contrasts;length label $50;length outcome $30;length outcome_label $100; length model $100;
	outcome="&outcome"; outcome_label="log(odds) &outcome_label";label="no contrast (model not converged)"; 
	estimate=.;stderr=.;probt=.;lower=.;upper=.;run;
	model="GLMM: &trt &period &covars &interaction_term | &random_statement ";run;
	%END;
	%IF &nonconverged eq 0 %THEN %DO;
	data _contrasts;
    length label $50;length outcome $30;length outcome_label $100; length model $100;
    set _contrasts;
    outcome="&outcome";outcome_label="log(odds) &outcome_label";
    model="GLMM: &trt &period &covars &interaction_term // &random_statement &repeated_statement";
    probt=probf; estimate=.;stderr=.;lower=.;upper=.;
    keep outcome outcome_label label estimate stderr probt lower upper model;
    run;
	%END;
    proc append force base=&dseff data=_contrasts;run;
%END;
*** end odds ratio**;

* only if model converged, provide plots;
%IF &nonconverged eq 0 %THEN %DO;
title6 "observed vs predicted plot: by cluster";
* calculate residuals, observed and fitted for cluster x time averages;
data _respred; set _respred; pred_percent=100*exp(lp)/(1+exp(lp)); run;
proc means data=_respred noprint; class &cluster &period;
output out=_pred1 mean(pred_percent pct_&outcome)=mean_pred mean_obs;run;
data _pred1; set _pred1; mean_resid=mean_obs-mean_pred;run;
title6 "observed vs predicted plot of clusters: by cluster";
proc sgpanel data=_pred1; panelby &cluster /onepanel;
series x=&period y=mean_pred;
scatter x=&period y=mean_obs;
rowaxis integer;
run;
title6 "residual vs predicted plot of clusters: by cluster";
proc sgpanel data=_pred1; panelby &cluster /onepanel;
scatter x=mean_pred y=mean_resid; refline 0 / axis=y;
run;
title6 "residual vs predicted plot of *all* clusters";
proc sgplot data=_pred1;
scatter x=mean_pred y=mean_resid; refline 0 / axis=y;
run;
%END;
%mend sw_bin_infer;

* per moment versies van een variabele maken;
%macro makebymoment(var=);
%do i=1 %to 5;
* for moment &i make the variable that takes the value of that variable only at moment &i;
if M&i=1 then &var._M&i= &var;
else &var._M&i =.;
%end;
%mend makebymoment;


********* READ 	DATA *******;
options pagesize=60;
libname dir ".";
* get formats;
options fmtsearch= (dir.formats);
* show variables in dataset;
title6 "variables in ruwe dataset";
proc contents data=dir.change varnum;run;

* show format, look up name of format in the formatslibrary;
/* 1‚Helpende; 2‚Leerling verpleegkundige, 3‚Overig, 4‚Serviceassistent,
5‚Verpleegkundige, 6‚Verzorgende */ 
proc format lib=dir.formats fmtlib;
   select BEROEPS; 
run;
/* show format id_afde*/
proc format lib=dir.formats fmtlib;
  select ID_AFDE;
run;


* show format, look up name of format in the formatslibrary;
/* 1‚Helpende; 2‚Leerling verpleegkundige, 3‚Overig, 4‚Serviceassistent,
5‚Verpleegkundige, 6‚Verzorgende */ 
proc format lib=dir.formats fmtlib;
   select BEROEPS; 
run;
/* show format id_afde*/
proc format lib=dir.formats fmtlib;
  select ID_AFDE;
run;



proc format; 
value beroep 1="verpleegkundige+verzorgende"
                          2="helpende+serviceassistent"
						  3="lerende"
;
value lerende 0="niet-leerling"
			  1="leerling"	
;
value type 1="revalidatie"
           2="psy.geriatrisch"
		   3="somatisch"
;
value num 0="0=nee"
		  1="1=ja"
;
run; 

   
* get dataset;
* define variables;
data ds; set dir.change; 
* moment van handhygiene;
M1=Voorpatientcontact; label M1="M1: voor patientcontact";
M2=Vooraseptischehandeling;label M2="M2: voor aseptische beh.";
M3=Nacontactlichaamsvloeistoffen;label M3="M3: na contact lich.vloeistof";
M4=Napatientcontact;label M4="M4: na patientcontact";
M5=Nacontactomgevingpatient;label M5="M5: na contact omgev.pat.";
* levels;
cluster=id_verpleeghuis;
subcluster=id_afdeling;
period = meting;
* intervention;
trt= (meting >= tijdstipinterventie); 
********;
*0-1 format instead of "ja/nee";
format HH_uitgev_gecorr_asep num.;
format HH_uitgevoerd_M1 num.;format HH_uitgevoerd_M2 num.;
format HH_uitgevoerd_M3 num.;format HH_uitgevoerd_M4 num.;
format HH_uitgevoerd_M5 num.;
* derived outcomes;
* over alle metingen heen;
if HH_uitgev_gecorr_asep=1 and handenwassen=1 then HH_asep_wassen=1; else  HH_asep_wassen=0;
if HH_uitgev_gecorr_asep=1 and Handdesinfectie=1 then HH_asep_desinfec=1; else  HH_asep_desinfec=0;
if HH_uitgev_gecorr_asep=1 and Handschoenen=1 then HH_asep_handschoen=1; else  HH_asep_handschoen=0;
*	handenschoen gecombineerd met ofwel handenwasen ofwel handdesinfectie ;
if HH_uitgev_gecorr_asep=1 and Handschoenen=1 and handenwassen=1 then HH_asep_hschoen_wassen=1; else  HH_asep_hschoen_wassen=0;
if HH_uitgev_gecorr_asep=1 and Handschoenen=1 and Handdesinfectie=1 then HH_asep_hschoen_des=1; else  HH_asep_hschoen_des=0;
* per meting
*     n.b. geteld alleen binnen de observaties waarvoor dat hygiene moment geindiceerd was;
%makebymoment(var=HH_asep_desinfec);
%makebymoment(var=HH_asep_wassen);
%makebymoment(var=HH_asep_handschoen);
%makebymoment(var=HH_asep_hschoen_wassen);
%makebymoment(var=HH_asep_hschoen_des);
* gecorrigeerde HH_uitgev_gecorr_asep alleen op M2  ;
if M2=1 then HH_uitgev_gecorr_asep_M2=HH_uitgev_gecorr_asep; else HH_uitgev_gecorr_asep_M2=.;
*********;
* subgroepen;
* lerende vs rest;
if beroepssubgroep_num ne . then lerende= (beroepssubgroep_num=2);
label lerende='leerling verpleegkundige';
format lerende lerende.;
* verpleegkundige+verzorgende, helpende+serviceassistent, lerende (overige weg);
if beroepssubgroep_num ne 3 then do;
if beroepssubgroep_num in (5,6) then beroep=1;
else if beroepssubgroep_num in (1,4) then beroep=2;
else if beroepssubgroep_num in (2) then beroep=3;
end;
format beroep beroep.;
label beroep='opleiding (1=vpk/vz,2=hlp/srv,3=ll)';
* type afdeling;
	* "VA1", "VA2", "VA3","VD2", "VE", "VH": revalidation;
if id_afdeling in (1, 2,3,8,9,12) then type_afd=1;
	* "VB","VC1","VF", "VG", "VI3", "VJ1", "VK", "VM1", "VM3": pg;
else if id_afdeling in (4,5,10,11,15, 17, 19,21,23) then type_afd=2;
	* "VC2","VD1", "VI1", "VJ2","VL", "VN1", "VN2", "VN3": som;
else if id_afdeling in (6,7,13,18,20,25,26,27) then type_afd=3;
format type_afd type.;
label type_afd='type afdeling (1=rev,2=pg,3=som)';
* implementatiescores;
Know_mean=KL_ProvideGeneralInformation; label know_mean="knowledge";
label AW_mean="awareness";
label SI_mean="socal influence";
label AT_mean="attitude";
label SE_mean="self-efficacy";
label IN_mean="intention";
label AC_UseCues="action control / use cues";
label MT_FormulateGoalsForMaintenance="(formulate goals for) maintenance";
label LS_mean="leadership";
label Total_sum="total";
run;


******************* STATISTICAL ANALYSIS *****************;

**********************************************************;
************* ITT ANALYSES *******************************;
**********************************************************;

* interaction analysis for a given outcome variable over a list of interaction variables;
%macro InteractionByVarlist(InteractionVarList=, outcome=); 
%local dseff; %let dseff=table_&outcome; *name of table to store results;
%local i;  * must be local to avoid clash with other (nested macros using same i);
%let i=0;
%do %while(%scan(&InteractionVarlist,&i+1,%str( )) ne %str( ));     
	%let i = %eval(&i+1);    
	%let interaction = %scan(&InteractionVarList,&i,%str( ));     
	** part to repeat over varlist***;
	* get label;
	data _null_; set ds; call symput('interaction_label', vlabel(&interaction));run;
	title2 "interaction of treatment with &interaction_label";
	* analyze;
	%sw_bin_infer(outcome=&outcome, covars=trt*&interaction, period_min=0, period_max=4,dseff=&dseff);
%end; 
%mend InteractionByVarlist;

* repeat InteractionAnalysis for several outcome variables;
%macro OutcomesOfVarlist(OutcomeVarList=,InteractionVarList=);
%local i;  * must be local to avoid clash with other (nested macros using same i);
%let i=0;
%do %while(%scan(&OutcomeVarList,&i+1,%str( )) ne %str( ) );
	%let i=%eval(&i+1);
	%let outcome=%scan(&OutcomeVarList,&i,%str( ));
	*part to repeat over varlist**;
	%InteractionByVarlist(InteractionVarList=&InteractionVarList, outcome=&outcome);
%end;
%mend OutcomesOfVarlist;

* make a print with the Output table for each Outcome variable;
%macro OutputOfVarlist(OutcomeVarList=);
%local i;* must be local to avoid clash with other (nested macros using same i);
%let i=0;
%do %while( %scan(&OutcomeVarList,&i+1,%str( )) ne %str( ));
	%let i=%eval(&i+1);
	%let outcome=%scan(&OutcomeVarList,&i,%str( ));
	title2 "outcome: &outcome";
	data table_exp; set table_&outcome; 
		*add the exponentiated estimates and 95%-CI for log transformed variables;
		if index(outcome_label,'log')>0 then do; 
		e_est=exp(estimate);e_lower=exp(lower); e_upper=exp(upper);end;
		if index(label, 'trt') >0 ; * only the treatment and interaction by treatment estimates;
		if index(label, 'trt*') >0 and (Probt < 0.05) then mark="*"; else mark=" ";* mark the stat.sign. interactions;
	run;
	proc print data=table_exp noobs; 
	var outcome_label label estimate lower upper probt e_est e_lower e_upper mark; 
	run;	
%end;
%mend OutputOfVarlist;

* list of interaction variables;
	*%let InteractionVarlist=%str(total_sum know_mean);
%let InteractionVarlist=%str(total_sum know_mean aw_mean si_mean at_mean se_mean in_mean ac_usecues mt_formulateGoalsForMaintenance ls_mean);
* list of outcome variables;
%let OutcomeVarList=%str(HH_uitgev_gecorr_asep hh_asep_wassen HH_asep_desinfec HH_asep_handschoen); 
 * %let OutcomeVarList=%str(HH_uitgev_gecorr_asep hh_asep_wassen);

*options symbolgen mlogic mprint;

ods pdf file="200731_output.pdf" compress=9;
%OutcomesOfVarlist(OutcomeVarList=&OutcomeVarList,InteractionVarList=&InteractionVarList);
ods pdf close;

options orientation=landscape;
ods rtf file="200731_table.doc" style=minimal;
%OutputOfVarlist(OutcomeVarList=&OutcomeVarList);
ods rtf close;

