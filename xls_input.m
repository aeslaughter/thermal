function [S,A,C,E] = xls_input(filename)
% XLS_INPUT builds input matrics for usage with the thermal model (v5).
%__________________________________________________________________________
% SYNTAX: 
%   [S,A,C,E] = xls_input(filename)
%__________________________________________________________________________

% 1 - CHECK FILE
    if nargin == 0; filename = 'template.xlsx'; end
    if ~exist(filename,'file'); 
        errordlg('File does not exist!'); return; 
    end;
      
% 2 - EXTRACT DATA FROM FILE
    % 2.1 - Read files
        [S,snwTXT] = xlsread(filename,'SnowProperties');
        [A,atmTXT] = xlsread(filename,'AtmosphericSettings');    
        [const] = xlsread(filename,'Constants');
        
    % 2.2 - Seperate constants and multipliers
        C = const(1:10);
        M = const(11:length(const),1); M(isnan(M)) = 0;
        aM = M(1:10); % atmospheric multipliers
        sM = M(11:length(M)); % snow multipliers
        
    % 2.3 - Seperate percent error values
        Nc = size(const,2);
        if Nc == 1; 
            E.atm = zeros(length(aM),1);  E.atm(:,1) = 0.05; 
            E.snow = zeros(length(sM),1); E.snw(:,1) = 0.05; 
            E.const = zeros(10,1);
        else
            E.atm = const(11:length(aM)+10,2)/100;
            E.snow = const(length(aM)+11:length(const),2)/100;
            E.const = const(1:10,2)/100;
        end

 % 3 - APPLY SPECIAL VALUES 
    % 3.1 - Compute the albedo based on snow type 
        A = albedo(A,atmTXT,S);
        
    % 3.2 -Adjust snow properties
        S = extinction(S,snwTXT);
        S = density(S,snwTXT);
        S = definefunctions(S,snwTXT,C(10),A(end,1));
   
 % 4 - APPLY MULTIPLERS
    % 4.1 - Re-size multipliers arrays to necessary size
        aM = [1;aM(1:size(A,2)-1)]; % 1 adds a column for time
        sM = [1;sM(1:size(S,2)-1)]; % 1 adds a column for the depth
        
    % 4.2 - Apply multipliers
        for i = 1:length(sM); S(:,i) = S(:,i) * sM(i); end
        for i = 1:length(aM); A(:,i) = A(:,i) * aM(i); end    

%--------------------------------------------------------------------------     
function A = albedo(A,atmTXT,S)
% ALBEDO applies special input into albedo column: dXX, classX, <type>  
% Special values given in the albedo column (#4) assume that the shortwave
% column (3) is an all-wave value, so it is divided into a VIS/NIR
% components as is the albedo for all "special" cases

% 1 - Determine "special" locations
    idx = find(isnan(A(:,4)));
    
% 2 - Cycle through each special value and compute desired albedos
for i = 1:length(idx);
    val = atmTXT{idx(i)+3,4}; % Current special case
    
    % Optical depth case: dXX
    if strcmpi('d',val(1)); % Optical depth caer
        dopt = str2double(val(2:length(val)));
        if isnan(dopt); 
            error('xls_input:albedo','optical depth ill define.'); 
        end
        [A(idx(i),4),b1,A(idx(i),11)] = rad_calc(dopt,S(1,2));
    
    % Class case: classX    
    elseif length(val) > 5 && strcmpi('class',val(1:5));
        cls = str2double(val(6:length(val)));
        if isnan(cls); 
            error('xls_input:albedo','class ill define.'); 
        end
        [A(idx(i),4),b1,A(idx(i),11)] = rad_calc('class',cls);
        
    % Cuvre case: 'fine','medium','coarse'
    elseif sum(strcmpi(val,{'fine','medium','coarse'})) == 1;
        [A(idx(i),4),A(idx(i),11)] = rad_calc(val);
        
    % Record an error    
    else
        error('xls_input:albedo','error with albedo input, colum 4!');
    end
    
    % Redifine all-wave shortwave to VIS/NIR components    
        [A(idx(i),3),A(idx(i),10)] = rad_calc(A(idx(i),3));
end
        
%--------------------------------------------------------------------------
function [S,snwTXT] = definefunctions(S,snwTXT,dt,tf)
% DEFINEFUNCTIONS applies time equations to the snow variables

% 1 - Initilize parameters
    t = 0:(dt/3600):tf;              % Time array in hours
    func = false;                    % Trigger for using full time array
    SNW = repmat(S,[1,1,length(t)]); % Intilize the time based array

% 2 - Search the data and apply time based functions for snow
for i = [3,6:size(S,2)]; % Conductivity and extinction coeff.
    for j = 1:size(S,1); % Loop through each item in column
        if isnan(S(j,i)); % If NaN, evaluat the function
            try
                SNW(i,j,:) = eval([snwTXT{j+3,i},';']);
                func = true;
            catch ME
                error('xls_input:definefunctions',...
                    'snow property time function failed.'); 
            end
        end    
    end
end

% 3 - If a time function was used, the full time based array is returned
if func; S = SNW; end

%--------------------------------------------------------------------------     
function S = extinction(S,snwTXT)
% EXTINCTION applies special input for extinction column: dXX or classX 
% Special values given in the extection column (#6) overwrite VIS/NIR
% columns with the desired numeric value

% 1 - Determine "special" locations
    if size(S,2) == 5; S(:,6) = NaN(size(S,1),1); end
    idx = find(isnan(S(:,6)));
    
% 2 - Cycle through each special value and compute desired albedos
for i = 1:length(idx);
    val = snwTXT{idx(i)+3,6}; % Current special case
    
    % Optical depth case: dXX
    if strcmpi('d',val(1)); % Optical depth caer
        dopt = str2double(val(2:length(val)));
        if isnan(dopt); 
            error('xls_input:extinction','optical depth ill define.'); 
        end
        [~,S(idx(i),6),~,S(idx(i),7)] = rad_calc(dopt,S(1,2));
    
    % Class case: classX    
    elseif length(val) > 5 && strcmpi('class',val(1:5));
        cls = str2double(val(6:length(val)));
        if isnan(cls); 
            error('xls_input:extinction','class ill define.'); 
        end
        [~,S(idx(i),6),~,S(idx(i),7)] = rad_calc('class',cls);
        
    % Record an error    
    else
        error('xls_input:albedo','error with albedo input, colum 4!');
    end
end

%--------------------------------------------------------------------------     
function S = density(S,snwTXT)
% DENSITY applies special input for density and/or thermal conductivity 
% columns, either can be 'auto', just not both. The auto values are
% replaced it the appopriate value from Sturm, 1997.  The quadratic is used
% for solving for k and the exponential when solving for density

for i = 1:size(S,1);
    rho = S(i,2)/1000; k = S(i,3);
    
    % Case when both rho and k are defined with numbers
    if isnumeric(rho) && isnumeric(k) && ~isnan(rho) && ~isnan(k); 
        S(i,2) = rho*1000; S(i,3) = k;
        
    % Case when the density is computed
    elseif isnan(rho) && isnumeric(k) && strcmpi(snwTXT{i+3,2},'auto');
        S(i,2) = (log10(k) + 1.652) / 2.65 * 1000;
        
    % Case when thermal conductivity is computed   
    elseif isnumeric(rho) && isnan(k) && strcmpi(snwTXT{i+3,3},'auto');
        if rho < 0.156;
            S(i,3) = 0.023 + 0.234 * rho;
        else
            S(i,3) = 0.138 - 1.01*rho + 3.233 * rho^2;
        end
        
%     % Failure
%     else
%         error('xls_input:density',...
%             'error with density/conductivity input, column 2 and/or 3!');
    end
end
