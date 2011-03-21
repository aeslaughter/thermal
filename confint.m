function data = confint(filename,B,n)
% CONFINT computes the confidence intervals for temp profiles

% Read file input
    [S,A,C,E] = xls_input(filename);

% Compute the actual temperature profile    
    [Sa,Aa] = xls_prep(S,A,C);
    T = thermal(Sa,Aa,C);

% Compute the standard deviation values    
    s = getstd(S,E.snow,n,1); % standard devaition for snow properties 
    a = getstd(A,E.atm,n,1); % standard devaition for atmospheric terms 
    c = getstd(C,E.const,n,0); % standard deviation for constants
    
% Compute the Monte Carlo replicates    
    data.Tboot = zeros([size(T),B]); % Initilize storage array
    h = waitbar(0,'Please wait...');
    for i = 1:B;
        r = rand(1);     
        S_b = norminv(r,S,abs(s)); % Re-sample snow
            S_b(:,1) = S(:,1);     % Snow depth does not change
            S_b(isnan(S_b)) = S(isnan(S_b));
        A_b = norminv(r,A,abs(a)); % Re-sample atmosphere 
            A_b(:,1) = A(:,1);     % Duration does not change  
            A_b(isnan(S_b)) = A(isnan(A_b));
        C_b = norminv(r,C,abs(c)); % Constant resampling
            C_b(9) = C(9);         % dz constant
            C_b(10) = C(10);       % dt constant
            C_b(isnan(C_b)) = C(isnan(C_b));
  
        [SS,AA] = xls_prep(S_b,A_b,C_b); % Build input for evaluation
        [data.Tboot(:,:,i), data.Qboot(:,:,:,i)] = thermal(SS,AA,C_b);
        data.Sboot(:,:,i) = SS;
        data.Aboot(:,:,i) = AA;
        data.Cboot(:,:,i) = C_b;
        waitbar(i/B,h);
    end
    close(h);

%--------------------------------------------------------------------------
function s = getstd(S,E,n,offset)
% GETSTD returns the standard deviation of the input items
    if offset == 1;
        s(:,1) = S(:,1);
        for i = 2:size(S,2);
            s(:,i) = S(:,i).*E(i-offset)/n;
        end
    elseif offset == 0;
        for i = 1:size(S,2);
            s(:,i) = S(:,i).*E(i)/n;
        end    
    end

