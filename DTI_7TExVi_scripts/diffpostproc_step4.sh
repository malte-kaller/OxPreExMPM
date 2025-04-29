#!/bin/bash

inputfolder=$1

fslswapdim ${inputfolder}/topup_mouse_field_2b0 x -z y ${inputfolder}/topup_mouse_field_2b0_unswapped
fslswapdim ${inputfolder}/topup_mouse_unwarped_images_2b0 x -z y ${inputfolder}/topup_mouse_unwarped_images_2b0_unswapped
