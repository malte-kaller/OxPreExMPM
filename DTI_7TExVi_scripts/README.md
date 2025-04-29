This repo contains all scripts to run the basic ex vivo diffusion-weighted MRI post-processing pipeline on data acquired at WIN's 7T Bruker facility.

This set of scripts, as it stands presently, can only be run on FMRIB's jalapeno cluster.

Guide on how to run and QC the pipeline: https://unioxfordnexus-my.sharepoint.com/:w:/r/personal/lina3298_ox_ac_uk/Documents/Tisca_VCAN_BCAN_project/MRI_Processing_Pipelines/BSB_exvivo_dMRI_pipeline.docx?d=w88fbd58084e64b54b41738b758b268a0&csf=1&web=1&e=lpb5PA

Cristiana Tisca
cristiana.tisca@linacre.ox.ac.uk
September 2021

################ NOTES

*Running topup
Note image dimensions need to be swapped for this step as our protocol has the phase encode direction in the z direction (superior-inferior direction). Topup has an inbuilt sanity check which does not allow us to specify that the phase encode direction is z, because in an in vivo human scan such an acquisition wouldn't be practical due to aliasing. The swapping step is done to bypass this check.

*Running bedpostX and NODDI
BedpostX and NODDI don't take jobids so they can only be run once previous jobs have finished.

*Running NODDI
Axial diffusivity (dax) value optimised in an iterative fashion on data acquired using our exvivo
dMRI protocols using NODDI, in combination with the spherical mean technique (SMT),#which generates voxel-wise estimates for axial diffusivitiy.
