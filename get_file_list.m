% A script for selecting the buoy data to be batch processed in WAFO written by
% David Christie

base_direc = 'D:\Buoy_Data';
buoy_name = 'Buoy_Name';
bns = length(buoy_name);
buoy_dir = [base_direc,'\',buoy_name,'\'];
 
 
full_file_list = [];
full_time_list = [];
 
year_list = dir([buoy_dir,'20*']);
num_years = size(year_list,1);
for year_no = 1:num_years
    yeardir = [buoy_dir,year_list(year_no).name,'\'];
    month_list = dir(yeardir);
    month_list = month_list(3:end);
    num_months = size(month_list,1);
    for monthno = 1:num_months
            
%         Get directory name, and list of files.  Horizontally concatenate copies of 
%         directory name to the file list so that each file path is fully
%         described.  Vertically concatenate with previous file list.
        monthdir = [yeardir,month_list(monthno).name,'\'];
        disp(monthdir);
        filelist = ls([monthdir,'*}*.raw']);
        file_chunk = [repmat(monthdir,size(filelist,1),1),filelist];
        
        full_file_list = [full_file_list;cellstr(file_chunk)];
        
%         Get date number corresponding to each file and vertically
%         concatenate with previous date list.
        yr = str2num(filelist(:,bns+2:bns+5));
        mth = str2num(filelist(:,bns+7:bns+8));
        day = str2num(filelist(:,bns+10:bns+11));
        hour = str2num(filelist(:,bns+13:bns+14));
        min = str2num(filelist(:,bns+16:bns+17));
        sec = zeros(size(min));
        
        full_time_list = [full_time_list;datenum([yr,mth,day,hour,min,sec])];
        end
        
 
end
[date_list_ordered,perm] = sort(full_time_list);
file_list_ordered = full_file_list(perm,:);
 
save('Siad_list','file_list_ordered','date_list_ordered');
