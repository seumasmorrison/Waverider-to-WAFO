# Waveider-to-WAFO
Two Matlab scripts written by David Christie (UHI) for processing Datawell buoy data for use in the Matlab toolbox WAFO 2.5 ( https://code.google.com/p/wafo/ )

Running get_file_list.m with the root directory of your buoy data and the buoy name will create a file_list.mat file lising the rawfiles for that buoy. The month_spec_params.m file reads file_list.m and creates a large mat file with output spectra and parameters for those raw files in file_list.m

get_file_list.m expects folder structure to be in the form buoy_name/year/month

month_spec_params outputs time steps based on the no_timestamps and startdate variables
