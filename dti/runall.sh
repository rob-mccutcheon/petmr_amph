#run as: bash runall.sh 12 (if e.g. you want to run 12 subjectss)

qsub -t 1-$1 mri.queue
qsub -t 1-$1 dti.queue
qsub -t 1-$1 fs.queue
qsub -hold_jid_ad mri_queue,dti_queue -t 1-$1 dtimri.queue
