
/*
   Define the macro that the next step will execute
*/ 

%macro getFundNameForSymbol(symbol);

filename yahoo url "http://finance.yahoo.com/q?s=&symbol"
        ;* proxy='http://inetgw.unx.sas.com';
       
data temp;
   infile yahoo length=len missover;
   length symbol $6 fund $67;
   keep symbol fund;
   
   input record $varying500. len ;
   symbol = "&symbol";
   nameloc = index(record,"Summary for");
    if nameloc>0 then do;
      put symbol= nameloc= record=;
      nameloc = nameloc+12;
      nameend = index(record,"- Yahoo! Finance");
       put symbol= nameloc= nameend= record=;
       if nameend=0 then do;
         fund = trim(substr(record,nameloc));
        fund = tranwrd(fund,'&amp;','&');  * Sometimes ampersand is messed up;
        put symbol= nameloc= nameend= fund=;
        output;
         stop;
       end; 
      else if nameend>nameloc+1 then do;
         fund = trim(substr(record,nameloc,nameend-nameloc));
        fund = tranwrd(fund,'&amp;','&');  * Sometimes ampersand is messed up;
        put symbol= nameloc= nameend= fund=;
        output;
         stop;
       end;
     end; 
run;

proc append base=Work.Funds data=temp;
run; 
%mend getFundNameForSymbol;

%*getFundNameForSymbol(FIREX);  *TEST ;
