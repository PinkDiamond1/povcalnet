*! version 0.1.0  	<sept2018>
/*=======================================================
Program Name: dotemplate.ado
Author:		  Jorge Soler Lopez
            Espen Beer Prydz	
            Christoph Lakner	
            Ruoxuan Wu				
            Qinghua Zhao			
            World Bank Group	

project:	  Stata package to easily query the [PovcalNet API](http://iresearch.worldbank.org/PovcalNet/docs/PovcalNet%20API.pdf) 
Dependencies: The World Bank - DEC
-----------------------------------------------------------------------
Creation Date: 		  Sept 2018
References:	
Output:		dta file
=======================================================*/


program def povcalnet, rclass

set checksum off //temporarily bypasses controls of files taken from internet

version 9.0

 syntax [,                           ///
        COUNtry(string)              /// 
        REGion(string)               ///
        YEAR(string)                 /// 
        POVline(numlist max=10 >=0)  /// 
        PPP(numlist max=1)           /// 
        AGGregate                    ///
        COUNTRYEStimates             ///
        CLEAR                        ///
        AUXiliary                    ///
        INFOrmation                  ///
        ISO                          ///Standard ISO codes
        SERVER(string)               ///internal use
        COESP(passthru)              ///internal use
        ] 
 

/*==================================================
Defaults           
==================================================*/
qui {
	*---------- Year
	if (wordcount("`year'") > 10){
		noi disp as err "Too many years specified."
		exit 198
	}

	if ("`year'" == "") local year "all"
	* 


	if ("`povline'" == "") local povline = 1.9
	 
	 
	* =============================================================
	* ==================== 0. Housekeeping  =======================
	* =============================================================

	/*==================================================
		Dependencies         
	==================================================*/

	if ("${pcn_cmds_ssc}" == "") {
		local cmds missings

		foreach cmd of local cmds {
			capture which `cmd'
			if (_rc != 0) ssc install `cmd'
		}

		adoupdate `cmds', ssconly
		if ("`r(pkglist)'" != "") adoupdate `r(pkglist)', update ssconly
		global pcn_cmds_ssc = 1  // make sure it does not execute again per session
	}


	/*==================================================
		Housekeeping
	==================================================*/
		
	if  ("`country'" == "") & ("`region'" == "") & ("`year'"=="") & /* 
	 */ ("`aggregate'" == "") & ("`information'" == ""){
			noi di  as err "{p 4 4 2} You did not provide any information. You could use the {stata povcalnet_info: guided selection} instead. {p_end}"
		 error 
		 }

	if ("`information'" != ""){
		povcalnet_info, `clear'
		exit
	}

	if ("`aggregate'" != "") {
		if ("`ppp'" != ""){
			noi di  as err "Option PPP cannot be combined with aggregate."
			error 198
		}
		local agg_display = "Aggregation in base year(s) `year'"
		 }

	if (wordcount("`country'")>2) {
		if ("`ppp'" != ""){
			noi di as err "Option PPP can only be used with one country."
			error 198
		}
	}

	
* ======================================================================
* =============================    1. Execution  =======================
* ======================================================================	
	local commanduse = "povcalnet_query"
	if  ("`aggregate'" != "") local commanduse = "povcalnet_aggquery" 
	
    local f = 1

	foreach i_povline of local povline {	
		tempfile file`f'
		noi `commanduse',   country("`country'")		///
							region("`region'")        	///
							year("`year'")             	///
							povline("`i_povline'")		///
							ppp("`ppp'") 				///
							server("`server'")			///
							`coesp'						///
							`auxiliary'	                ///
							`clear'                     ///
							`information'				///
							`countryestimates'			///
							`iso'						///
							`original'
		local queryfull`f'  "`r(queryfull)'"
		save `file`f''
		local f = `f'+1
		
  }

  local f = `f'-1
  
  if (`f' != 0) {
		use `file1'
		forvalues i = 2(1)`f'  {
			append using `file`i''
		}
  }
	
	local obs = _N 
	if (`obs' != 0) {
		noi di as result "{p 4 4 2}Succesfully loaded `obs' observations.{p_end}"
	}
	
	return local queryfull  "`queryfull1'"
	

} // end of qui
end


