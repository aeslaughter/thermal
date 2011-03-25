function [T,Q] = thermal(snow,atm,C)
% THERMAL executes 1-D heat equation based thermal model
%__________________________________________________________________________
% SYNTAX:
%   [T,Q] = thermal(snow,atm,C)
%
% DESCRIPTION:
%   [T,Q] = thermal(snow,atm,C) based on the information provided in the
%   numeric arrays containing snow properties (snow), atmospheric
%   conditions (atm), and model constants (C) a 1-D thermal analysis is
%   performed resulting in the snowpack temperatures (T) and associated
%   heat fluxes (Q)
%__________________________________________________________________________

% 1 - PREPARE VARIABLES FOR CALCULATION
    % 1.1 - Pre-define arrays
        if size(atm,2) == 11 && size(snow,2) == 7; 
            ndim = 2; 
        else 
            ndim = 1; 
        end

        nt = size(atm,1);           % Number of time steps
        ns = size(snow,1);          % Number of snow elements

        T = zeros(ns,nt);           % Temperature array
        q = zeros(ns,nt,ndim);      % Short-wave flux absorbed array
        qs = zeros(nt,3);           % Surface flux array

        A = zeros(ns+1,ns+1);       % A-matrix for temperature solution
        b = zeros(ns+1,1);          % b-vector for temperature solution

    % 1.2 - Establish user specified constants
        Ls = C(1);
        Ke = C(2);
        Kh = C(3);
        MvMa = C(4);
        Rv = C(5);
        T0 = C(6) + 273.15;
        e0 = C(7);
        emis = C(8);
        dz = C(9)/100;
        dt = C(10);
    
    % 1.3 - Define additional constants needed   
        sb = 5.6696*10^(-8);        % Stefan–Boltzmann constant (W/m^2/K^4)
        R = 0.287;                  % Gas constant for air (kJ/kg/K)
    
    % 1.4 - Compute the properties of air    
        Cp_air = 1003;              % Specific heat @-5C (J/kg/K)
        rho_air = atm(:,9)./(R*(atm(:,6) + 273.15)); % Density (kg/m^2)

 % 2 - INITILIZE ARRAYS FOR COMPUTATION       
    % 2.1 - Initilize temperature array    
        T(:,1) = snow(:,5);   % Initial snow temperature
        T(ns+1,:) = atm(:,8); % Base

    % 2.2 - General matrix coefficients
        Ca = squeeze(snow(:,3,:) ./ dz^2);                  % a
        Cb = squeeze((snow(:,2,:) .* snow(:,4,:))./dt);     % b

        
    % 2.3 - Adjust matrix coefficients
        if size(Ca,2) == 1;
            Ca = repmat(Ca,1,nt);
            Cb = repmat(Cb,1,nt);
        end
        
    % 2.4 - Complete the matrix coefficients    
        Cc = Cb + Ca;  % c
        Cd = Cb - Ca;  % d      

% 3 - BEGIN COMPUTING FOR EACH TIME STEP (time step = index "j")        
for j = 2:nt     
    % 3.1 - Establish air/snow surface temperatures
        Ta = atm(j,6) + 273.15;
        Ts = T(1,j-1) + 273.15; 
    
    % 3.2 - Compute longwave heat flux
        qs(j,1) = atm(j,2) - emis*sb*Ts^4;

    % 3.3 - Compute the latent heat flux 
        ea = e0*exp(Ls/Rv *(1/T0 - 1/Ta))*atm(j,7)/100;
        es = e0*exp(Ls/Rv *(1/T0 - 1/Ts));
        qs(j,2) = 1000*MvMa*rho_air(j)*Ls*Ke*atm(j,5)*(ea-es)/atm(j,9);

    % 3.4 - Compute the sensible heat flux
        qs(j,3) = Kh*rho_air(j)*Cp_air*atm(j,5)*(Ta - Ts);

    % 3.5 - Compute the absorbed shortwave and build solution matrix 
    %       for each layer of snow  
        % 3.5.1 - Compute shortwave absorbed in the top layer
            q(1,j,1) = atm(j,3)*(1-atm(j,4))*(1-exp(-snow(1,6)*dz));
            
        % 3.5.2 - Compute shortave in NIR if present
            if ndim == 2;
                q(1,j,2) = atm(j,10)*(1-atm(j,11))*(1-exp(-snow(1,7)*dz));
            end
            
        % 3.5.2 - Compute shortwave absorbed for lower layers and build 
        %         solution matrices    
        for i = 2:ns
            % Short-wave radiation absorbed
            q(i,j,1) = q(i-1,j,1)*exp(-snow(i,6)*dz); % all-wave or VIS
            if ndim == 2;
                q(i,j,2) = q(i-1,j,2)*exp(-snow(i,7)*dz); % NIR
            end
            
            % Solution matrices
            A(i,i-1) = -Ca(i,j)/2;
            A(i,i)   = Cc(i,j);
            A(i,i+1) = -Ca(i,j)/2;
            b(i,1) = Ca(i,j)/2*T(i-1,j-1) + Cd(i,j)*T(i,j-1) + ...
                        Ca(i,j)/2*T(i+1,j-1) + sum(q(i,j,:))/dz;
        end
        
    % 3.6 - Compute the surface flux
        sur_flux = sum(qs(j,1:3));
 
    % 3.7 - Insert matrix values for surface node (i = 1)
        A(1,1) = Cc(1,j);
        A(1,2) = -Ca(1,j);
        b(1) = Cd(1,j)*T(1,j-1) + Ca(1,j)*T(2,j-1) + 2*sur_flux/dz + ...
            sum(q(1,j,:))/dz;

    % 3.8 - Insert matrix values for bottom boundary condition
        A(ns+1,ns+1) = 1;
        b(ns+1) = atm(j,8);

    % 3.9 - Calculate the new temperature profile
        Tnew = A\b;
        Tnew(Tnew>0) = 0;
        T(:,j) = Tnew;
end;

Q = zeros(ns,nt,ndim+3);
Q(1,:,1:3) = qs;
Q(:,:,4:end) = q;