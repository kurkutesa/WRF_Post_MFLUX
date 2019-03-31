load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;; Read the enviornment variable passed to the script via shell scripts. For this script it would be a YEAR1=2001

   year_opt = stringtointeger(getenv("YEAR1"))  ;

;; Start and End Months
   months_s=1
   months_e=12

;; Path of the WRF data output files
   diri="./"

;; Read WRF constant directory in order to assign coordinate attributes to input data variables

   wrf=addfile("/home/kurkutes/wrfout_d01_constant.nc","r")
   T2 = wrf_user_getvar(wrf,"T2",-1)
   lon2d = wrf->XLONG(0,:,:)
   lat2d = wrf->XLAT(0,:,:)

   print(lat2d(0,0))
   print(lon2d(0,0))

;; Soil layers

   d1 = 100.0
   d2 = 300.0
   d3 = 600.0
   d4 = 1000.0


;;; Set netcdf file options

   setfileoption("nc","Format","LargeFile")
   
   print(year_opt)
 
;; Create the directory based on the year

   system("mkdir Budget_terms_"+year_opt)
 
;; Loop through Years

   do months = months_s,months_e
 
   dim_1 = days_in_month(year_opt,months)
   print(dim_1)

;; Define variables

  resid=new((/dim_1,699,639/),float)
  acrain=new((/dim_1,699,639/),float)
  acqfx=new((/dim_1,699,639/),float)
  rsfc=new((/dim_1,699,639/),float)
  rund=new((/dim_1,699,639/),float)
  soilm=new((/dim_1,699,639/),float)
  canwat=new((/dim_1,699,639/),float)
  swe=new((/dim_1,699,639/),float)
  acQFX=new((/dim_1,699,639/),float)
  acSWE=new((/dim_1,699,639/),float)
  RES_SWE=new((/dim_1,699,639/),float)


  do dim = 1,dim_1

   dim1=dim-1

   day_cf= systemfunc("date --date '"+year_opt+"-0"+months+"-"+dim+" ' +%Y-%m-%d | cut -d'-' -f3 | cut -c1-2")
   day_current=stringtoint(day_cf)
   month_cf = systemfunc("date --date '"+year_opt+"-0"+months+"-"+dim+" ' +%Y-%m-%d | cut -d'-' -f2 | cut -c1-2")
   month_current=stringtoint(month_cf)
   year_cf = systemfunc("date --date '"+year_opt+"-0"+months+"-"+dim+" ' +%Y-%m-%d | cut -d'-' -f1 | cut -c1-4")
   year_current=stringtoint(year_cf)


   day_nf= systemfunc("date --date '"+year_opt+"-0"+months+"-"+dim+" +1 days' +%Y-%m-%d | cut -d'-' -f3 | cut -c1-2")
   day_next=stringtoint(day_nf)
   month_nf= systemfunc("date --date '"+year_opt+"-0"+months+"-"+dim+" +1 days' +%Y-%m-%d | cut -d'-' -f2 | cut -c1-2")
   month_next=stringtoint(month_nf)
   year_nf= systemfunc("date --date '"+year_opt+"-0"+months+"-"+dim+" +1 days' +%Y-%m-%d | cut -d'-' -f1 | cut -c1-4")
   year_next=stringtoint(year_nf)

;; read input data files

   ctrl_can_max = diri+year_opt+"_2D_3D"+"/wrf2d_d01_"+year_cf+"-"+month_cf+"-"+day_cf+"_00:00:00"
   b = addfile(ctrl_can_max, "r")

   ctrl_can_const = "/home/kurkutes/wrfout_d01_constant.nc"
   a        = addfile(ctrl_can_const,"r")

   ctrl_can_next = diri+year_nf+"_2D_3D"+"/wrf2d_d01_"+year_nf+"-"+month_nf+"-"+day_nf+"_00:00:00"
   c = addfile(ctrl_can_next, "r")


;---Read temperature at first time step 

   Times = c->XTIME

   print(Times)
  
   delete(Times)
    
;; Soil Moisture
   begin_sm_layers = b->SMOIS  
   begin_sm        = d1*begin_sm_layers(:,0,:,:) + d2*begin_sm_layers(:,1,:,:) + d3*begin_sm_layers(:,2,:,:) + d4*begin_sm_layers(:,3,:,:)

;; Canapory Water Vapor
   begin_canwat   = b->CANWAT
   begin_canwat@_FillValue = default_fillvalue("float")
   begin_canwat = where(begin_canwat.le.-1e30,begin_canwat@_FillValue, begin_canwat)

;; Snow water equivalanet
   begin_swe    = b->SNOW

;; Subsurface RUn-Off
   begin_urun   = b->UDROFF

;; Surface Runoff
   begin_srun   = b->SFROFF

;; Latent heat
   begin_lh1    = b->LH
   lh     = (begin_lh1)*(0.035408)  ;; Convert to (W/m2) to mm/day ... 24*60*60/2.45e6

   delete(begin_lh1)

   lh@_FillValue = default_fillvalue("float")
   lh = where(lh.le.-1e30, lh@_FillValue, lh)

;; 3 Hourly acculmulated Precipitation 

   rain        = b->PREC_ACC_NC  ; 3-hr precipitation amount (rain+snow+graupel)
   rain@_FillValue = default_fillvalue("float")
   rain = where(rain.le.-1e30, rain@_FillValue, rain)

;; 3 hourly accumulated snow  
   ACSWE        = b->SNOW   ;   SNOW_ACC_NC  ; 3-hr precipitation amount (rain+snow+graupel)
   ACSWE@_FillValue = default_fillvalue("float")
   ACSWE = where(ACSWE.le.-1e30, ACSWE@_FillValue, ACSWE)


;;;; Read next day file and take the difference between 0th time step of next day and 0th time step of current day.

   end_sm_layers = c->SMOIS
   end_sm        = d1*end_sm_layers(:,0,:,:) + d2*end_sm_layers(:,1,:,:) + d3*end_sm_layers(:,2,:,:) + d4*end_sm_layers(:,3,:,:)
   end_swe       = c->SNOW
   end_canwat    = c->CANWAT
   end_canwat@_FillValue = default_fillvalue("float")
   end_canwat = where(end_canwat.le.-1e30,end_canwat@_FillValue, end_canwat)

   end_urun   = c->UDROFF
   end_srun   = c->SFROFF

    
   acrain(dim1,:,:)   = dim_sum_n(rain,0)
   acSWE(dim1,:,:)    = dim_sum_n(ACSWE,0)   
   acqfx(dim1,:,:)    = dim_avg_n(lh,0)

;;;; Take daily mean of the following quantities

   swe(dim1,:,:)      = dim_avg_n(end_swe,0) - dim_avg_n(begin_swe,0)
   canwat(dim1,:,:)   = dim_avg_n(end_canwat,0) - dim_avg_n(begin_canwat,0)
   soilm(dim1,:,:)    = dim_avg_n(end_sm,0) - dim_avg_n(begin_sm,0)

;;; Daily accumulated values of Surface and Underground Run-Off
   rsfc(dim1,:,:)     = end_srun(0,:,:) - begin_srun(0,:,:)
   rund(dim1,:,:)     = end_urun(0,:,:) - begin_urun(0,:,:)

   printVarSummary(soilm)
   printVarSummary(acrain)
   print(dim1) 


;;; The LHS is residual which represents the Evapotranspiration + residual for NOAH-LSM WRF
   resid(dim1,:,:)  = acrain(dim1,:,:) - acqfx(dim1,:,:) - rsfc(dim1,:,:) - rund(dim1,:,:) - acSWE(dim1,:,:) - soilm(dim1,:,:) - canwat(dim1,:,:)
   ET(dim1,:,:) = dim_avg_n(resid,0)

  end do

;;; Write output to the files
  
  outfile = addfile("./Budget_terms_"+year_opt+"/CTRL_BT_"+year_opt+"_0"+months+".nc","c")

  acrain@description = "Daily Accumulated Precipitation"
  acrain@units = "MM"
  copy_VarMeta( rain, acrain )
  outfile->ACPRCP  = acrain

  copy_VarMeta( rain, acqfx ) 
  acqfx@units = "MM"
  acqfx@description = "Daily Evaporation"
  outfile->ACQFX   = acqfx

  copy_VarMeta( rain, swe )
  swe@units = "Kg m-2"
  swe@description = "Daily Change in SWE"
  outfile->SWE     = swe

  copy_VarMeta( rain, soilm )
  soilm@units = "MM"
  soilm@description = "Daily change in Soil Moisture"
  outfile->SOILM   = soilm

  copy_VarMeta( rain, canwat )
  canwat@units = "kgm-2"
  canwat@description = "Daily change in Canopy Water"
  outfile->CANWAT  = canwat


  copy_VarMeta( rain, ET )
  ET@description = "Daily Evapotranspiration "
  ET@units = "MM"
  outfile->ET  = ET

  copy_VarMeta( rain, rund )
  rund@units = "MM"
  rund@description = "Daily Underground Flow"
  outfile->acRUND  = rund

  copy_VarMeta( rain, rsfc )
  rsfc@units = "MM"
  rsfc@description = "Daily Surface Runoff"
  outfile->acRSFC  = rsfc

  copy_VarMeta( rain, acSWE )
  acSWE@description = "1-hr change in surface Flow (begin_time and valid_time)."
  outfile->acSWE  = acSWE


  global = True
  global@ncl_script_name = get_script_name()
  global@file_creation = systemfunc( "date" ) + " kurkute.sopan@usask.ca (sopan kurkute)"
  fileattdef( outfile, global )

  delete(acrain)
  delete(acqfx)
  delete(swe)
  delete(rsfc)
  delete(rund)
  delete(canwat)
  delete(soilm)
  delete(acSWE)
  delete(resid)
  delete(dim)
  delete(acQFX)
  delete(RES_SWE)
end do ; ends of months

delete(year_opt)

  end    ; end of code

