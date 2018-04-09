# gets 1st argument from python and assigns it to data_dir
export data_dir=$1
cd $data_dir

# convert to mif
mrconvert dti.nii -fslgrad dti.bvec dti.bval dti.mif
mrconvert structural.nii structural.mif

# Make dwi image to register to
dwiextract dti.mif -bzero - | mrcalc - 0.0 -max - | mrmath - mean -axis 3 dti_meanbzero.mif

# registration
mrconvert dti_meanbzero.mif dti_meanbzero.nii
antsRegistrationSyNQuick.sh -d 3 -f dti_meanbzero.nii -m structural.nii -t r -o ants1
antsApplyTransforms -d 3 -i structural.nii -r structural.nii -t ants10GenericAffine.mat -o structural_reg.nii -v

# segmentation
5ttgen fsl structural_reg.nii structural_reg_5tt.nii

# normalisation of MNI template to subject dti-registered structural
antsRegistrationSyNQuick.sh -d 3 -f structural_reg_5tt.nii -m ../../../atlases/mni_icbm152_t1_tal_nlin_sym_09a.nii -t s -o mni_ants

# apply transforms from previous step to your atlas of choice (Gordon here)
antsApplyTransforms -d 3 -v 1 -i ../../../atlases/aal.nii -o warped_atlas_label.nii -r structural_reg.nii -n NearestNeighbor -t mni_ants1Warp.nii.gz -t mni_ants0GenericAffine.mat
