#!/bin/bash

######                          SUBMIT SCRIPTS                                       ######     
#* The following script creates a slurm job file named as set_time_${yr}.bash for every  *#
#* year and each month.									 *#	
#* The submitted job renames and sets the time axis to the files generated bt the script *#
#* "submit_surface_water_budget.bash".							 *#
#* The script computes monthly means of budget terms                                     *#
######                          #############                                        ######     

DIR='./Surface_Budget'

for yr in {2001..2012}

do

echo $yr


for mm in {\01,\02,\03,\04,\05,\06,\07,\08,\09,10,11,12}

do

echo $mm

cat > set_time_${yr}_${mm}.bash << EOF1
#!/bin/bash
#SBATCH --account=rpp-project_PI
#SBATCH --time=00-00:05           # time (DD-HH:MM)
#SBATCH --nodes=1
#SBATCH --tasks-per-node=32
#SBATCH --mem=45G

yr=$yr

module load cdo
module load nco

cd $DIR
ncrename -dTime,time $DIR/Budget_terms_${yr}/CTRL_BT_${yr}_${mm}.nc
cdo settaxis,${yr}-${mm}-01,00:00:00,1day $DIR/Budget_terms_${yr}/CTRL_BT_${yr}_${mm}.nc $DIR/Budget_terms_${yr}/CTRL_BT_${yr}_${mm}_time.nc

cd $DIR/Budget_terms_${yr}/

mkdir Daily_Budget_terms_${yr}

cdo monmean CTRL_BT_${yr}_${mm}_time.nc CTRL_BT_${yr}_${mm}_monthly.nc

mv CTRL_BT_${yr}_${mm}.nc ./Daily_Budget_terms_${yr}

EOF1

/opt/software/slurm/current/bin/sbatch set_time_${yr}_${mm}.bash
echo "Submit JOB for "$yr "  "$mm

done ### for months

done ### for years

