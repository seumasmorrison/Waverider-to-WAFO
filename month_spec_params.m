
% Matlab script written by David Christie ( UHI ) for processing raw files from 
% Datawell Waverider MKII/MKII buoys used in conjunction with the accompanying 
% get_file_list.m to select files for processing.

directory_name = 'D:\output\';
fclose('all');
 
list_exists = 1;
sample_freq = 1.28;
sample_T = 1/sample_freq;
g = 9.81;
base_filename = 'full2012_1_';
 
nd_param_key{1} = 'Hm0 Significant wave height';
nd_param_key{2} = 'Tm01 Mean wave period';
nd_param_key{3} = 'Tm02 Mean zero-crossing period';
nd_param_key{4} = 'Tm_10 Energy period';
nd_param_key{5} = 'Tp Peak period';
nd_param_key{6} = 'Tp1 Peak Period (robust estimate';
 
d_param_key{1} = 'TpMdir Mean wave direction at the spectral peak';
d_param_key{2} = 'TpSpr Directional Spread of TpMdir';
 
% WAFO setup
h = 65; % water depth for Siadar buoy
nfft = 232;
nt = 91;
nf = nfft/2+1; % number of frequencies (from nfft)
 
 
posv = zeros(3,3);
% WAFO's angular convention is 0 at x-axis; pi/2 at y-axis.  So the buoy's
% N corresponds with x, and E (ie -W) corresponds with y.  
typesv = [18 16 17]; % ie [Z_p, X_p, Y_p].  
bfsvH = [1 0 0]; 
wafo_settings = [posv,typesv',bfsvH'];
spec_method = 'EMEM';
 
% Quality thresholds
file_fraction = 0.9; %min fraction of .raw file present for "good file"
flag_threshold = 0.2; %max fraction of error flags for "good file"
 
% Get list of dates and filenames
if list_exists 
    load('D:\input\file_list.mat');
else
    get_file_list;
end
 
 
% Time period to be written to dfs2 file (all of 2012)
no_timesteps = 48*366; % Leap year
startdate = [2012 1 1 0 0 0];
timeline = zeros(no_timesteps,1);
 
% Spectral quantities to compare
nd_params_1dspec = zeros(no_timesteps,6);    
nd_params_2dspec = zeros(no_timesteps,6);
d_params = zeros(no_timesteps,2);
include_step = true(no_timesteps,1);
 
% Sensitivity (how close should timestamps of spt and dfs2 files be?)
t_sensitivity = 10^(-4);
 
missing = [];
incomplete = [];
toomany_flags = [];
any_flags = [];
unreadable = [];
wrongsize = [];
allrejects = [];
 
for step = 1:no_timesteps
    m21_step = step-1;    % dfs2 steps go from zero
    
    % find the point in the date index corresponding to the timestep we
    % want to write (IF it exists)
    stepdate = datenum(startdate + 30*[0 0 0 0 m21_step 0]);
    raw_date_loc = find(abs(date_list_ordered - stepdate) < t_sensitivity);
    timeline(step) = stepdate;
    % No ambiguity in step (as some near duplicate files sneaked in)
    assert(length(raw_date_loc)<= 1,'Duplicate step!');
    
    % If you can't find the step, add it to the "missing" list.  If you
    % can, calculate the directional spectrum from the parameters.
    if isempty(raw_date_loc)
%        fprintf(missing_steps,'%s missing\n',datestr(stepdate));
       missing = vertcat(missing,stepdate);
       allrejects = vertcat(allrejects,stepdate);
    else 
        % Read data from file.  Reject file if unreadable.
        currentfile = char(file_list_ordered(raw_date_loc));
        try file_data = csvread(currentfile);  
            data_OK = true;
        catch
            data_OK = false;
            %fprintf(missing_steps,'%s unreadable\n',datestr(stepdate));
            unreadable = vertcat(unreadable,stepdate);
            allrejects = vertcat(allrejects,stepdate);
        end
                   
        if data_OK
            if size(file_data,1)<sample_T*30*60*file_fraction
                data_OK = false;
                %fprintf(missing_steps,'%s incomplete\n',datestr(stepdate));
                incomplete = vertcat(incomplete,stepdate);
                allrejects = vertcat(allrejects,stepdate);
            end
            flags = sum(file_data(:,1)>1);
            flag_fraction = flags/size(file_data,1);
            if flag_fraction > flag_threshold
                data_OK = false;
                %fprintf(missing_steps,'%s %f flag ratio\n',datestr(stepdate),flag_fraction);
                toomany_flags = vertcat(toomany_flags,[stepdate flags]);
                allrejects = vertcat(allrejects,stepdate);
            end
            
            if flags>0
                any_flags = vertcat(any_flags,[stepdate flags]);
            end
        end
 
 
            % Generate spectrum: last chance to reject unsuitable file (wrong
            % size)
        if data_OK
            hnw_raw = double(file_data(:,2:4))/100;
            notflagged = file_data(:,1)<=1;  % flag of zero or one is OK, reject the rest
            hnw = hnw_raw(notflagged,:);
            hnw(:,3) = -hnw(:,3); % WAFO x-axis is east, not west
            newfname = ['F:\wafo_filtered\', currentfile(end-39:end)];
            dummy_flags = zeros(size(hnw,1),1);
            new_filedata = [dummy_flags hnw];
            
            dlmwrite(newfname, new_filedata);
            time = (0:(size(hnw,1)-1))'/sample_freq;
            %S2 = dat2dspec([time hnw],wafo_settings,65,nfft,nt,spec_method,...
            %     'ftype','f','bet',-1); % setting bet to -1 := "travelling from"
            %S1 = dat2spec([time,hnw(:,1)]);
            
            %nd_params_1dspec(step,:) = spec2char(S1,[1 2 3 5 6 11]);            
            %nd_params_2dspec(step,:) = spec2char(S2,[1 2 3 5 6 11]);
            %d_params(step,:) = spec2char(S2,[11 12]);
 
           
            %if all(size(S2.S) ~= [nt,nf])
            %    %fprintf(missing_steps,'%s wrong size spectrum\n',datestr(stepdate));
            %    wrongsize = vertcat(wrongsize,stepdate);
            %    allrejects = vertcat(allrejects,stepdate);
            % If the resulting spectral matrix is too small, then reject.
            %end
        end
        include_step(step) = data_OK;
    end
 
	    
	%     Write dfs2 timestep (either the one obtained from the collected
	%     spectral file, or a duplicate of the previous one
 
 
 
		
end
 
% fclose(missing_steps);
% dfs2.Close();
% 
% error_filename = [base_filename,spec_method,'errors.txt'];
% save(error_filename, 'missing','incomplete','toomany_flags',...
%     'any_flags','unreadable','wrongsize','allrejects');
 
dates = datestr(timeline(include_step));
nd_params_1dspec = nd_params_1dspec(include_step,:);     
nd_params_2dspec = nd_params_2dspec(include_step,:);
d_params = d_params(include_step,:);
 
error_collection{1} = missing;
error_collection{2} = incomplete;
error_collection{3} = toomany_flags;
error_collection{4} = any_flags;
error_collection{5} = unreadable;
error_collection{6} = wrongsize;
 
error_labels = {'missing'; 'incomplete'; 'toomany_flags'; 'any_flags'; 'unreadable';...
	'wrongsize'; 'allrejects'};
 
save(base_filename,'dates','nd_params_1dspec','nd_params_2dspec',...
	'd_params','nd_param_key','d_param_key','error_labels','error_collection');
