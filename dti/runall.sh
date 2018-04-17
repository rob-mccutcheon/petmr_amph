#run as: bash runall.sh 12 (if e.g. you want to run 12 subjectss)



qsub -t 1-$1 mri.queue
sleep 2
qsub -t 1-$1 dti.queue
sleep 2
qsub -t 1-$1 fs.queue
sleep 2
qsub -hold_jid_ad mri_queue,dti_queue -t 1-$1 dtimri.queue
