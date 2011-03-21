function [s,a] = xls_prep(snow,atm,constants)
% XLS_PREP builds arrays for inputing into thermal model
%__________________________________________________________________________
% SYNTAX:
%   [snow,atm] = prep_input(snow,atm,constants);
%
% INPUT: 
%   snow      = matrix containing snow data
%   atm       = matrix containing atmospheric data
%   constants = matrix containing model constants 
%
% EXAMPLE INPUT:
%   snow     = [50,130,0.06,2030,-10,70];
%   atm      = [6,240,500,0.82,1.7,-10,.2,-10,101];
%   contants = [2833,0.0023,0.0023,0.622,0.462,-5,0.402,0.95,1,60,1];
%__________________________________________________________________________

% 1 - Fill in atmospheric data  
    atm(:,1) = atm(:,1) .* 3600; % Convert time to seconds   
    dt = constants(10);          % Time step in seconds
    a  = fill_array(atm,dt);

% 2 - Fill and snow properties data
    dz = constants(9);
    s = fill_array(snow,dz);

%--------------------------------------------------------------------------
% SUBFUCTION: fill_array
function out = fill_array(in,int)
% FILL_ARRAY builds an array from "in" using the interval in "int" based on
% the first column of data

% 1 - Build array for case when data is only a single row (constant data)
    len = size(in,1);
    if len == 1;
        in(2,:) = in(1,:);
        in(1,1) = 0;
    end

% 2 - Build new array with spacing based on "int"
    % 2.1 - Build the first column of the new array (e.g. time steps)
        n = size(in,1);
        xi = (in(1,1):int:in(n,1))';

    % 2.2 - Interpolate the remaining data based on the first column
        x = in(:,1);
        Y = in(:,2:size(in,2));
        yi = interp1(x,Y,xi,'linear');
        out = [xi,yi];
