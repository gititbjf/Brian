/*
  Macro definition for getHistoricalPricesForSymbols
*/



%macro getHistoricalPricesForSymbol(symbol, sDay, sMon, sYear, eDay, eMon, eYear,index=);
/**********************************************************************
  Find the last date in the data
**********************************************************************/
%if %sysfunc(exist(rawdata.&symbol.)) %then %do;
  proc sql noprint;
    select max(date) into :maxDate
    from rawdata.&symbol.;
  quit;
run;
data _null_;
  maxdate = &maxdate.;
  today = today();
  weekday = weekday(today());
  put maxdate= today= weekday=; 
  if &maxDate. = today() 
  or (&maxDate. = today()-1 and weekday(today())=7) 
  or (&maxDate. = today()-2 and weekday(today())=1)
     then call symput('abort','yes');
     else call symput('abort','no');
run;
%end;
%else %do;
  %let abort=no;
  %let maxDate=0;
%end;
/**********************************************************************
  Only fetch data that is not current as of today (or as of Friday if
  running on Saturday or Sunday.)
**********************************************************************/
%if "&abort."="no" %then %do;
/* fix month */
%let sMon=%eval(&sMon-1);
%let eMon=%eval(&eMon-1);

/* Indices like SPX need a 'hat' in front of symbol on Yahoo */
%if "&index"="yes" 
    %then %let hat=^;
    %else %let hat=;

** obtained manually: filename yahoo url "http://ichart.finance.yahoo.com/table.csv?s=^SPX&a=00&b=1&c=2004&d=00&e=2&f=2005&g=d&ignore=.csv";

 filename yahoo url "http://ichart.yahoo.com/table.csv?s=&hat.&symbol.%str(&)a=&sMon%str(&)b=&sDay%str(&)c=&sYear%str(&)d=&eMon%str(&)e=&eDay%str(&)f=&eYear%str(&)g=d%str(&)ignore=.csv";
    * proxy='http://inetgw.unx.sas.com';
       
data work.new_&symbol;
   infile yahoo length=len missover;
   length symbol $8;
   keep symbol date open high low close volume adjClose;
   /*
    */
   format date date9.;
   input record $varying200. len ;
   if substr(record,1,4)='Date' then delete;
   if index(record,'yahoo')>0 then stop;
   symbol = "&symbol";
   date = input(record,yymmdd10.);
   comma = index(record,",");
   record = substr(record,comma+1,length(record)-comma);
   *put date= record=;
   %get(open);
   %get(high);
   %get(low);
   %get(close);
   %get(volume);
   %get(adjClose);
run;  
*proc print data=prices;
%end;
%mend getHistoricalPricesForSymbol;

/*** Testing: ***************** 
*%getHistoricalPricesForSymbol(symbol=SPX, sDay=1,  sMon=1, sYear=2004, 
                                          eDay=2,  eMon=1, eYear=2005,index=yes);

%getHistoricalPricesForSymbol(symbol=SHY, sDay=1,  sMon=12, sYear=2004, 
                                          eDay=14, eMon=8, eYear=2014);
run;

%getHistoricalPricesForSymbol(symbol=AACC , sDay=1,  sMon=1, sYear=1985,eDay=31, eMon=12, eYear=2015  );
*/

/* See options at: http://finance.yahoo.com/q/hp?s=FMAGX&a=08&b=2&c=1986&d=06&e=12&f=2004&g=d */

%macro get(var);
    comma = index(record,",");
   *put comma= record=;
   if comma=0
    then &var = input(record,6.2); 
   else do;  
      token = substr(record,1,comma-1);
      &var = input(token,6.2);
      record = substr(record,comma+1,length(record)-comma);
      *put &var= token= record=;
   end;
%mend get;
