from nilearn.connectome import ConnectivityMeasure
from nilearn import datasets
import numpy as np
import matplotlib.pyplot as plt
%matplotlib inline
import matplotlib.pyplot as plt

dataset = datasets.fetch_atlas_harvard_oxford('cort-maxprob-thr25-2mm')
atlas_filename = dataset.maps
labels = dataset.labels

print('Atlas ROIs are located in nifti image (4D) at: %s' %
      atlas_filename)  # 4D data

# One subject of resting-state data
data = datasets.fetch_adhd(n_subjects=1)
fmri_filenames = data.func[0]

from nilearn.input_data import NiftiLabelsMasker
masker = NiftiLabelsMasker(labels_img=atlas_filename, standardize=True,
                           memory='nilearn_cache', verbose=5)

# Here we go from nifti files to the signal time series in a numpy
# array. Note how we give confounds to be regressed out during signal
# extraction
time_series = masker.fit_transform(fmri_filenames, confounds=data.confounds)
time_series.shape

volumes, rois
fmri_filenames

time_series=np.loadtxt('/data/project/AMPH/rob/resting/sub-602/ses-A/func/roitimeseries')
time_series.shape
correlation_measure = ConnectivityMeasure(kind='correlation')
correlation_matrix = correlation_measure.fit_transform([time_series])[0]
np.fill_diagonal(correlation_matrix, 0)
from nilearn import plotting

atlas_filename='/data/project/AMPH/rob/resting/sub-602/ses-A/func/lausanne33.masked.nii.gz'
masker = NiftiLabelsMasker(labels_img=atlas_filename, standardize=True,memory='nilearn_cache', verbose=5)

labels=list(range(1,83))


plotting.plot_matrix(correlation_matrix)
plt.show()


plt.plot(range(100))
