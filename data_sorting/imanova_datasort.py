# Imanova Data Sorting

# Call the script as e.g.: python imanova_datasort.py 501 A

# The subject folder should contain a session folder (A or B), that contains the .zip from imanova (and nothing else):
# e.g. data/sub-501/ses-A/imanova.zip

# Trouble shooting: (1)Is anaconda 3.6 loaded (and 2.7 unloaded)? (2)Are you in a bash shell?
# (3)The pipeline relies on the imanova data being organised consistently each time

import re
import os
import zipfile
import glob
import shutil
import pydicom
import sys
from nipype.interfaces.dcm2nii import Dcm2niix

subject_id = "sub-"+sys.argv[1]
visit_id = "ses-"+sys.argv[2]
data_dir = "/data/project/AMPH/data/" + subject_id + "/" + visit_id + "/"
data_file = str(os.listdir(data_dir)[0])


def extract_nested_zip(zippedFile, toFolder):
    with zipfile.ZipFile(zippedFile, 'r') as zfile:
        zfile.extractall(path=toFolder)
    os.remove(zippedFile)
    for root, dirs, files in os.walk(toFolder):
        for filename in files:
            if re.search(r'\.zip$', filename):
                fileSpec = os.path.join(root, filename)
                extract_nested_zip(fileSpec, root)


def move_files(file_searchstring, dest_folder):  # dest_folder can be a filename if want to rename (single files only)
    search = glob.glob((data_dir+file_searchstring))
    if len(search) == 1:
        file = search[0]
        shutil.move(file, (data_dir+dest_folder))
    elif len(search) > 1:
        for filename in search:
            shutil.move(filename, (data_dir+dest_folder))


def move_files_recursive(file_searchstring, dest_folder):
    search = glob.glob((data_dir+file_searchstring), recursive=True)
    if len(search) == 1:
        file = search[0]
        shutil.move(file, (data_dir+dest_folder))
    elif len(search) > 1:
        for filename in search:
            shutil.move(filename, (data_dir+dest_folder))


# Move qsms as we want these non converted
def move_qsms(dicom_dir):
    dicoms = glob.glob(dicom_dir+'/*.dcm')
    for file in dicoms:
        if pydicom.dcmread(file).SeriesDescription == 'CV SWAN QSM':
            shutil.move(file, (data_dir+'qsm'))


# Unzip original zip its subzips
extract_nested_zip((data_dir+data_file), data_dir)

# Make directories
new_folders = ["asl", "dwi", "mrs", "func", "anat", "qsm", 'jsons', 'pet', 'misc']
for folder in new_folders:
    os.makedirs(data_dir+folder)

# Find dicom directory
dicom_dir = glob.glob((data_dir+'**/Series*'), recursive=True)[0]

# Get QSM dicoms
move_qsms(dicom_dir)

# Convert remaining dicoms
converter = Dcm2niix()
converter.inputs.source_dir = dicom_dir
converter.inputs.output_dir = data_dir
converter.inputs.compress = 'n'
converter.run()
converter.cmdline

# Move and rename files
move_files('/*BRAVO*nii*', ('anat/'+subject_id+'_'+visit_id+'_T1w.nii'))

move_files('/*task1*nii*', ('func/'+subject_id+'_'+visit_id+'_task-CA_run-1_bold.nii'))
move_files('/*task2*nii*', ('func/'+subject_id+'_'+visit_id+'_task-CA_run-2_bold.nii'))
move_files('/*rsfMRI*nii*', ('func/'+subject_id+'_'+visit_id+'_task-rest_bold.nii'))

move_files('/*flip*DTI.nii', ('dwi/'+subject_id+'_'+visit_id+'_acq-flipped_dwi.nii'))
move_files('/**DTI.nii*', ('dwi/'+subject_id+'_'+visit_id+'_acq-normal_dwi.nii'))
move_files('/*flip*DTI*bvec*', ('dwi/'+subject_id+'_'+visit_id+'_acq-flipped_dwi.bvec'))
move_files('/*flip*DTI*bval*', ('dwi/'+subject_id+'_'+visit_id+'_acq-flipped_dwi.bval'))
move_files('/*DTI*bvec*', ('dwi/'+subject_id+'_'+visit_id+'_acq-normal_dwi.bvec'))
move_files('/*DTI*bval*', ('dwi/'+subject_id+'_'+visit_id+'_acq-normal_dwi.bval'))

move_files('/*json*', 'jsons')

move_files('/*CASL*nii*', ('asl/'+subject_id+'_'+visit_id+'_asl.nii'))

move_files('/*Dynamic*', 'misc')
move_files('/*B1_Map*nii*', 'misc')
move_files('/*MRAC*', 'misc')
move_files('/*Plane_Loc*', 'misc')
move_files('/*PROBE*nii*', 'misc')
move_files('/*ASSET*', 'misc')
move_files('/*Static*', 'misc')

move_files_recursive('**/*Dynamic_MAC.img', 'pet/dynamic_mrac.img')
move_files_recursive('**/*Dynamic_MAC.hdr', 'pet/dynamic_mrac.hdr')
move_files_recursive('**/*Dynamic_NAC.img', 'pet/dynamic_nac.img')
move_files_recursive('**/*Dynamic_NAC.hdr', 'pet/dynamic_nac.hdr')
move_files_recursive('**/*.anc', 'pet/dynamic_nac.anc')
