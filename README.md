# datawell_wafo_matlab
Two Matlab scripts written by David Christie (UHI) for processing Datawell buoy data for use in the Matlab toolbox WAFO 2.5

Running get_file_list.m with the root directory of your buoy data and the buoy name will create a file_list.mat file lising the rawfiles for that buoy. The monthly_stats.m file reads file_list.m and creates a large mat file with output spectra and parameters for those raw files in file_list.m
