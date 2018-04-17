# gets 1st argument from python and assigns it to data_dir
export data_dir=$1
export fs_dir=$2
export session_id=$3
cd $data_dir

# tckgen
#tckgen fod.mif tractogram.tck -algorithm ifod2 -act structural_reg_5tt.nii -backtrack -crop_at_gmwmi -cutoff 0.1 -maxlength 250 -select 1000000 -seed_dynamic fod.mif

#tcksift2
#tcksift2 tractogram.tck fod.mif weights.csv -act structural_reg_5tt.nii -out_mu mu.txt -fd_scale_gm

# Wait for freesurfer to generate atlases
while [ ! -f $fs_dir'/ses-'$session_id'/lausanne/ROIv_scale500.nii.gz' ]; do sleep 1; done

#connectome generation
resolutions='33 60 125 250 500'
for resolution in $resolutions
do
    tck2connectome tractogram.tck $fs_dir'/ses-'$session_id'/lausanne/ROIv_scale'$resolution'_thick.nii.gz' 'connectome'$resolution'.csv' -tck_weights_in weights.csv
done
