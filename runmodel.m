function data = runmodel(varargin)
% RUNMODEL program to exceucte thermal model using Excel input file.
%__________________________________________________________________________
% SYNTAX:
%   data = runmodel;
%   data = runmodel(filename);
%   data = runmodel(filename,name);
%   data = runmodel(filename,name,desc);
%   data = runmodel(...,[B,N]);
%
% DESCRIPTION:
%   data = runmodel executes the thermal model via Excel input, prompting 
%       the user for a filename.
%   data = runmodel(filename) executes the thermal model for supplied name.
%   data = runmodel(filename,name) same as above, but allows the user to
%       name the run (e.g. name = 'Model Run #3');
%   data = runmodel(filename,name,desc) same as above, but allows user to
%       also add a description to the run (e.g. desc = 'This run mimics 
%       Feb-14-2008 at the South station of the YC';)
%   data = runmodel(filename,name,desc,[B,N]) runs the model and 
%       computes the bootstrap confidence intervals, where B = number
%       of resamplings, N = number of standard deviations to assume for 
%       the tails
%
% OUTPUT:
% The data structure has the following fieldnames
%          xls: Input Excel filename
% bootsettings: Bootstrap settings
%         name: Name of current run
%         desc: Description of the current run
%         time: Start time of model execution
%            T: Array of snowpack temperatures 
%            Q: Array of snowpack heat fluxes
%          snw: Input array of snow properties 
%          atm: Input array of atmospheric conditions
%        const: Array of model constants
%        Tboot: Bootstrap replicates of temperature
%        Qboot: Bootstrap replicates of heat fluxes
%        Sboot: Bootstrap replicates of snw inputs
%        Aboot: Bootstrap replicates of atm inputs
%        Cboot: Bootstrap replicates of const inputs
%__________________________________________________________________________

% 1 - GATHER OPTIONS
    data = getoptions(varargin{:});

% 2 - EXECUTE MODEL
    [S,A,data.const] = xls_input(data.xls);
    [data.snw,data.atm] = xls_prep(S,A,data.const);
    [data.T,data.Q] = thermal(data.snw,data.atm,data.const);
    
% 3 - RUN THE BOOSTRAP
    if ~isempty(data.bootsettings);
        B = data.bootsettings;
        bootdata = confint(data.xls,B(1),B(2));
        fn = fieldnames(bootdata);
        for i = 1:length(fn);
            data.(fn{i}) = bootdata.(fn{i});
        end
    end  
    
%--------------------------------------------------------------------------    
function [data,B] = getoptions(varargin)
% GETOPTIONS determines/sets the input options

% 1 - SET THE DEFAULTS
    filename = '';
    name = '';
    desc = '';
    B = [];
    
% 2 - GATHER BOOTSTRAPPING DATA
    idx = [];
    for i = 1:nargin; idx(i) = isnumeric(varargin{i}); end
    ix = find(idx,1,'first');
    if ~isempty(ix); B = varargin{ix}; end
    
% 3 - GATHER FILENAME, NAME, AND DESCRIPTION..
    if isempty(B); rem = varargin; else rem = varargin(1:nargin-1); end
    if length(rem) >= 1; filename = varargin{1}; end
    if length(rem) >= 2; name = varargin{2}; end
    if length(rem) == 3; desc = varargin{3}; end      
    
% 4 - PROMPT FOR FILENAME   
    % 4.1 - Gather/define the "lastdir" preference
        if ispref('ThermalModel_v5','lastdir'); 
            defdir = getpref('ThermalModel_v5','lastdir'); 
        else
            addpref('ThermalModel_v5','lastdir',cd); 
            defdir = cd;
        end
        
    % 4.2 - Prompt the user for a filename   
        if isempty(filename) ;
            FilterSpec = {'*.xlsx','Excel Workbook (*.xlsx)';...
                '*.xls','Excel 97-2003 Workbook (*.xls)';...
                '*.*','All files (*.*)'};
            [fn,pth] = uigetfile(FilterSpec,'Select file...',defdir);
            if isnumeric(fn); return; end
            filename = [pth,fn];
            setpref('ThermalModel_v5','lastdir',fileparts(filename)); 
        end

% 5 - BUILD DATA STRUCTURE   
    % 5.1 - File information
        data.xls = filename;
        data.bootsettings = B;
        data.name = name;
        data.desc = desc;
        data.time = datestr(now);
        
    % 5.2 - Model evaluation    
        data.T = []; data.Q = [];
        data.snw = []; data.atm = []; data.const = [];
    
    % 5.3 - Bootstrap results    
        data.Tboot = []; data.Qboot = [];
        data.Sboot = []; data.Aboot = []; data.Cboot = [];
    