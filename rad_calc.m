function varargout = rad_calc(varargin)
% RAD_CALC spectral calculations of radiation, albedo, and extiction.
%__________________________________________________________________________
% SYNTAX:
%   [SWvis,SWnir,SWswir] = rad_calc(SWall);
%   [Avis,Anir,Aswir] = rad_calc(curve);
%   [Avis,Bvis,Anir,Bvis,Aswir,Bswir] = rad_calc(dopt,rho);
%   [Avis,Bvis,Anir,Bvis,Aswir,Bswir] = rad_calc('class',num);
%
% DESCRIPTION:
%   [SWvis,SWnir,SWswir] = rad_calc(SWall) computes spectral components of
%       all-wave shortwave radiation based on ASTM standard.
%   [Avis,Anir,Aswir] = rad_calc(curve) computes spectral albedo components
%       based on curves: 'fine','medium','coarse'
%   [Avis,Bvis,Anir,Bvis,Aswir,Bswir] = rad_calc(dopt,rho) computes
%       spectral components of albedo and extiction based on Snow & Climate
%       equations given on p.56.
%   [Avis,Bvis,Anir,Bvis,Aswir,Bswir] = rad_calc('class',num) computes
%       spectral components of albedo and extiction based on Snow & Climate
%       table given on p.57, where num must be an integer between 1 and 6.
%__________________________________________________________________________

% 1 - Compute desired values, execute as order in SYNTAX/DESCRIPTION above
    if nargin == 1 && isnumeric(varargin{1});
        output = shortwave(varargin{1});
    elseif nargin == 1 && ischar(varargin{1});
        output = albedo_curve(varargin{1});
    elseif nargin == 2 && isnumeric(varargin{1});
        output = albedo_eqn(varargin{:});
    elseif nargin == 2 && ischar(varargin{1});
        output = albedo_table(varargin{2});
    end
 
% 2 - Produce output
    varargout = num2cell(output);

%--------------------------------------------------------------------------
function out = albedo_table(N)
% ALBEDO_TABLE computes albedo and exciction base on Snow&Climate(p.57)

% Error handling
    if N < 1 || N > 6;
        error('Class must be an interger 1 through 6!'); out = NaN; return; 
    end

% Build Table 2.6 from Snow & Climate (2008), p.57
    C(:,1) = [94,94,93,93,92,91]/100;
    C(1:6,2) = 40;
    C(:,3) = [80,73,68,64,57,42]/100;
    C(:,4) = [110,136,190,110,112,127];
    C(:,5) = [59,49,42,37,30,18]/100;
    C(1:6,6) = inf;
    
 % Produce output
    out = C(N,:);

%--------------------------------------------------------------------------
function out = albedo_eqn(dopt,rho)
% ALBEDO_EQN computes albedo and exciction base on Snow&Climate(p.56)

% Convert units (dopt mm->m; rho kg/m^3->gm/cm^3)
    dopt = dopt/1000; rho = rho/1000;

% VIS
    out(1) = min(0.94,0.96 - 1.58*sqrt(dopt));
    out(2) = max(0.04, 0.0192*rho/sqrt(dopt))*100;
   
% NIR    
    out(3) = 0.95 - 15.4 * sqrt(dopt);
    out(4) = max(1, 0.1098*rho/sqrt(dopt))*100;
    
% SWIR    
    out(5) = 0.88 + 346.6*dopt - 32.31*sqrt(dopt);
    out(6) = inf;

%--------------------------------------------------------------------------
function Aout = albedo_curve(curve)
% ALBEDO_CURVE computes VIS,NIR,& SWIR albedos based on input curve

% 1 - Load the desired curve
    X = load('albedo.mat');
    A = X.(curve); 
    
% 2 - Parse out the albedo for each wavelength group
    L = [285,800; 800,1500; 1500,3500];
    for i = 1:size(L,1); 
        idx(1) = find(A(:,1)>=L(i,1),1,'first');
        idx(2) = find(A(:,1)<=L(i,2),1,'last');
        Aout(i) = mean(A(idx(1):idx(2),2))/100;
    end

%--------------------------------------------------------------------------
function SWout = shortwave(SWall)
% SHORTWAVE computes spectral components of all-wave based on ASTM standard

% 1 - Load the solar spectrum desired
    X = load('albedo.mat');
    S = X.astm; 

% 2 - Normalize solar spectrum to inputed SW data
    I = insolation(S,[285,3500]); 
    S(:,2) = (S(:,2)/I)*SWall;

% 3 - Parse out wavelength groups
    L = [285,800; 800,1500; 1500,3500];     
    for i = 1:size(L,1); SWout(i) = insolation(S,L(i,:)); end
      
%--------------------------------------------------------------------------
function I = insolation(S,L)
% POWER computers the insolation between the a and b wavelenghts

% 1 - Locate indicies of wavelenghts
    x = S(:,1); y = S(:,2);
    i(1) = find(x>L(1),1,'first');
    i(2) = find(x<L(2),1,'last');
    idx = i(1):i(2);

% 2 - Compute the insolation    
    I = sum((y(i(1):i(2)-1)+diff(y(idx))).*diff(x(idx)));
