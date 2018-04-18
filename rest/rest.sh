#create path variables
export subject_id=sub-$1
export session_id=ses-$2
export analysisfolder='/data/project/AMPH/rob'
export func_folder=$analysisfolder/resting/$subject_id/$session_id/func
export anat_folder=$analysisfolder/resting/$subject_id/$session_id/anat
export sigma=50 #Since my TR = 2 s and I want highpass filtering of 200 second, highpass sigma is = 200/2/2=50

#make directories and copy resting over
mkdir -p $analysisfolder/resting/$subject_id/$session_id/{anat, func}
cp /data/project/AMPH/data/$subject_id/$session_id/func/$subject_id'_'$session_id'_task-rest_bold.nii' \
$func_folder/resting.nii

#slice timing
cd $func_folder
slicetimer -i resting.nii -o resting_st.nii --odd -r 2

#motion correction
mcflirt -in resting_st.nii -o resting_mcf.nii -plots -mats

#average across time sries, brain extract and use this to mask full run (the 0.3 threshold is reccomended for ica_aroma)
fslmaths resting_mcf.nii -Tmean meanresting_mcf.nii
bet meanresting_mcf.nii resting_bet.nii -f 0.3 -m -n -R
fslmaths resting_mcf.nii -mas resting_bet_mask resting_mcf_masked.nii

# wait for structural_reg to be made in dti folder and then copy over
while [ ! -f $analysisfolder'/dti/sub-'$subject_id'/ses-'$session_id'/structural_reg.nii' ]; do sleep 1; done
cp $analysisfolder'/dti/sub-'$subject_id'/ses-'$session_id'/structural_reg.nii' $anat_folder/structural_reg.nii

# bet the structural
cd $anat_folder
bet structural_reg.nii structural_reg_bet.nii -f 0.5 -m -R

# coregister the structural to mni(12dofm as rigid body give bad subsequent fnirt results)
flirt -in structural_reg_bet.nii -ref $analysisfolder/atlases/avg152T1_brain.nii.gz \
-out structural_reg_betMNI.nii -dof 12 -omat strucmniaff.mat

#and apply the affine from this to the unbetted structural
flirt -in structural_reg.nii -ref $analysisfolder/atlases/avg152T1_brain.nii.gz \
-applyxfm -init strucmniaff.mat -out structural_reg_MNIlinear.nii

# nonlinear registration of the above affined structural to mni
fnirt --in=structural_reg_MNIlinear.nii --config=T1_2_MNI152_2mm --fout=warp --iout=warpedstruc

# coregister the functional to the (pre-warping) mni registered structural (to get an affine for ica_aroma)
cd $func_folder
flirt -in resting_mcf_masked.nii -ref ../anat/structural_reg_betMNI.nii -out epi_reg_betMNI.nii  -dof 12 -omat epireg.mat

# Smooth The gaussian kernel takes its argument as sigma instead of the FWHM,  to convert see
# http://mathworld.wolfram.com/GaussianFunction.html (FWHM = sigma*2.3548) 5mm here:
fslmaths resting_mcf_masked.nii -kernel gauss 2.1233226 -fmean smoothed.nii

#ica-aroma(this is ran from code stored in AMPH i.e. not the ica_aroma module)
python /data/project/AMPH/src/ICA-AROMA-master/ICA_AROMA.py -in $func_folder/smoothed.nii.gz -out ICA_AROMA \
-affmat $func_folder/epireg.mat -warp $anat_folder/warp.nii.gz -mc $func_folder/resting_mcf.nii.par

#apply reg_filt with the identified components to unsmoothed data
motion_ICs=$(<./ICA_AROMA/classified_motion_ICs.txt)
fsl_regfilt -i resting_mcf_masked.nii.gz -d ./ICA_AROMA/melodic.ica/melodic_mix -f $motion_ICs -o unsmoothed_aroma.nii

#rigid coregister unsmoothed_aroma to the structural
# flirt -in unsmoothed_aroma.nii -ref ../anat/structural_reg_bet.nii -out unsmoothed_coreg.nii  -dof 6 -omat
# firt -in unsmoothed_aroma.nii -applyxfm -init epi2struct.mat -o testflirt

#rigid coregister the structural to unsmoothed_aroma
flirt -in ../anat/structural_reg_bet.nii -ref resting_bet.nii -out structural_coreg.nii  -dof 6 -omat struc2func.mat


#Taken from ottavias wm_csf_tfilt script
#Segment structural
cd $anat_folder
mkdir structural.fast
fast -t 1 -n 3 -o structural.fast/structural structural_reg_bet.nii

# WM signal extraction - create WM mask and extract time series from the denoised functional
fslmaths structural.fast/structural_pve_2.nii.gz -thr 0.9 -ero -ero WMmask_eroded
flirt -in WMmask_eroded.nii.gz -applyxfm -init ../func/struc2func.mat -ref ../func/unsmoothed_aroma.nii.gz -out WMmask_func
fslmaths WMmask_func -mas ../func/meanresting_mcf.nii WMmask2_func
fslmeants -i ../func/unsmoothed_aroma.nii.gz -m WMmask2_func --no_bin -o WM.timeseries

# GM signal extraction - as above
fslmaths structural.fast/structural_pve_0.nii.gz -ero CSFmask_eroded
flirt -in CSFmask_eroded.nii.gz -applyxfm -init ../func/struc2func.mat -ref ../func/unsmoothed_aroma.nii.gz -out CSFmask_func
fslmaths CSFmask_func -mas ../func/meanresting_mcf.nii CSFmask2_func
fslmeants -i ../func/unsmoothed_aroma.nii.gz -m CSFmask2_func --no_bin -o CSF.timeseries

paste WM.timeseries CSF.timeseries > nuisance.timeseries

#regress these timeseries out
fslmaths rest.feat/ICA_AROMA/denoised_func_data_nonaggr.nii.gz -Tmean tempMean

fsl_glm -i rest.feat/ICA_AROMA/denoised_func_data_nonaggr.nii.gz -o confounds -d nuisance.timeseries --demean --out_res=residual

fslmaths residual -bptf $sigma -1 -add tempMean denoised_func_data

applywarp --ref=rest.feat/reg/standard --in=denoised_func_data --out=denoised_func_data_FSL --warp=rest.feat/reg/highres2standard_warp --premat=rest.feat/reg/example_func2highres.mat --interp=trilinear












WarpImageMultiTransform 3 WMmask_eroded.nii.gz WMmask_func.nii.gz -R meica_3TEs/mean_func.nii.gz -i func2struct/func2struct_Affine.txt

fslmaths WMmask_func -mas meica_3TEs/mean_func.nii.gz WMmask2_func

fslmeants -i meica_3TEs/rest_medn.nii.gz -m WMmask2_func --no_bin -o WM.timeseries

#CSF signal extraction
fslmaths structural.fast/structural_pve_0.nii.gz -thr 0.9 -ero CSFmask_eroded

WarpImageMultiTransform 3 CSFmask_eroded.nii.gz CSFmask_func.nii.gz -R meica_3TEs/mean_func.nii.gz -i func2struct/func2struct_Affine.txt

fslmaths CSFmask_func -mas meica_3TEs/mean_func.nii.gz CSFmask2_func

fslmeants -i meica_3TEs/rest_medn.nii.gz -m CSFmask2_func --no_bin -o CSF.timeseries

#Remove WM and CSF signal
paste WM.timeseries CSF.timeseries > nuisance.timeseries

fslmaths meica_3TEs/rest_medn.nii.gz -Tmean tempMean

fsl_glm -i meica_3TEs/rest_medn.nii.gz -o confounds -d nuisance.timeseries --demean --out_res=residual

fslmaths residual -bptf $sigma -1 -add tempMean denoised_func_data.nii.gz
