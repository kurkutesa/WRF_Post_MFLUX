#!/bin/bash

######                          SUBMIT SCRIPTS                                       ######     
#* The following script creates a slurm job file named as cal_avg_${yr}.bash		 *#
#* The script usage data generetaed from submit_all_monthly_budget_terms.bash to merge   *#   
#* data daily and monthly respt.                                                         *#
######                          #############                                        ######     

DIR='./Surface_Budget'

for yr in {2001..2012}

do

echo $yr

cat > cal_avg_${yr}.bash << EOF1
#!/bin/bash
#SBATCH --account=rpp-project_PI
#SBATCH --time=00-00:08           # time (DD-HH:MM)
#SBATCH --nodes=1
#SBATCH --tasks-per-node=32
#SBATCH --mem=45G

yr=$yr

module load cdo
module load nco

cd $DIR

cdo mergetime $DIR/Budget_terms_${yr}/CTRL_BT_${yr}_*_time.nc $DIR/Budget_terms_${yr}/CTRL_BT_Annual_${yr}.nc

cdo mergetime $DIR/Budget_terms_${yr}/CTRL_BT_${yr}_*_monthly.nc $DIR/Budget_terms_${yr}/CTRL_BT_Monthly_${yr}.nc 

cd $DIR/Budget_terms_${yr}/

mv CTRL_BT_${yr}_*_time.nc ./Daily_Budget_terms_${yr}
mv CTRL_BT_${yr}_*_monthly.nc ./Daily_Budget_terms_${yr}

EOF1

/opt/software/slurm/current/bin/sbatch set_time_${yr}_avg.bash
echo "Submit JOB for "$yr

done ### for years

