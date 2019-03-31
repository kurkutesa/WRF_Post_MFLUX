;**********************************************************
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;; This repository contains the NCL, Python codes as well as shells scripts to compute Vertically Integrated Moisture Flux
;**********************************************************

;;;; File and Directory permission calculator https://chmod-calculator.com/
;;;; changes 
  begin
 
;******************************************************
; open file and read in data: data are on a Fixed Grid
;******************************************************
 

 INDIR="./"
 diri_constant= "./"

;; Array for years and months
 years=(/"2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","2011","2012","2013"/)
 months_opt= (/"01","02","03","04","05","06","07","08","09","10","11","12"/)

;; Open WRF constant file and read variables from it. 

 wrf_const = addfile(diri_constant + "wrfout_d01_constant.nc","r")

 T2 = wrf_user_getvar(wrf,"T2",-1)   	;; Surface Temp 
 lon2d = wrf->XLONG(0,:,:)	     	;; Longitude
 lat2d = wrf->XLAT(0,:,:)		;; Latitude
 lat = lat2d(:,0)			;; Xarray of latitudes
 lon = lon2d(0,:)			;; Xarray of Longitudes
 T2 = wrf->T(0,0,:,:)			;; Read variable fro single time
 Mfx = wrf->MAPFAC_U(0,:,:)		;; Map Factor along X
 Mfy = wrf->MAPFAC_V(0,:,:)		;; Mao Factor along Y
 DX = 4000				;; Grid point distance
 DY = 4000				;; Grid point Distance	


;; Do loop over Years

  do year_1 = 0,dimsizes(years)-1
 

;; Do loop over months
   
  do mm = 0,dimsizes(months_opt)-1 ; 2

  year_opt = years(year_1)

;; Get days in the month

  dim_1 = days_in_month(stringtoint(year_opt),stringtoint(months_opt(mm)))  

;; Do loop over days

  do dim=1,dim_1
   
;; get the current date of the year and month 
  day_cf= systemfunc("date --date '"+year_opt+"-0"+months_opt(mm)+"-"+dim+" ' +%Y-%m-%d | cut -d'-' -f3 | cut -c1-2")
  day_current=stringtoint(day_cf)

;; Read 3D variable WRF file (i.e. Time, Level, Lon, Lat)
  f = addfile(INDIR+"/PGW_"+year_opt+"_2D_3D/"+"wrf3d_d01_"+year_opt+"-"+months_opt(mm)+"-"+day_cf+"_00:00:00","r")
;; Read 2D variable WRF file (i.e. Time, Lon, Lat)
  b = addfile(INDIR+"/PGW_"+year_opt+"_2D_3D/"+"wrf2d_d01_"+year_opt+"-"+months_opt(mm)+"-"+day_cf+"_00:00:00","r")

;; read time variable or time stamp

  Times = b->XTIME 

;; create new variable (mflux .. i.e. moisure flux) for the day

  ml_sizes=dimsizes(T2)
  ml_1 = dt_sizes(1)
  ml_2 = dt_sizes(2)

  mflux=new((/8,ml_1,ml_2/),float)

;; Delete variable for future conflict if any ;)

  delete([/ml_sizes,ml_1,ml_2/])
 
;; Do loop over hours

  do it=0,7  ; For loop over Time (sub-daily)

;; Read surface pressure from 2D file

  psfc = b->PSFC(it,:,:)

;; Define Vertical pressure levels for integration

  plev = (/ 100000.,97500.,95000.,92500.,90000.,87500.,85000.,82500.,80000., \
 	77500.,75000.,72500.,70000.,67500.,65000.,62500.,60000., \
	55700.,55000.,52500.,50000.,45000.,40000.,35000.,30000.,25000.,20000., \
	17500.,15000.,12500.,10000.,9000.,8000., 7000., 6000., 5000. /)               ;;;; In Pascals

;;; calculate the array of pressure difference between twopressure levels for an integration
	
  dp  = dpres_plevel(plev, psfc, 5000, 0)   ; In pascals
 
  printVarSummary(dp)
  
;; Read winds and moisture variables from 3D files.

  u1 = f->U(it,:,:,:)  ; in ms-1
  v1 = f->V(it,:,:,:)  ; ms-1
  mr  = f->QVAPOR(it,:,:,:) ; The original unit of QVAPOR is kgkg-1
  q0  = mr/(1+mr)           ; kgkg-1
  Q   = q0      ;
  P   = f->P(it,:,:,:)   ; Pressure is in Pascals (Pa)
 
;;; Unstagger the wind

  u2 = wrf_user_unstagger(u1,u1@stagger)
  v2 = wrf_user_unstagger(v1,v1@stagger)
  
  dt_sizes=dimsizes(P)
  l_0 = dt_sizes(0)
  l_1 = dt_sizes(1)
  l_2 = dt_sizes(2)

;; Define temporary variable for loop

  var2u=new((/dimsizes(plev),l_1,l_2/),float)
  var2v=new((/dimsizes(plev),l_1,l_2/),float)

;;; Perform verticle intregration over pressure levels

  do jj=0,dimsizes(plev)-1

  var2u(jj,:,:) = wrf_interp_3d_z(u2*Q,P,plev(jj))
  var2v(jj,:,:) = wrf_interp_3d_z(v2*Q,P,plev(jj))

  end do

;; Store output to the seperate file 

   outfile = addfile("CTRL_MB_"+year_opt+"_"+months_opt(mm)+"_"+day_cf+"_"+it+".nc","c")
   outfile->var2u = var2u
   outfile->var2v = var2v

 ;;;;;;; Compute flux at every layer  
 
  u = var2u*dp   ;     
  v = var2v*dp

  outfile->u = u
  outfile->v = v

  ; integrate fluxes from top to bottom
 
  U1= dim_sum_n(u,0)/9.81
  V1= dim_sum_n(v,0)/9.81

;; assigne dimensions to the vaiables

  U1!0 = "lat"
  U1!1 = "lon"

  V1!0 = "lat"
  V1!1 = "lon"
  
  outfile->Integrated_uq=U1
  outfile->Integrated_vq=V1 

  dim_UV = dimsizes(U1)
  NX = dim_UV(1)
  NY = dim_UV(0)
  


;;;; Create divergence variable

  DIV_NCL = new((/699,639/),float)

  begTime = get_cpu_time()


  DIV_NCL = uv2dv_cfd (U1,V1,lat,lon, 2)

  print("Time Required " + (get_cpu_time() - begTime) + " seconds")

  delete(begTime)

 
  mflux(it,:,:)=DIV_NCL
  delete(DIV_NCL)
  
  print("Calculating for Time= "+it+ "Day = " +day_cf+ "Month= "+mm+ "Year= " +year_opt)

  end do   ; hours
  
;; Assign Variable to the Vertically Integrated Moisture Flux

  mflux!0 = "Times"
  mflux!1 = "lat"
  mflux!2 = "lon"

  mflux&Times = Times
  mflux&lat = lat
  mflux&lon = lon

  mflux@Name = "Integated Horizontal Moisture Flux"

;;; Write output to the file

  ncdf = addfile("CTRL_MFC_"+year_opt+"_"+months_opt(mm)+"_"+day_cf+".nc","c")

  filedimdef(ncdf,(/"Times","lat","lon"/),(/-1,dimsizes(lat),dimsizes(lon)/),(/True,False,False/))
  fAtt = True            ; assign file attributes
  fAtt@Contact ="Sopan Kurkute (kurkute.sopan@usask.ca)"
  fAtt@creation_date = systemfunc ("date")
  fileattdef( ncdf, fAtt )

  ncdf->mflux  = mflux
 
  delete(mflux)
  delete(INDIR)   



  end do  ; days
  end do  ; months
  
  end do  ;  years
  end
  
  exit
