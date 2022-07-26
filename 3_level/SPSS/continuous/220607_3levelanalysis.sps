* Encoding: UTF-8.

* define file handles where the gpl folder is (containing macros.sps and the needed gpl files).
* and the file handle where the dataset is.
* absolute folder paths must be used.
FILE HANDLE gpl /NAME ="C:\Users\st\surfdrive\Actief\20 SW moreel beraad Niek Kok\22 05 analyse als cluster RCT\gpl".
FILE HANDLE data /NAME ="C:\Users\st\surfdrive\Actief\20 SW moreel beraad Niek Kok\22 05 analyse als cluster RCT".

* Open data and name it 'original' for use in macros later on.
GET FILE="data\Moreel beraad effectstudie data_Long.sav".
DATASET NAME original.  
EXECUTE.

* read macros to be used in the analysis.
INSERT   FILE= 'gpl\macros.sps'.


* variables below needed to estimate time effects in the control condition.
COMPUTE T1=0.
If time=1 T1=1.
COMPUTE T2=0.
If time=2 T2=1.
COMPUTE T3=0.
If time=3 T3=1.
COMPUTE T4=0.
If time=4 T4=1.
EXECUTE.


* note that dummy 0,1 variables are used as covars so that the reference category is 0.
* if you see an error code "final Hession not positive definite' and one of the random effects.
*    is estimated at 0, then you can ignore this error code.


* basic model with no confounder corrections AIC= 1577.8. .
!linear_3level continu_outcome=(uitputting) repeatedmeasure=(time) subject=(id1) cluster=(ICU)
fixed=(deelname_MB T2 T3 T4) covars=(deelname_MB teamklimaat T2 T3 T4) cofactors=()
.


* model with correction for  TeamKlimaat, AIC= 1552.6, this is more than 3.7 points decrease so an improvement.
!linear_3level continu_outcome=(uitputting) repeatedmeasure=(time) subject=(id1) cluster=(ICU)
fixed=(deelname_MB T2 T3 T4 teamklimaat) covars=(deelname_MB teamklimaat T2 T3 T4) cofactors=()
.


