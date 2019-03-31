#!/bin/bash

###### 				SUBMIT SCRIPTS					     ######	
#* The following script creates a slurm job file named as test_${yr}.bash for every year *#
#* The test_${yr}.bash script runs Water_budget_edited_modified_ET.ncl code to compute   *#
#* surface water bdget									 *#
######				#############					     ######	


for yr in {2002..2012}
do
echo $yr
cat > test_${yr}.bash << EOF1
#!/bin/bash
#SBATCH --account=rpp-
#SBATCH --time=00-00:55           # time (DD-HH:MM)
#SBATCH --nodes=1
#SBATCH --tasks-per-node=32
#SBATCH --mem=45G

export YEAR1="$yr"

module load ncl/6.4.0
cd $PATH_OF_WORKING_DIRECTORY
ncl Water_budget_edited_modified_ET.ncl
#ncl Water_budget_edited.ncl
EOF1
/opt/software/slurm/current/bin/sbatch test_${yr}.bash
echo "Submit JOB for "$yr 
done
