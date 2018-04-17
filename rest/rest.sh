#remove 4 epi vols

#slice timing
slicetimer -i sub-602_ses-A_task-rest_bold.nii -o resting_st.nii --odd -r 2

#motion correction
mcflirt -in resting_st.nii -o resting_mcf.nii -plots -mats

#average across time sries, brain extract and use this to mask full run
fslmaths resting_mcf.nii -Tmean meanresting_mcf.nii
bet meanresting_mcf.nii resting_bet.nii -f 0.3 -m -n -R
fslmaths resting_mcf.nii -mas resting_bet_mask resting_mcf_masked.nii

#wait for structural_reg
wait

#bet the structural aswell
cd ../anat
bet structural_reg.nii structural_reg_bet.nii -f 0.5 -m -R

#coregister the structural to mni
flirt -in structural_reg_bet.nii -ref /data/project/AMPH/rob/atlases/avg152T1_brain.nii.gz -out structural_reg_betMNI.nii  -dof 6 -omat strucmniaff.mat

#and apply the affine from this to the unbetted structural
flirt -in structural_reg.nii -ref /data/project/AMPH/rob/atlases/avg152T1_brain.nii.gz -applyxfm -init strucmniaff.mat -out structural_reg_MNIlinear.nii

# nonlinear registration of structural to mni
fnirt --in=structural_reg_MNIlinear.nii --config=T1_2_MNI152_2mm --fout=warp --iout=warpedstruc --verbose

#coregister the functional to the mni'd structural - consider using 'epireg
cd ../func
flirt -in resting_mcf_masked.nii -ref ../anat/structural_reg_betMNI.nii.nii -out resting_mcf_coreg.nii -omat affine.mat -dof 6
epi_reg --epi=resting_mcf_masked.nii --t1=structural_reg_MNIlinear --t1brain=../anat/structural_reg_betMNI.nii. --out=epi2struct

#smooth
# The gaussian kernel takes its argument as sigma instead of the FWHM,  to convert see
# http://mathworld.wolfram.com/GaussianFunction.html (FWHM = sigma*2.3548)
fslmaths resting_mcf_coreg.nii -kernel gauss 2.1233226 -fmean smoothed.nii



#get affine between coregistered and structural (should be practically nil)





#ica-aroma
python ICA_AROMA.py -in smoothed_resting.nii -out ICA_AROMA -affmat func2struc.mat -warp warp.nii -mc resting_mcf.nii.par
