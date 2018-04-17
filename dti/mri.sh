# gets 1st argument from python and assigns it to data_dir
export data_dir=$1
export bids_id=$2
export dti_normal=$bids_id'_acq-normal_dwi.nii'
export dti_normal_bvec=$bids_id'_acq-normal_dwi.bvec'
export dti_normal_bval=$bids_id'_acq-normal_dwi.bval'
export structural=$bids_id'_T1w.nii'

cd $data_dir

# convert to mif
mrconvert $dti_normal -fslgrad $dti_normal_bvec $dti_normal_bval dti.mif
mrconvert $structural structural.mif

# Make dwi image to register to
dwiextract dti.mif -bzero - | mrcalc - 0.0 -max - | mrmath - mean -axis 3 dti_meanbzero.mif

# registration
mrconvert dti_meanbzero.mif dti_meanbzero.nii
antsRegistrationSyNQuick.sh -d 3 -f dti_meanbzero.nii -m $structural -t r -o ants1
antsApplyTransforms -d 3 -i $structural -r $structural -t ants10GenericAffine.mat -o structural_reg.nii -v

# segmentation
5ttgen fsl structural_reg.nii structural_reg_5tt.nii

### Uncomment if you wish to generate volumetric atlases
## normalisation of MNI template to subject dti-registered structural
#antsRegistrationSyNQuick.sh -d 3 -f structural_reg.nii -m ../../../atlases/mni_icbm152_t1_tal_nlin_sym_09a.nii -t s -o mni_ants
## apply transforms from previous step to your volumetric atlas of choice (e.g. AAL/Gordon )
#antsApplyTransforms -d 3 -v 1 -i ../../../atlases/aal.nii -o warped_atlas_label.nii -r structural_reg.nii -n NearestNeighbor -t mni_ants1Warp.nii.gz -t mni_ants0GenericAffine.mat
