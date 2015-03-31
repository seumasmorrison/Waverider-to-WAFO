% Matlab script written by David Christie ( UHI ) for processing raw files from 
% Datawell Waverider MKII/MKII buoys used in conjunction with the accompanying 
% get_file_list.m to select files for processing.
 

list_exists = 1;
% remove_whole_files = true;
remove_single = true;
interp_rate = 20;
sample_freq = 1.28;


% method = 0 max(Vcf, Vcb) and corresponding wave height Hd or Hu in H
%    1 crest front (rise) speed (Vcf) in S and wave height Hd in H. (default)
%   -1 crest back (fall) speed (Vcb) in S and waveheight Hu in H.
%    2 crest front steepness in S and the wave height Hd in H.
%   -2 crest back steepness in S and the wave height Hu in H.
%    3 total wave steepness in S and the wave height Hd in H
%      for zero-downcrossing waves.
%   -3 total wave steepness in S and the wave height Hu in H.
%      for zero-upcrossing waves.
method = 2;

num_months = 12;
startmonth = 1;

file_fraction = 0.9; %fraction of .raw file which needs to be present.
flag_threshold = 0.2; %fraction of error flags not to be exceeded
%start_set = 7.3509e+05;

%number_half_hours = 17520;
g = 9.81;
% Get list of dates and filenames
try load('Siad_list');
catch
    get_file_list;
end

date_vec_list = datevec(date_list_ordered);


for month = startmonth:(startmonth+num_months-1);
    
    dates_selected = date_vec_list(:,2) == month;
    num_files = sum(dates_selected);
    
    t_axis = date_list_ordered(dates_selected);
    
    files_selected = file_list_ordered(dates_selected);


    noflags = true(1,num_files); % files with no error flags at all
    used = true(1,num_files); % files long enough and with certain max fraction of errors
   
    noflags = true(1,num_files); % files with no error flags at all
    used = true(1,num_files); % files long enough and with certain max fraction of errors

    individual_S_H_Ac_At_Tcf_Tcb = cell(num_files,1);
    Hm0_Tm01_Tm02_Te = zeros(num_files,4);
    S_rms = zeros(num_files,1);
    H_rms = zeros(num_files,1);


    for file_load = 1:num_files
        
        
    %     First, is the file readable (eg no missing stuff)
        try file_data = csvread(char(files_selected(file_load)));
        catch
            used(file_load) = false;
        end
        
        %     Read the file, check it's long enough, check not too many flags
        %        only use if long enough
        used(file_load) = used(file_load) & size(file_data,1)>30*file_fraction/sample_freq;
        
        flag_fraction = sum(file_data(:,1)>1) / size(file_data,1);       
        %        only use if not too many flags
        used(file_load) = used(file_load) & flag_fraction < flag_threshold;

        
        if  used(file_load) 
            heave = double(file_data(:,2))/100; 
            flags = single(file_data(:,1));
            time = (0:(length(heave)-1))/sample_freq;

    %         Wave steepnesses etc.....
            if interp_rate == 1
                [S, H,Ac,At,Tcf,Tcb, z_ind] = dat2steep([time',heave],interp_rate,2);
                yn = heave;
            else
                [S, H,Ac,At,Tcf,Tcb, z_ind, yn] = dat2steep([time',heave],interp_rate,2);
            end;

            numwaves = length(S);  

            goodwaves = true(numwaves,1);
    %         For each flag, find index in interpolated file, and label the wave
    %         which contains this index
            if remove_single && sum(flags)>0
            bad_loc_set =  find(flags)*interp_rate;
            else
                bad_loc_set = [];
            end
            % get the downcross indices
            if yn(z_ind(1)+1,2)< yn(z_ind(1),2); % is the first index a down or up?
                downcross_inds = z_ind(1:2:2*numwaves-1);
            else
                downcross_inds = z_ind(2:2:2*numwaves);
            end
            
            use_for_spectra = true(size(yn));


             for badindex = bad_loc_set'
                downcross_ind_before_flag = find(downcross_inds <= badindex,1,'last'); 
    %            This returns the index of the last downcrossing before the
    %            flag in question
                downcross_loc_before_flag = downcross_inds(downcross_ind_before_flag);
                downcross_ind_after_flag = find(downcross_inds > badindex,1,'first'); 
                downcross_loc_after_flag = downcross_inds(downcross_ind_after_flag);       
                
                if ~isempty(downcross_ind_before_flag)
                    goodwaves(downcross_ind_before_flag) = false;
                    use_for_spectra(downcross_loc_before_flag:(downcross_loc_after_flag-1))=false;
                end
             end
            end
            
  

    % steepness and crest amplitude
    S_rms(file_load,1) = rms(S(goodwaves));
    H_rms(file_load,1) = rms(H(goodwaves));  % can also be called etaprime
    
    collected_measurements = [S, H,Tcf,Tcb];
    individual_S_H_Ac_At_Tcf_Tcb{file_load,1} = collected_measurements(goodwaves);

    % spectral quantities
   
    spectime = (0:(size( yn(use_for_spectra))-1))/(interp_rate*sample_freq);
    
    
    specfromheave = dat2spec([yn(use_for_spectra),spectime']);
    Hm0_Tm01_Tm02_Te(file_load,:) = spec2char(specfromheave,[1 2 3 5],spectime(end));
        
        


        end
       Hm0_Tm01_Tm02_Te = Hm0_Tm01_Tm02_Te(used,:);
       S_rms = S_rms(used,:);
       H_rms = H_rms(used,:);
       individual_S_H_Ac_At_Tcf_Tcb = individual_S_H_Ac_At_Tcf_Tcb(used',:);
       
 
       time_axis = datestr(t_axis(used,:));
       
       fname = ['typeA_method',num2str(method),'_month',num2str(month)];
       save(fname,'Hm0_Tm01_Tm02_Te','S_rms','H_rms','individual_S_H_Ac_At_Tcf_Tcb','time_axis');
       

    


    end



