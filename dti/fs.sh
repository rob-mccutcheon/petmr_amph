
export SUBJECTS_DIR=$1 #this is the freesurfer analysis directory
export subject_id=sub-$2
export session_id=ses-$3
export bids_id=$4
export orig_data_dir=$5
export struc_dir="/data/project/AMPH/rob/dti"

cd $SUBJECTS_DIR/..

#wait for structural_reg to be created by mri.sh
while [ ! -f $struc_dir/$subject_id/$session_id/'structural_reg.nii' ]; do sleep 1; done

#run freesurfer recon-all on structural registred to B0s
recon-all -sd $subject_id -s $session_id -i $struc_dir/$subject_id/$session_id/'structural_reg.nii' -all

#run easy_lausanne (needs python2, fsl 5.0.9, freesurfer6.0.0)
mkdir $SUBJECTS_DIR/$session_id/'lausanne'
source activate python2
easy_lausanne\
    --subject_id $session_id \
    --target_volume /data/project/AMPH/rob/dti/$subject_id/$session_id/dti_meanbzero.nii \
    --target_type diffusion \
    --output_dir $SUBJECTS_DIR/$session_id/lausanne \
    --include500

#dilate easy_lausanne atlases
resolutions='33 60 125 250 500'
for resolution in $resolutions
do
    atlas_dilate 'ROIv_scale'$resolution'.nii.gz' 'ROIv_scale'$resolution'_thick.nii.gz'
done
