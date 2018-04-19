#create variables
subjectses=$1
export subject_id=sub-${subjectses:0:3}
export session_id=ses-${subjectses:3:4}
export analysisfolder='/data/project/AMPH/rob'
export func_folder=$analysisfolder/resting/$subject_id/$session_id/func
export anat_folder=$analysisfolder/resting/$subject_id/$session_id/anat
export sigma=25 #Since my TR = 2 s and I want highpass filtering of 200 second, highpass sigma is = 200/2/2=50
export smoothing=2.1233226 #(FWHM = sigma(sifferent to sigma above!)*2.3548, i.e. 5mm smooth with 2.1233)

# #make directories and copy resting over
# mkdir -p $func_folder $anat_folder
# cd $func_folder
# cp /data/project/AMPH/data/$subject_id/$session_id/func/$subject_id'_'$session_id'_task-rest_bold.nii' resting.nii
#
# #slice timing & motion correction
# slicetimer -i resting.nii -o resting_st.nii --odd -r 2
# mcflirt -in resting_st.nii -o resting_mcf.nii -plots -mats
#
# #average across time series, brain extract and use this to mask full run (the 0.3 threshold is reccomended for ica_aroma)
# fslmaths resting_mcf.nii -Tmean meanresting_mcf.nii
# bet meanresting_mcf.nii resting_bet.nii -f 0.3 -m -n -R
# fslmaths resting_mcf.nii -mas resting_bet_mask resting_mcf_masked.nii
#
# # wait for structural_reg to be made in dti folder and then copy over
# while [ ! -f $analysisfolder/dti/$subject_id/$session_id/structural_reg.nii ]; do sleep 1; done
# cp $analysisfolder/dti/$subject_id/$session_id/structural_reg.nii $anat_folder/structural_reg.nii
#
# # bet the structural (0.5 threshold this time)
# cd $anat_folder
# bet structural_reg.nii structural_reg_bet.nii -f 0.5 -m -R
#
# # coregister the structural to mni(12dofm as rigid body give bad subsequent fnirt results)
# flirt -in structural_reg_bet.nii -ref $analysisfolder/atlases/avg152T1_brain.nii.gz \
# -out structural_reg_betMNI.nii -dof 12 -omat struc2mniaff.mat
#
# #and apply the affine from this to the unbetted structural
# flirt -in structural_reg.nii -ref $analysisfolder/atlases/avg152T1_brain.nii.gz \
# -applyxfm -init struc2mniaff.mat -out structural_reg_MNIlinear.nii
#
# # nonlinear registration of the above affined structural to mni
# fnirt --in=structural_reg_MNIlinear.nii --config=T1_2_MNI152_2mm --fout=warp --iout=warpedstruc
#
# # coregister the functional to the (pre-warped) mni registered structural (to get an affine for ica_aroma)
cd $func_folder
# flirt -in resting_mcf_masked.nii -ref ../anat/structural_reg_betMNI.nii -out epi_reg_betMNI.nii  -dof 12 -omat epireg.mat
#
# # Smooth The gaussian kernel takes its argument as sigma instead of the FWHM
# fslmaths resting_mcf_masked.nii -kernel gauss $smoothing -fmean smoothed.nii

#ica-aroma(this is ran from code stored in AMPH i.e. not the ica_aroma module)

#python /data/project/AMPH/src/ICA-AROMA-master/ICA_AROMA.py -in $func_folder/smoothed.nii.gz -out $func_folder/ICA_AROMA \
#-affmat $func_folder/epireg.mat -warp $anat_folder/warp.nii.gz -mc $func_folder/resting_mcf.nii.par -tr 2

#apply reg_filt with the identified components to unsmoothed data
# motion_ICs=$(<./ICA_AROMA/classified_motion_ICs.txt)
# fsl_regfilt -i resting_mcf_masked.nii.gz -d ./ICA_AROMA/melodic.ica/melodic_mix -f $motion_ICs -o unsmoothed_aroma.nii

#rigid coregister the structural to unsmoothed_aroma
#flirt -in ../anat/structural_reg_bet.nii -ref resting_bet.nii -out structural_coreg.nii  -dof 6 -omat struc2func.mat

#Below MW/CSF regression taken from Ottavias wm_csf_tfilt script
#Segment structural
#mkdir ../anat/fast
#fast -t 1 -n 3 -o ../anat/fast/structural ../anat/structural_reg_bet.nii

# WM signal extraction - create WM mask and extract time series from the denoised functional
# fslmaths ../anat/fast/structural_pve_2.nii.gz -thr 0.9 -ero ../anat/WMmask_eroded
# flirt -in ../anat/WMmask_eroded.nii.gz -applyxfm -init struc2func.mat -ref unsmoothed_aroma.nii.gz -out WMmask_func
# fslmaths WMmask_func -mas resting_bet_mask WMmask2_func
# fslmeants -i unsmoothed_aroma.nii.gz -m WMmask2_func --no_bin -o WM.timeseries

# GM signal extraction - as above
fslmaths ../anat/fast/structural_pve_0.nii.gz -thr 0.9 -ero ../anat/CSFmask_eroded
flirt -in ../anat/CSFmask_eroded.nii.gz -applyxfm -init struc2func.mat -ref unsmoothed_aroma.nii.gz -out CSFmask_func
fslmaths CSFmask_func -mas resting_bet_mask CSFmask2_func
fslmeants -i unsmoothed_aroma.nii.gz -m CSFmask2_func --no_bin -o CSF.timeseries

#combine into text file
paste WM.timeseries CSF.timeseries > nuisance.timeseries

#regress these timeseries out
fslmaths unsmoothed_aroma.nii -Tmean tempMean
fsl_glm -i unsmoothed_aroma.nii -o confounds -d nuisance.timeseries --demean --out_res=residual

#high pass temporal filtering
fslmaths residual -bptf $sigma -1 -add tempMean denoised_func_data

# Move lausanne atlases onto epi (use ANTs as serious headache with flirt origins/reference image)
antsRegistrationSyNQuick.sh -d 3 -f ../anat/structural_reg_bet.nii.gz -m resting_bet.nii.gz -t r -o func2struc_ants
mkdir lausanne_epiregistered
mkdir timeseries
resolutions='33 60 125 250 500'
for resolution in $resolutions
do
    antsApplyTransforms -d 3 -i $analysisfolder/fs_structural/$subject_id/$session_id/lausanne/'ROIv_scale'$resolution'.nii.gz' \
    -r resting_bet.nii.gz \
    -t [func2struc_ants0GenericAffine.mat,1] -o lausanne_epiregistered/lausanne_epireg_$resolution.nii -n NearestNeighbor
    # mask with your epi so not getting parcels with empty voxels
    fslmaths lausanne_epiregistered/lausanne_epireg_$resolution.nii -mas resting_bet_mask lausanne_epiregistered/lausanne$resolution.masked.nii
    #extract timeseries
    fslmeants -i denoised_func_data.nii.gz --label=lausanne_epiregistered/lausanne$resolution.masked.nii -o timeseries/roitimeseries$resolution
done
