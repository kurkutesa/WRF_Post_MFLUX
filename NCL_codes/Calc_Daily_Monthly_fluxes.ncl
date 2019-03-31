  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin

INDIR="../"

yr_start=2001
yr_end = 2002

do year_opt = yr_start,yr_end,1

 system("ncrcat "+INDIR+"CTRL_MFC_"+year_opt+"* MFLUX_WRF_CTRL_"+year_opt+".nc")

f    = addfile ("./MFLUX_WRF_CTRL_"+year_opt+".nc", "r")   

t=f->mflux

t = where(abs(t).gt.1e20, t@_FillValue, t)

counter=0

dt_sizes=dimsizes(t)
l_0 = dt_sizes(0)
l_1 = dt_sizes(1)
l_2 = dt_sizes(2)

tdays_yrr = l_0/8
var2u=new((/tdays_yrr,l_1,l_2/),float)  ;; Only for 2013

tdays=l_0;

do ii=0,(tdays-9),8
   jj=ii+8
   var2u1=dim_avg_n(t(ii:jj,:,:),0)
   var2u(counter,:,:)=var2u1
   counter=counter+1
   print(ii)
   print(jj)
   print(counter)
end do
  
   outfile = addfile("MFLUX_DAILY_"+year_opt+"_WRF.nc","c")
   outfile->mflux  = var2u
   printVarSummary(var2u)
  
   delete(outfile)
   delete(ii)
   delete(jj)
   delete(counter)
   delete(f)
   delete(var2u)

;; Write monthly avearge files

months_opt= (/"01","02","03","04","05","06","07","08","09","10","11","12"/)
  
  f       = addfile ("MFLUX_DAILY_"+year_opt+"_WRF.nc", "r")
  var1    = f->mflux
  mflux   = new((/dimsizes(months_opt),l_1,l_2/),float)
  counter = 0

do ii=0,11
   dim_1 = days_in_month(stringtoint(year_opt),stringtoint(months_opt(ii)))
   doy_s = day_of_year(stringtoint(year_opt),stringtoint(months_opt(ii)),1)     
   doy_e = day_of_year(stringtoint(year_opt),stringtoint(months_opt(ii)),dim_1)    
   
   print ("Interation= "+ii+"  DiM= "+dim_1+"  Doy_s= "+doy_s+"  Doy_e= "+doy_e) 
   
   printVarSummary(var1) 
   var2u1		= dim_avg_n(var1(doy_s-1:doy_e-1,:,:),0)
   mflux(counter,:,:)	= var2u1
   counter		= counter+1
 
   printVarSummary(var2u1)

;; Free the variable for overwrite
 
   delete(var2u1)
   delete(dim_1)
   delete(doy_s)
   delete(doy_e)
   
end do
  

   outfile = addfile("MFLUX_MONTHLY_"+year_opt+"_WRF.nc","c")
   outfile->mflux  = mflux

end do
end
