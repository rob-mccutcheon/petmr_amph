# gets 1st argument from python and assigns it to data_dir
export data_dir=$1
cd $data_dir
pwd
# convert to mif
mrconvert flipped_dti.nii -fslgrad flipped_dti.bvec flipped_dti.bval flipped_dti.mif

#wait for dti.mif to be created by mri.sh
while [ ! -f dti.mif ]; do sleep 1; done

# denoise
dwidenoise dti.mif dti_denoised.mif -noise noise.mif

#Combine 2 B0s in opposite directions into one image
fslroi dti.nii b0_dti.nii 0 1
fslroi flipped_dti.nii b0_flipped_dti.nii 0 1
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
