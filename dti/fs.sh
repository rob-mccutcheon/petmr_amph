# gets 1st argument from python and assigns it to data_dir, this is amph/rob/fs_structural/subid/sessid
export subj_dir=$1
export subject_id=$2
export session_id=$3

export SUBJECTS_DIR=$subj_dir
export struc_dir="/data/project/AMPH/data"

cd $subj_dir/..
recon-all -sd $subject_id -s $session_id -i $struc_dir/$subject_id/$session_id/struc/structural.nii -all
