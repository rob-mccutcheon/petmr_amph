
export subj_dir=$1 #this is the freesurfer analysis directory
export subject_id=sub-$2
export session_id=ses-$3
export bids_id=$4
export orig_data_dir=$5

export SUBJECTS_DIR=$subj_dir
export struc_dir="/data/project/AMPH/data"

cd $subj_dir/..
recon-all -sd $subject_id -s $session_id -i $struc_dir/$subject_id/$session_id/anat/$bids_id'_T1w.nii' -all
