import os
import shutil
import subprocess
import sys

mriordti = sys.argv[2]
subject_session = sys.argv[1]
subject_id = subject_session[:3]
session_id = subject_session[-1:]
bids_id = 'sub-'+subject_id+'_ses-'+session_id

orig_data_dir = '/data/project/AMPH/data/sub-'+subject_id+'/ses-'+session_id
dti_dir = '/data/project/AMPH/rob/dti/'
src_dir = '/data/project/AMPH/src/dti/'
data_dir = dti_dir+'sub-'+subject_id+'/ses-'+session_id
fs_dir = '/data/project/AMPH/rob/fs_structural/'+subject_id


# Make the subjects folder
def make_subj_fold(folder):
    if os.path.exists(folder):
        print("folder present")
    else:
        os.makedirs(folder)


make_subj_fold(data_dir)
make_subj_fold(fs_dir)

shutil.copy((orig_data_dir+'/dwi/'+bids_id+'_acq-normal_dwi.nii'), data_dir)
shutil.copy((orig_data_dir+'/dwi/'+bids_id+'_acq-flipped_dwi.nii'), data_dir)
shutil.copy((orig_data_dir+'/dwi/'+bids_id+'_acq-normal_dwi.bvec'), data_dir)
shutil.copy((orig_data_dir+'/dwi/'+bids_id+'_acq-flipped_dwi.bvec'), data_dir)
shutil.copy((orig_data_dir+'/dwi/'+bids_id+'_acq-normal_dwi.bval'), data_dir)
shutil.copy((orig_data_dir+'/dwi/'+bids_id+'_acq-flipped_dwi.bval'), data_dir)
shutil.copy((orig_data_dir+'/anat/'+bids_id+'_T1w.nii'), data_dir)

# change to shell script directory
src_dir = '/data/project/AMPH/src/dti/'
os.chdir(src_dir)

# Choose shell script based on original queue script
if mriordti == "mri":
    subprocess.call(["bash", "mri.sh", data_dir, bids_id])

elif mriordti == "dti":
    subprocess.call(["bash", "dti.sh", data_dir, bids_id])

elif mriordti == "fs":
    subprocess.call(["bash", "fs.sh", fs_dir, subject_id, session_id, bids_id, orig_data_dir])

elif mriordti == "dtimri":
    subprocess.call(["bash", "dtimri.sh", data_dir, bids_id])
