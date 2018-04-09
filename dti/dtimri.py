import os
import shutil
import subprocess
import sys

mriordti = sys.argv[2]
subject_session = sys.argv[1]
subject_id = subject_session[:3]
session_id = subject_session[-1:]

orig_data_dir = '/data/project/AMPH/data/'+subject_id+'/'+session_id
dti_dir = '/data/project/AMPH/rob/dti/'
src_dir = '/data/project/AMPH/src/dti/'
data_dir = dti_dir+subject_id+'/'+session_id
fs_dir = '/data/project/AMPH/rob/fs_structural/'+subject_id


# Make the subjects folder
def make_sub_fold(folder):
    if os.path.exists(folder):
        print("folder present")
    else:
        os.makedirs(folder)


make_sub_fold(data_dir)
make_sub_fold(fs_dir)

shutil.copy((orig_data_dir+'/dti/dti.nii'), data_dir)
shutil.copy((orig_data_dir+'/dti/flipped_dti.nii'), data_dir)
shutil.copy((orig_data_dir+'/dti/dti.bvec'), data_dir)
shutil.copy((orig_data_dir+'/dti/flipped_dti.bvec'), data_dir)
shutil.copy((orig_data_dir+'/dti/dti.bval'), data_dir)
shutil.copy((orig_data_dir+'/dti/flipped_dti.bval'), data_dir)
shutil.copy((orig_data_dir+'/struc/structural.nii'), data_dir)

# change to shell script directory
src_dir = '/data/project/AMPH/src/dti/'
os.chdir(src_dir)

# Choose shell script based on original queue script
if mriordti == "mri":
    subprocess.call(["bash", "mri.sh", data_dir])

elif mriordti == "dti":
    subprocess.call(["bash", "dti.sh", data_dir])

elif mriordti == "fs":
    subprocess.call(["bash", "fs.sh", fs_dir, subject_id, session_id])

elif mriordti == "dtimri":
    subprocess.call(["bash", "dtimri.sh", data_dir])
