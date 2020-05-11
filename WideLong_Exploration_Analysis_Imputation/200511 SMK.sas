* let even op dat je de quantilen op de unieke records bepaald, niet de herhaalde metingen doet;

****** MACROS ************************************;

%macro categorize(ds=,var=,percentile_list=%str(20 40 60 80),class_var=);
** categorize a continuous variable into classes based on given percentiles;

* calculate the percentiles for the given percentages;
proc univariate noprint data=&ds;
  var &var;
  output out=_percsplit pctlpts=&percentile_list pctlpre=pct;
run;

* format classes from a dataset;
* needed vars: fmtname, start (left side of the =), label (right of the =);
data format;set _percsplit;
retain fmtname "fmt_&var";
array percentile pct: ;
do start=1 to dim(percentile);
	if start=1 then label=catx('<', '..', put(percentile{start},5.2));* put(..,5.2) to get 2 decimals;
	if start ne 1 then label=catx('-', put(percentile{start-1},5.2), put(percentile{start},5.2));
	output;
end;
label=put(percentile{dim(percentile)},5.2)||">..";output; * last range;
drop pct: ;
run;
proc format cntlin=format;run;

* add the cutpoints create the new variable in the main dataset;
data &ds; 
if _n_=1 then set _percsplit; set &ds; * add the cutpoints to the dataset;
array percentile pct: ; * an array with percentiles;
* calculate the class number; 
if &var ne . then do; 
	&class_var=1; 
	do i=1 to dim(percentile); if &var > percentile{i} then &class_var=&class_var+1; end;
end;
label &class_var="class &var";
format &class_var fmt_&var..;
* drop the percentiles;
drop i ;drop pct:;
run;

%mend categorize;


%macro missing_indicators(ds=, vars=%str(coronaal transversaal_tibia) );
%local var;
data &ds; set &ds;
%do i=1 %to %sysfunc(countw(&vars));
	%let var=%scan(&vars, &i);
	miss_&var=missing(&var);
%end;
run;
%mend; 




***** DATA ****************************************;

* relative folder naming; 
libname here ".";
libname data "../Data";

	/* proc contents data=data.raw;run; */
	/* proc print data=data.raw;
	*var KSS_functie KISS_functie_12mnd KISS_functie_24mnd KISS_functie_60mnd; 
	run;*/

* correcties transversaal femur Simon van Laarhoven, mail 2020/03/23;
data corr; set data.correcties;run;
data raw(drop=transversaal_femur transversaal_tibia); set data.raw;run;

proc sort data=raw; by pp;run;
proc sort data=corr; by pp;run;

data knee; merge raw corr; by pp;run;
	/* proc print data=knee noobs; var pp transversaal_femur transversaal_tibia;run;*/

* add analysis variable (for imputation);
data knee; set knee;
transversaal_tibia_sq=Transversaal_tibia*Transversaal_tibia;
coronaal_sq=coronaal*coronaal;
sagittaal_femur_sq=sagittaal_femur**2;
run;



%categorize(ds=knee,var=leeftijd,percentile_list=%str(20 40 60 80),class_var=leeftijd_c);
%categorize(ds=knee,var=coronaal,percentile_list=%str(20 40 60 80),class_var=coronaal_c);
%categorize(ds=knee,var=sagittaal_femur,percentile_list=%str(20 40 60 80),class_var=sagittaal_femur_c);
%categorize(ds=knee,var=sagittaal_tibia,percentile_list=%str(20 40 60 80),class_var=sagittaal_tibia_c);
%categorize(ds=knee,var=transversaal_femur,percentile_list=%str(20 40 60 80),class_var=transversaal_femur_c);
%categorize(ds=knee,var=transversaal_tibia,percentile_list=%str(20 40 60 80),class_var=transversaal_tibia_c);
%categorize(ds=knee,var=KSS_ROM,percentile_list=%str(20 40 60 80),class_var=KSS_ROM_c);
%categorize(ds=knee,var=VAS_pijn,percentile_list=%str(20 40 60 80),class_var=vas_pijn_c);

%let vars=%str(coronaal kss_rom kss_functie kss_functie_12mnd kss_functie_24mnd kss_functie_60mnd
kss_klinisch kss_klinisch_12mnd kss_klinisch_24mnd kss_klinisch_60mnd sagittaal_femur sagittaal_tibia
transversaal_femur transversaal_tibia vas_pijn geslacht leeftijd);

%missing_indicators(ds=knee,vars=&vars);

*wide format;
*add change scores;
data wide(drop=i); set knee; 
array end{4} KSS_functie KSS_functie_12mnd KSS_functie_24mnd KSS_functie_60mnd; 
array change{4} change0_function change12_function change24_function change60_function; 
do i=1 to 4;
	change{i}=end{i} - KSS_functie;
end;
run;
	/*check
	proc print data=knee; 
	var KSS_functie KSS_functie_12mnd KSS_functie_24mnd KSS_functie_60mnd change12_function change24_function change60_function
        change0_function; 
	run;
	*/

* add long format;
data long; set wide; 
array t{4} (0 12 24 60);
array f{4} KSS_functie KSS_functie_12mnd KSS_functie_24mnd KSS_functie_60mnd;
array k{4} KSS_klinisch KSS_klinisch_12mnd KSS_klinisch_24mnd KSS_klinisch_60mnd;
array c{4} change0_function change12_function change24_function change60_function;
do i=1 to 4;
 time=t{i}; function=f{i}; clinical=k{i}; 
 change_function=c{i};
output;
end;
run;
	/* check
	proc print data=knee; 
	var PP KSS_functie KSS_functie_12mnd KSS_functie_24mnd KSS_functie_60mnd time function
			change0_function change12_function change24_function change60_function;
	run;
	*/





***  ANALYSIS *****;
options orientation=landscape;
ods pdf compress=9 file="SMK_knee_st200511.pdf" startpage=no  pdftoc=2 style=journal;
ods noproctitle;

title "SMK knee malignment";

title2 "missing data fKSS";
footnote "some patients no functional KSS data";
ods select MissPattern;
proc mi data=wide nimpute=0;
var KSS_functie KSS_functie_12mnd KSS_functie_24mnd KSS_functie_60mnd;
run;

title2 "missing data baseline covariates"; 
footnote "notably transversaal_femur/tibia missing ~ 50%";
ods select MissPattern;
proc mi data=wide nimpute=0;
var KSS_functie coronaal sagittaal_femur sagittaal_tibia transversaal_femur transversaal_tibia KSS_rom VAS_pijn leeftijd geslacht ;
run;

title2 "*fraction* of missing data in covariates (percentage is *100, so 1=100%)";
proc means data=wide n mean;
var miss_geslacht miss_leeftijd miss_sagittaal_femur miss_sagittaal_tibia
miss_kss_rom miss_coronaal miss_vas_pijn
miss_transversaal_femur miss_transversaal_tibia   
miss_kss_functie miss_kss_functie_12mnd 
miss_kss_functie_24mnd miss_kss_functie_60mnd
miss_kss_klinisch miss_kss_klinisch_12mnd miss_kss_klinisch_24mnd miss_kss_klinisch_60mnd 
 ;
run;


title2 "distribution KSS function over time";
footnote " ";
proc sort data=long; by time;
proc sgpanel data=long;
panelby time /columns=1;
histogram function;
run;
footnote " ";

title2 "distribution *change* KSS function over time";
proc sort data=long; by time;
proc sgpanel data=long;
panelby time /columns=1;
histogram change_function;
run;
footnote " ";

title2 "correlation baseline KSS function and change?";
footnote1 bold "higher baseline, smaller increase (ceiling effect)";
proc sgpanel data=long;
panelby time;where time > 0;
scatter x=KSS_functie y=change_function;
run;


title2 "KSS function over time";
footnote bold "sharp increase in the beginning, then constant";
proc sgpanel data=long;
panelby PP /columns=5 rows=3;
series x=time y=function;
*series x=time y=clinical;
colaxis label="time";
rowaxis label="score";
run;


title2 "change KSS function over time";
footnote bold "more linear like profiles";
proc sgpanel data=long;
where time > 0;
panelby PP /columns=5 rows=3;
series x=time y=change_function;
*series x=time y=clinical;
colaxis label="time";
rowaxis label="change from baseline";
run;
footnote " ";



title2 "linear mixed model on changes to 12,24, 60 months";
title3 "no covariates: N=106: 6 patients no value for covariate KSS_functie";

ods exclude classlevels tests3;
proc mixed data=long;class pp;
where time > 0;
model change_function= KSS_functie time /solution outp=predresid;
random intercept time /subject=pp;
run;


title3 "residual plot";
proc sgplot data=predresid;
scatter x=pred y=resid / group=pp;
refline 0 /axis=y;
run;

title3 "observed versus predicted plots";
proc sgpanel data=predresid;
panelby PP /columns=5 rows=3;
scatter x=time y=change_function ;
series x=time y=pred;
run;

* next steps: try to improve with adding covariates?;
* let even op dat je de quantilen op de unieke records, niet de herhaalde metingen doet;

title2 "influence of different covariates (univariately)";
%macro influence(ds=long, outcome_time=change_function, outcome_fixed=change60_function, var=);
* assumes that the categorical version of &var is &var._c;
proc sort data=&ds; by pp time;
proc sgpanel data=&ds;
panelby &var._c/ columns=5;
series x=time y=&outcome_time;
where time > 0;
run;
proc sort data=&ds; by &var._c;
proc boxplot data=&ds; 
where time=0;
plot &outcome_fixed*&var._c;
run;
/* proc freq data=&ds; table &class/missing;run;*/
proc sgplot data=&ds; 
where time=0;
scatter x=&var y=&outcome_fixed;
run;
/*proc means data=&ds mean std q1 median q3; var &outcome_time; class time;run;*/
%mend influence;
title3 "leeftijd in quantiles (lineair)";
%influence(var=leeftijd);

title3 "geslacht (linear)";
proc sgpanel data=long;
panelby geslacht/ columns=2;
series x=time y=change_function;
where time > 0;
run;
proc sort data=long; by geslacht;
proc boxplot data=long; 
where time=0;
plot change60_function*geslacht;
run;

title3 "coronaal in quantiles (misschien kwadratisch? beter bij afwijking??)";
%influence(var=coronaal);
title3 "sagittaal femur in quantiles (misschien kwadratisch??)";
%influence(var=sagittaal_femur);
title3 "sagittaal tibia in quantiles (0 effect?, heel misschien lineair)";
%influence(var=sagittaal_tibia);
title3 "transversaal femur in quantiles (grillig, 0 effect?, linear?";
%influence(var=transversaal_femur);
title3 "transversaal tibia in quantiles (misschien neg kwadratisch)";
%influence(var=transversaal_tibia);
title3 "KSS ROM in quantiles (misschien lineair)";
%influence(var=KSS_ROM);
title3 "VAS pijn in quantiles (0 effect? linear?)";
%influence(var=vas_pijn);


title2 "linear mixed model on changes";
title3 "all covariates";
title4 "only **46** patients with all covariates known";
ods exclude classlevels tests3;
proc mixed data=long;class pp;
where time > 0;
model change_function
		= KSS_functie time geslacht leeftijd
		 coronaal coronaal*coronaal sagittaal_femur sagittaal_femur*sagittaal_femur
		 sagittaal_tibia transversaal_femur transversaal_tibia transversaal_tibia*transversaal_tibia
         KSS_rom vas_pijn	
/solution outp=predresid;
random intercept time /subject=pp;
run;

title2 "residual plot";
proc sgplot data=predresid;
scatter x=pred y=resid /group=pp;
refline 0 /axis=y;
run;


******* imputation *****************************************;
title2 "imputation of transv.femur/tibia (kss_functie), based on all other covars";
title3 "including sagitaal_femur and sagitaal_tibia, but not kss_klinisch";

%let n_imputations=100;
title3 "&n_imputations imputations, note we use the (transformed) variables for the analysis";
title4 "except those that can be linearly predicted from the others (i.e., change_12/24/60mnd)";
footnote "";
* fcs imputation;
proc mi data=wide nimpute=&n_imputations out=mi_wide seed=65537;
class geslacht;
*variables in order from no to many missing values;
var leeftijd geslacht sagittaal_tibia sagittaal_femur sagittaal_femur_sq
	kss_rom vas_pijn coronaal coronaal_sq 
	kss_functie kss_functie_12mnd kss_functie_24mnd kss_functie_60mnd
	transversaal_tibia transversaal_femur transversaal_tibia_sq;
fcs logistic(geslacht /link=glogit) nbiter=100; 
fcs plots=trace(mean std); 
run;


%macro mi_analysis_fromwide(ds_imputed=mi_wide, mi_est_table=mi_est_table);
proc sort data=&ds_imputed; by _imputation_;run;

*changes from baseline;
data &ds_imputed; set &ds_imputed; 
array f{4} kss_functie kss_functie_12mnd kss_functie_24mnd kss_functie_60mnd;
array c{4} change0_function change12_function change24_function change60_function;
do i=1 to 4; c{i}=f{i}-kss_functie; end; 
run;
* set to long format;
data &ds_imputed._long; set &ds_imputed;
array t{4} (0 12 24 60);
array c{4} change0_function change12_function change24_function change60_function;
do i=1 to 4;
	time=t{i}; change_function=c{i};
	output;
end;
run;

title6 "as example: analysis of first imputed dataset";
ods exclude classlevels tests3;
proc mixed data=&ds_imputed._long ;
where _imputation_=1 and time > 0;
class pp;
model change_function
		= KSS_functie time geslacht leeftijd
		 coronaal coronaal_sq 
		 transversaal_femur transversaal_tibia transversaal_tibia_sq
		 sagittaal_femur sagittaal_femur_sq sagittaal_tibia
         KSS_rom vas_pijn	
/solution outp=predresid;
random intercept time /subject=pp;
run;


* now the analysis of all imputation datasets;
proc mixed data=&ds_imputed._long;
ods select none; * no output to display;
ods output SolutionF=parameters_fcs;
by _imputation_;
class pp;
where time > 0;
model change_function
		= KSS_functie time geslacht leeftijd
		 coronaal coronaal_sq 
		 transversaal_femur transversaal_tibia transversaal_tibia_sq
		 sagittaal_femur sagittaal_femur_sq sagittaal_tibia
         KSS_rom vas_pijn	
/solution outp=predresid;
random intercept time /subject=pp;
run;
ods select all; 
ods output close;

title6 "residual plot of few imputated datasets";
proc sgpanel data=predresid;
panelby _imputation_ /columns=5 rows=4; 
where _imputation_ <= 20;
scatter x=pred y=resid /group=pp;
refline 0 /axis=y;
run;


title6 "pooling of estimates of imputed datasets";
ods output parameterestimates=&mi_est_table;
proc mianalyze parms=parameters_fcs;
modeleffects intercept KSS_functie time geslacht leeftijd
		 coronaal coronaal_sq 
		 transversaal_femur transversaal_tibia transversaal_tibia_s
		 sagittaal_femur sagittaal_femur_sq sagittaal_tibia
         KSS_rom vas_pijn;
run;	
%mend;

%mi_analysis_fromwide(ds_imputed=mi_wide,mi_est_table=mi_est_table);

/*** for comparison glmselect **;
proc glmselect data=mi_wide;by _imputation_; 
model change60_function= KSS_functie geslacht leeftijd
		 coronaal coronaal_sq 
		 transversaal_femur transversaal_tibia transversaal_tibia_sq
		 sagittaal_femur sagittaal_tibia
         KSS_rom vas_pijn /selection=lasso;
ods select 
run;
**/


title2 "for comparison: the same model on the 46 patients";
ods output solutionF=est_completers;
proc mixed data=long;class pp;
where time > 0;
model change_function
		= KSS_functie time geslacht leeftijd
		 coronaal coronaal_sq 
		 transversaal_femur transversaal_tibia transversaal_tibia_sq
		 sagittaal_femur sagittaal_femur_sq sagittaal_tibia
         KSS_rom vas_pijn	
/solution cl outp=predresid;
random intercept time /subject=pp;
ods select classlevels Nobs solutionF Covparms;
run;

***** MI door imputeren normaal waardes voor transversaal_femur/tibia***;
title2 "imputation of only transversaal_tibia/femur based on normal values";
title3 "femur: SD=1.2, tibia=2.6";
data pmi_wide; set wide;
call streaminit(65537); 
do _imputation_=1 to &n_imputations;
if miss_transversaal_femur=1 then transversaal_femur=1.2*Rand("normal");
if miss_transversaal_tibia=1 then transversaal_tibia=2.6*Rand("normaal");
transversaal_tibia_sq=transversaal_tibia**(2);
output;
end;
run;

footnote "note that imputing transversaal_femur/tibia does not resolve all missingness (n=89)";
%mi_analysis_fromwide(ds_imputed=pmi_wide, mi_est_table=pmi_est_table);

title2 "comparions of estimates between the three imputation methods";
data a1; set mi_est_table; length method $ 30; 
L95=LCLmean; U95=UCLmean; pvalue=probt;method="multiple imputation";
parameter=lowcase(parm);
keep parameter estimate L95 U95 stderr pvalue method;
run;
data a2; set pmi_est_table;length method $ 30; 
L95=LCLmean; U95=UCLmean; pvalue=probt;method="multiple imputation via normal values";
parameter=lowcase(parm);
keep parameter estimate L95 U95 stderr pvalue method;
run;
data a3; set est_completers; length method $ 30;
L95=lower; U95=upper; pvalue=probt;method="completers analysis";
parameter=lowcase(effect);
keep parameter estimate L95 U95 stderr pvalue method;
run;
data a; set a1 a2 a3;run;
proc sort data=a; by parameter method;run;
proc tabulate data=a; class parameter method;
var estimate L95 U95 pvalue stderr;
table parameter*method
, 
estimate*(mean=" ") L95*(mean=" ") U95*(mean=" ") pvalue*(mean=" ") stderr*(mean=" ");
run;
footnote "note that imputing transversaal_femur/tibia does not resolve all missingness (n=89)";
footnote2 "note that completers analysis is only on 46 subjects";



ods pdf close;

