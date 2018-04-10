# gets 1st argument from python and assigns it to data_dir
export data_dir=$1
export bids_id=$2
export dti_normal=$bids_id'_acq-normal_dwi.nii'
export dti_normal_bvec=$bids_id'_acq-normal_dwi.bvec'
export dti_normal_bval=$bids_id'_acq-normal_dwi.bval'
export dti_flipped=$bids_id'_acq-flipped_dwi.nii'
export dti_flipped_bvec=$bids_id'_acq-flipped_dwi.bvec'
export dti_flipped_bval=$bids_id'_acq-flipped_dwi.bval'
export structural=$bids_id'_T1w.nii'

cd $data_dir
# convert to mif
mrconvert $dti_flipped -fslgrad $dti_flipped_bvec $dti_flipped_bval flipped_dti.mif

#wait for dti.mif to be created by mri.sh
while [ ! -f dti.mif ]; do sleep 1; done

# denoise
dwidenoise dti.mif dti_denoised.mif -noise noise.mif

#Combine 2 B0s in opposite directions into one image
fslroi $dti_normal b0_dti.nii 0 1
fslroi $dti_flipped b0_flipped_dti.nii 0 1
fslmerge -t both_b0 b0_dti.nii.gz b0_flipped_dti.nii.gz

#preprocess
dwipreproc dti_denoised.mif dti_preprocessed.mif -rpe_pair -se_epi both_b0.nii.gz -pe_dir AP -cuda

#bias correct
dwibiascorrect dti_preprocessed.mif dti_bias_corrected.mif -ants

# Generate response function using the tournier algorithm, input is the dti.mif from previous step; output is response.txt
dwi2response tournier dti_bias_corrected.mif response.txt

#create mask
dwi2mask dti_bias_corrected.mif mask.mif

#perform csd
dwi2fod csd dti_bias_corrected.mif -mask mask.mif response.txt fod.mif
