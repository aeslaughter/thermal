clrfig;
excelfile = 'input\Morstad2004\Exp#1.xlsx';
    [S,A,data.const] = xls_input(excelfile);
    [data.snw,data.atm] = xls_prep(S,A,data.const);
    [T1,Q1] = thermal_old(data.snw,data.atm,data.const);
    [T2,Q2] = thermal(data.snw,data.atm,data.const);

% E = 2*abs(T2-T1)./(T2+T1) * 100;
y = 0:0.5:40.5;
E = T2 - T1;

a.contour = 'on';
a.colorbar = 'on';
a.colorbarlabel = 'Temp. Difference [$^{\circ}$C]';
a.ydir = 'reverse';
a.colormap = 'jet';
a.contourxunits = 1/60;
a.contouryunits = 0.5;
a.xlim = [0,10];
a.ylim = [0,40];
a.xlabel = 'Time (hr)';
a.ylabel = 'Depth (cm)';
a.interpreter = 'latex';
XYscatter(E,50,'advanced',a);

a.colorbarlabel = 'Temp. [$^{\circ}$C]';
XYscatter(T1,50,'advanced',a,'title','Old');
XYscatter(T2,50,'advanced',a,'title','New');


