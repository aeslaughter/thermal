function results(type,data,varargin)
% RESULTS plotter for thermal model input/output data.
%__________________________________________________________________________
% SYNTAX:
%   results('snw',data,N);
%   results('atm',data,N);
%   results('T',data,Tint);
%   results('TG',data,Tint);
%   results('Tcontour',data);
%   results('TGcontour',data);
%   results('flux',data,N,Tint);
%   results('fluxcontour',data,N);
%   results(...,ci);
%
% DESCRIPTION:
%   results('snw',data,N) plots the Nth* column of snow data.
%   results('atm',data,N) plots the Nth* column of atmospheric data.
%   results('T',data,Tint) plots temperature profiles with a time interval 
%       of Tint, which is given in hours.
%   results('TG',data,Tint)plots temperature gradient profiles with a time 
%       interval of Tint, which is given in hours. ;
%   results('Tcontour',data) graphs temperature via a contour plot.
%   results('TGcontour',data) graphs temp. gradient via a contour plot.
%   results('flux',data,N,Tint) graphs Nth flux term; sensible, latent, and
%       and long-wave plot as a single line with time (Tint is not needed
%       for these flux items); short-wave plots as profiles at the desired 
%       Tint given in hours.
%   results('fluxcontour',data,N); graphs the Nth flux term as a contour
%       graph with time.
%   results(...,ci) adds confidence levels specified by percentage provided
%       in ci, i.e., ci = 5 plots the 5 and 95% conficence levels
%__________________________________________________________________________

% 1 - GATHER THE X & Y DATA AND PLOT SETTINGS (a)
switch lower(type)
    % Snow properties
    case 'snw'; 
        N = varargin{1};
        y = data.snw(:,1); x = data.snw(:,N);
        [a.xlabel,a.ylabel] = getlabel(type,N);  
     
        if length(varargin) == 2 && ~isempty(varargin{2}); % adds c.i.
            lvl = varargin{2};
            ci = prctile(data.Sboot(:,N,:),[lvl,100-lvl],3);
            x = [ci(:,:,1),x,ci(:,:,2)];
            a.legend = {[num2str(lvl),'\% C.I.'],'Basis',...
                [num2str(100-lvl),'\% C.I.']};
        end
        
    % Atmospheric conditions
    case 'atm'; 
        N = varargin{1};
        x = data.atm(:,1)/3600; y = data.atm(:,N);
        [a.ylabel,a.xlabel] = getlabel(type,N);
        
        if length(varargin) == 2 && ~isempty(varargin{2}); % adds c.i.
            lvl = varargin{2};
            ci = prctile(data.Aboot(:,N,:),[lvl,100-lvl],3);
            y = [ci(:,:,1),y,ci(:,:,2)];
            a.legend = {[num2str(lvl),'\% C.I.'],'Basis',...
                [num2str(100-lvl),'\% C.I.']};
        end 
        
    % Temp. and temp. gradient    
    case {'t','tg'} 
        [x,y,a] = tempplot(type,data,varargin{:});
    case {'tcontour','tgcontour'} % Temp and gredient coutours
        [x,y,a] = tempcontour(type,data,varargin{:});
    case 'flux'; % Flux w/r/t time
        [x,y,a] = fluxplot(data,varargin{:});
    case 'fluxcontour'; % Flux contours
        [x,y,a] = fluxcontour(data,varargin{:});
end

% 2 - PRODUCE GRAPH
    if isempty(x); return; end
    XYscatter(x,y,'advanced',a,'interpreter','latex');
       
%--------------------------------------------------------------------------
function [X,Y] = getlabel(type,N)
% GETLABEL returns the approiate axis labels

switch lower(type)
    case 'snw';
        x{1} = 'Depth ($cm$)';
        x{2} = 'Density, $\rho$ ($kg/m^3$)';
        x{3} = 'Thermal conductivity, $k$ ($W/(m^{circ}K)$)';
        x{4} = 'Specific heat, $C_p$ ($kJ/(kg^{\circ}K)$)';
        x{5} = 'Initial snow temp., $T_s^{initial}$ ($^{\circ}C$)';
        x{6} = 'Extinction coefficient, $\kappa$ ($m^{-1}$)';
        x{7} = 'Extinction coefficient, $\kappa_{NIR}$ ($m^{-1}$)';
        X = x{N}; Y = 'Depth ($cm$)';
    case 'atm';
        x{1} = 'Time ($s$)';
        x{2} = 'Long-wave radiation, $LW$ ($W/m^2$)';
        x{3} = 'Short-wave radiation, $SW$ ($W/m^2$)';
        x{4} = 'Albedo, $\alpha$ ($\%$)';
        x{5} = 'Wind speed, $V_w$ ($m/s$)';
        x{6} = 'Air temperature, $T_a$ ($^{\circ}C$)';
        x{7} = 'Relative humidity, $RH$ ($\%$)';
        x{8} = 'Lower boundary temp., $T_{bottom}$ ($^{\circ}C$)';
        x{9} = 'Air pressure, $P_{atm}$ ($kPa$)';
        x{10} =  'Short-wave radiation (NIR), $SW_{NIR}$ ($W/m^2$)';
        x{11} = 'Albedo, $\alpha_{NIR}$ ($\%$)';    
        X = x{N}; Y = 'Time ($hr$)';
    case 'flux';
        x{1} = 'Latent heat flux, $Q_{lat}$ ($W/m^2$)';
        x{2} = 'Sensible heat flux, $Q_{sen}$ ($W/m^2$)';
        x{3} = 'Long-wave heat flux, $Q_{LW}$ ($W/m^2$)';
        x{4} = 'Short-wave heat flux, $Q_{SW}$ ($W/m^2$)';   
        x{5} = 'Short-wave heat flux (NIR), $Q_{SW_{NIR}}$ ($W/m^2$)';
        X = x{N};
end

%--------------------------------------------------------------------------
function [x,y,a] = tempplot(type,data,varargin)
% TEMPPLOT builds temp. and gradient profiles w/r/t time

% 1 - Build X and Y data
    C = data.const; dt = C(10); dz = C(9);
    y = (0:dz:size(data.T,1)*dz)';
    Tint = varargin{1};
    
    if length(varargin) == 2 && ~isempty(data.Tboot) &&...
            ~isempty(varargin{2}); % C.I. version plots specific profiles
        t = Tint*3600/dt+1;
        for i = 1:length(Tint); 
            a.legend{i} = datestr(Tint(i)/24,'HH:MM');
        end
    else %Non C.I. plots profiles at an interval
        t = 1:varargin{1}*3600/dt:size(data.T,2);
        for i = 1:length(t); 
            a.legend{i} = datestr((i-1)*varargin{1}/24,'HH:MM'); 
        end  
    end 
    x = data.T(:,t); 

% 2 - Set graph settings    
    a.xlabel = 'Temperature ($^{\circ}C$)';
    a.ylabel = 'Depth ($cm$)';
    a.ydir = 'reverse';

% 3 - Compute TG if desired    
    if strcmpi(type,'tg') && length(varargin) == 2% && isempty(varargin{2})
        a.xlabel = 'Temperature gradient ($^{\circ}C/m$)';
        x = diff(x,1)/dz*100;
        y = y(1:size(y,1)-1,:);
    end
    
% 4 - Add confidence intervals
    if length(varargin) == 2 && ~isempty(data.Tboot) &&...
            ~isempty(varargin{2});   
        lvl = varargin{2};
        ci = prctile(data.Tboot(:,t,:),[lvl,100-lvl],3);
       if strcmpi(type,'tg'); ci = diff(ci,1)/dz*100; end
    
        xnew = []; leg = {};
        for i = 1:size(ci,2);
            xnew = [xnew, ci(:,i,1), x(:,i), ci(:,i,2)];
            cur = a.legend{i};
            leg = [leg, [cur,' ',num2str(lvl),'\% C.I.'],cur,...
                [cur,' ',num2str(100-lvl),'\% C.I.']];
        end
        x = xnew; a.legend = leg;
    end

%--------------------------------------------------------------------------
function [x,y,a] = tempcontour(type,data,varargin)
% TEMPCONTOUR builds contour plots of temp/gradient w/r/t time

% 1 - Build X & Y data
    C = data.const; dt = C(10); dz = C(9);
    x = data.T;
    y = 50; % No. of contours 
          
% 2 - Define plot settings
    a.xlabel = 'Time ($hr$)';
    a.ylabel = 'Depth ($cm$)';
    a.ydir = 'reverse';
    a.contourxunits = dt/3600;
    a.contouryunits = dz;
    a.colormap = 'jet';
    a.contour = 'on';
    a.colorbar = 'on';
    a.colorbarlabel = 'Temperature ($^{\circ}C$)';
    a.ylim = [0,(size(data.T,1)-1)*dz];
    a.xlim = [0,(size(data.T,2)-1)*dt/3600];

% 3 - Compute TG if desired    
    if strcmpi(type,'tgcontour') && (isempty(varargin) ||...
            isempty(varargin{1}));
        a.colorbarlabel = 'Temperature gradient ($^{\circ}C/m$)';
        x = diff(x,1)/dz*100;
        Tint = varargin{1};
        t = Tint*3600/dt+1;
    elseif strcmpi(type,'tgcontour') && ~isempty(varargin{1});
        mes = ['Confidence interval plots for temperature gradient ',...
            'are not valid, thus the plot was not created.'];
        msgbox(mes,'WARNING!','warn'); x = []; y = []; a = []; return;
    end
    
% 4 - Case when C.I. is desired
    if ~isempty(varargin) && ~isempty(varargin{1});
        C = data.const; dt = C(10);
        T = data.T;
        lvl = varargin{1};
        ci = prctile(data.Tboot,[lvl,100-lvl],3);
        dev(:,:,1) = abs(T - ci(:,:,1));
        dev(:,:,2) = abs(ci(:,:,2) - T);
        x = max(dev,[],3); size(x)
        
        a.contourxunits = 1/dt;
        a.colorbarlabel = 'Max deviation ($^{\circ}C$)';
    end
        
%--------------------------------------------------------------------------
function [x,y,a] = fluxplot(data,varargin)
% FLUXPLOT plots flux profiles or surface value w/r/t to time

% 1 - Gather constant data
    N = varargin{1}; % Flux item to plot         
    C = data.const; dt = C(10); dz = C(9);
    if length(varargin) == 3 && ~isempty(varargin{3});
        mes = 'C.I. plots for flux data was not developed, sorry.';
        msgbox(mes,'Warning!','warn'); x = []; y =[]; a = []; return;
    end
 
% 2 - Case when latent, sensible, long-wave (only at surface, no profile) 
    if N <= 3;
        y = data.Q(1,:,N)'; 
        x = data.snw(:,1); 
        a.ylabel = getlabel('flux',N);
        a.xlabel = 'Time ($hr$)';
        
% 3 - Case when short-wave (builds profiles)        
    elseif N > 3
        y = (0:dz:(size(data.Q,1))*dz)'; 
        t = 1:varargin{2}*3600/dt:size(data.Q,2);
        x = data.Q(:,t,N); 
        a.xlabel = getlabel('flux',N);
        a.ylabel = 'Depth ($cm$)';   
        a.ydir = 'reverse';
        for i = 1:length(t); 
            a.legend{i} = datestr((i-1)*varargin{1}/24,'HH:MM'); 
        end  
    end
    
%--------------------------------------------------------------------------
function [x,y,a] = fluxcontour(data,varargin)
% FLUXCONTOUR builds contour plots of flux data (short-wave)

% 1 - Build X & Y data
    N = varargin{1};
    C = data.const; dt = C(10); dz = C(9);
    x = data.Q(:,:,N); 
    y = 50; % No. of contorus
    
% 2 - Set graph settings    
    a.xlabel = 'Time ($hr$)';
    a.ylabel = 'Depth ($cm$)';
    a.ydir = 'reverse';
    a.contourxunits = dt/3600;
    a.contouryunits = dz;
    a.colormap = 'jet';
    a.contour = 'on';
    a.colorbar = 'on';
    a.colorbarlabel = getlabel('flux',N);
    a.ylim = [0,(size(x,1)-1)*dz];
    a.xlim = [0,(size(x,2)-1)*dt/3600];
        