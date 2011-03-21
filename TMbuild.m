function TMbuild(version)

% BUILD STAND-ALONE APPLICATION
if isnumeric(version);
% Copy XYscatter into current directory
    XY = 'C:\Users\pigpen\Documents\MSUResearch\MATLABcode\XYscatter\';
    copyfile([XY,'XYscatter.m'],cd,'f');
    copyfile([XY,'icons.ico'],cd,'f');
    
% Copy waitbar
    WB = 'C:\Users\pigpen\Documents\MSUResearch\MATLABcode\waitbar.m';
    copyfile(WB,cd,'f');
    
% Build project
    m = 'mcc -F model.prj'; eval(m);
    
% Copy files into release directory
    copyfile('model\src\model.exe','release\','f');

% Compile installer
    install_pkg = 'installer\TMinstaller.mpi';
    jam = ['!installjammer --build ',install_pkg];
    eval(jam);
    copyfile('installer\output\TMsetup.exe','release\');

% Copy documentation    
    hfile = 'documentation\main_ThermalModel.pdf';
    copyfile(hfile,'release\help.pdf','f');
    
% Update version file
    dlmwrite('release\version.txt',version);

% UDPATE REMOTE DIRECTORY
elseif strcmpi(version,'web')    
    sync = ['!winscp.exe /console /script="',cd,filesep,'sync.txt"'];
    eval(sync);
end
