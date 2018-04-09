# gets 1st argument from python and assigns it to data_dir
export data_dir=$1
cd $data_dir

# tckgen
tckgen fod.mif tractogram.tck -algorithm ifod2 -act structural_reg_5tt.nii -backtrack -crop_at_gmwmi -cutoff 0.1 -maxlength 250 -select 1000000 -seed_dynamic fod.mif

#tcksift2
tcksift2 tractogram.tck fod.mif weights.csv -act structural_reg_5tt.nii -out_mu mu.txt -fd_scale_gm

#connectom generation
tck2connectome tractogram.tck warped_atlas_label.nii connectome.csv -tck_weights_in weights.csv
