function fig = model
% MODEL opens the thermal model GUI (modelGUI.m and modelGUI.fig)

% 1 - OPEN GUI AND SET PROGRAM PREFERENCES
    fig = open('modelGUI.fig'); 
    h = guihandles(fig);
    createpref;
    
% 2 - SET CALLBACKS
    % 2.1 - Callback for when the figure is closing
        set(fig,'CloseRequestFcn',{@callback_closerequestfcn});
        
    % 2.2 - Callbacks for project actions    
        set(h.open,'Callback',{@callback_openproject});
        set(h.save,'Callback',{@callback_saveproject});
        set(h.new,'Callback',{@callback_newproject});
        set(h.push_open,'ClickedCallback',{@callback_openproject});
        set(h.push_save,'ClickedCallback',{@callback_saveproject});
        set(h.push_new,'ClickedCallback',{@callback_newproject});
        set(h.compci,'Callback',{@callback_toggleci});
        
    % 2.3 - Callbacks for program usage    
        set(h.list,'Callback',{@callback_selectproject});
        set(h.newrun,'Callback',{@callback_newrun});
        set(h.changebase,'Callback',{@callback_changebase});
        set(h.evaluate,'Callback',{@callback_evaluate});
        set(h.graph,'Callback',{@callback_graph});
        set(h.exit,'Callback',{@callback_closerequestfcn});
        set(h.help,'Callback',{@help});
        set(h.about,'Callback',{@about});
    
    % 2.4 - Context menu for removing a project run    
        hmenu = uicontextmenu('parent',fig);
        uimenu(hmenu,'Label','Remove','Callback',{@callback_deleterun});
        uimenu(hmenu,'Label','Edit name','Callback',{@callback_editname});
        set(h.list,'uicontextmenu',hmenu);
        
    % 2.5 - Callbacks for plot buttons
        hh = [h.contour,h.profile,h.ciprofile,h.cicontour,h.input];
        set(hh,'Callback',{@callback_plotbtn});
   
 % 3 - INITILIZE
 	pth = getpref('TMv5','lastprojdir');
    fn = getpref('TMv5','lastprojfile');
    filename = [pth,fn];
    if exist(filename,'file');
        callback_openproject(h.open,filename);
    else
        callback_newproject(h.new,[]);
    end
    callback_toggleci(h.compci,[]);
    set(h.profile,'Value',1); callback_plotbtn(h.profile,[]);
    
 % 4 - VERSION INFORMATION
    GUI = guidata(fig);
    GUI.version = 0.1;
    GUI.verdate = 'Mar. 22, 2010';
    setpref('thermalmodel','version',GUI.version);
    guidata(fig,GUI);
 
 % 5 - PROMPT USER OF NEW VERSION
    try
        available = urlread(['http://www.coe.montana.edu/',...
                    'ce/subzero/snow/thermalmodel/version.txt']);
        available = str2double(available);
    catch
        available = 0;
    end
    if available > getpref('thermalmodel','version');
       q = ['A new version is available, would you like to download',...
           ' the new file?'];
       ans = questdlg(q,'New version?','Yes','No','Yes');
       if strcmpi(ans,'yes');
            web http://www.coe.montana.edu/ce/subzero/snow/thermalmodel/...
                -browser
       end
    end
       
%--------------------------------------------------------------------------
function callback_graph(hObject,eventdata)
% CALLBACK_GRAPH creates the desired graph via result.m   
  
% 1 - GATHER INFORMATION FROM GUI
    h = guihandles(hObject);
    GUI = guidata(hObject);
    data = GUI.current;
    profile = get(h.profile,'Value');
    Tint = str2double(get(h.Tint,'String'));
    ci =[];
    if get(h.ciprofile,'Value') == 1 || get(h.cicontour,'Value') == 1;  
        Tint = eval(['[',get(h.citime,'String'),']']);
        ci = str2double(get(h.cilevel,'String'));
        profile = get(h.ciprofile,'Value');
    end
    
% 2 - SNOW DATA
    snw = get(h.snw,'Value'); idx = snw ~= 1; snw = snw(idx);
    for i = 1:length(snw); 
        results('snw',data,snw(i),ci); title(data.name);  
    end
    
% 3 - ATMOSPHERIC DATA
    atm = get(h.atm,'Value'); idx = atm ~= 1; atm = atm(idx);
    for i = 1:length(atm); results('atm',data,atm(i),ci); end
    
% 4 - FLUX DATA
    flx = get(h.flux,'Value'); idx = flx ~= 1; flx = flx(idx)-1;
    for i = 1:length(flx); 
        if profile == 1
            results('flux',data,flx(i),Tint,ci);;
        elseif profile == 0;
            results('fluxcontour',data,flx(i),ci);;
        end
    end
    
% 5 - TEMP. DATA
    tmp = get(h.temp,'Value'); idx = tmp ~= 1; tmp = tmp(idx)-1;
    opt = {'T','TG'};
    for i = 1:length(tmp); 
        if profile == 1
            results(opt{tmp(i)},data,Tint,ci);;
        elseif profile == 0;
            results([opt{tmp(i)},'contour'],data,ci);;
        end
    end
    
%--------------------------------------------------------------------------
function callback_newproject(hObject,eventdata)
% CALLBACK_NEWPROJECT creates a new project
  
% 1 - CHECK THAT PROJECT IS SAVED
    % 1.1 - Compare structures
    GUI = guidata(hObject); if isempty(GUI); delete(gcbf); return; end
    if ~exist(GUI.prjfile,'file') || ~isfield(GUI,'data'); 
        tf = 0;
    else
        tmp = load('-mat',GUI.prjfile); prj = tmp.data;
        tf = isequal(prj,GUI.data);
    end
    
    % 1.2 - Prompt user to exit if the current project is unsaved    
    if tf == 0;
        mes = ['The current project has not been saved, ',...
            'are you sure you want to continue?'];  
        q =questdlg(mes,'Project not saved!','Continue','Cancel','Cancel');
        if strcmpi(q,'Cancel'); return; end
    end  

% 2 - PREPARE GUI INFORMATION
    h = guihandles(hObject);
    set(h.list,'String',{});
    if isfield(GUI,'data'); GUI = rmfield(GUI,'data'); end
    GUI.prjfile = '';
    
% 3 - CREATE A NEW EXCEL BASE
    % 3.1 - Prompt user to start a new base file
        spec = {'*.xlsx','MS Excel 2007 (*.xlsx)';...
            '*.xls','MS Excel 97-03 (*.xls)'};
        loc = getpref('TMv5','lastxlsdir');    
        q = questdlg(['Do you want to create a new Excel input file ',...
            'or use an existing file?'],'New...','New','Existing',...
            'Cancel','New');
        
    % 3.2 - Determine Excel base filename    
        if strcmpi(q,'new');
            [fn,pth] = uiputfile(spec,'Save file as...',[loc,'*.xlsx']);
            if isnumeric(fn); return; end;  
            copyfile('template.xlsx',[pth,fn],'f'); winopen([pth,fn]); 
        elseif strcmpi(q,'existing')
            [fn,pth] = uigetfile(spec,'Select file...',[loc,'*.xlsx']);
            if isnumeric(fn); return; end;    
        else    
            return;
        end
        
    % 3.3 - Store directory and creat new run     
        setpref('TMv5','lastxlsdir',pth);    
        set(h.base,'String',[pth,fn]);
        guidata(hObject,GUI);
        callback_newrun(h.newrun,[]);
    
%--------------------------------------------------------------------------
function callback_changebase(hObject,eventdata)
% CALLBACK_CHANGEBASE opens dialog for changing base xls file

% 1 - Determine new Excel file
    h = guihandles(hObject);
    GUI = guidata(hObject);
    if strcmpi(get(h.base,'Enable'),'off');
        winopen(GUI.current.xls);
    else
        spec = {'*.xlsx','MS Excel 2007 (*.xlsx)';...
            '*.xls','MS Excel 97-03 (*.xls)'};
        loc = getpref('TMv5','lastxlsdir');
        [fn,pth] = uigetfile(spec,'Select base Excel file...',loc);
        if isnumeric(fn); return; end;
        setpref('TMv5','lastxlsdir',pth);
        set(h.base,'String',[pth,fn]);
    end

%--------------------------------------------------------------------------
function callback_openproject(hObject,eventdata)
% CALLBACK_OPENPROJECT opens a saved project

% 1 - Open the file
    if ~exist(eventdata,'file');
        spec = {'*.prj','Thermal model project (*.prj)'};
        loc = getpref('TMv5','lastprojdir');
        [fn,pth] = uigetfile(spec,'Select project...',loc);
        if isnumeric(fn); return; end;
        setpref('TMv5','lastprojdir',pth);
        setpref('TMv5','lastprojfile',fn);
        filename = [pth,fn];
    else
        filename = eventdata;
    end
    tmp = load('-mat',filename); prj = tmp.data;

% 2 - List project runs in GUI
    h = guihandles(hObject);
    prjcell = struct2cell(prj);
    set(h.list,'String',prjcell(3,:),'Value',1);
    
% 3 - Update the current run information
    GUI = guidata(hObject);
    GUI.data = prj;
    GUI.prjfile = filename;
    guidata(hObject,GUI);
    callback_selectproject(h.list,[]);

%--------------------------------------------------------------------------
function callback_selectproject(hObject,eventdata)
% CALLBACK_SELECTPROJECT executes when a run is selected from the project
    
% 1 - Insert text
    h = guihandles(hObject);
    GUI = guidata(hObject);
    itm = get(hObject,'Value');
 
 % 2 - Build short version of base-file name   
    file = GUI.data(itm).xls;
    idx = strfind(file,cd);
    if idx == 1;file = file(length(cd)+2:length(file));end
    
 % 3 - Insert correct data into run informatin   
    set(h.base,'String',file);
    set(h.name,'String',GUI.data(itm).name);
    set(h.time,'String',GUI.data(itm).time);
    set(h.desc,'String',GUI.data(itm).desc);
    set(h.newrun,'Enable','on');
    set([h.changebase],'ToolTipString','open excel file');
    
 % 4 - Change run information so that it cannot be editted   
    hh = [h.base,h.name,h.time,h.desc];
    set(hh,'enable','off');
    
 % 5 - Apply selected data to GUI data strcuture
    GUI.current = GUI.data(itm);
    guidata(hObject,GUI);
    
 % 6 - Results setup
    [S,A,F,T] = getlists;
    ns = size(GUI.current.snw,2); set(h.snw,'String',S(1:ns));
    na = size(GUI.current.atm,2); set(h.atm,'String',A(1:na));
    nf = size(GUI.current.Q,3)+1; set(h.flux,'String',F(1:nf));
    set(h.temp,'String',T);
    
 % 7 - Confidence level settings
    hh = [h.ciprofile,h.cicontour];
    if isempty(GUI.current.Tboot);
        set(hh,'Value',0,'Enable','off');
    else
        set(hh,'Enable','on');
    end

%--------------------------------------------------------------------------
function callback_evaluate(hObject,eventdata)
% CALLBACK_EVALUATE peforms the model evalution and add to run list

 % 1 - Gather GUI information
    h = guihandles(hObject);
    GUI = guidata(hObject);    
    name = get(h.name,'String');
    desc = get(h.desc,'String');
    xls = get(h.base,'String');
    
% 2 - Warn user about overwritting   
    str = cellstr(get(h.list,'String'));
    m = strmatch(name,str);
    if ~isempty(m); % Re-evaluation
        mes = ['This run was previously evaluated, would you like to ',...
            'contiune and overwrite the existing evaluation?'];
        q = questdlg(mes,'Overwrite?','Continue','Cancel','Cancel');
        if strcmpi(q,'Cancel'); return; end;
    end
    
 % 2 - Run the model
    if get(h.compci,'Value') == 1;
        B(1) = str2double(get(h.nboot,'String'));
        B(2) = str2double(get(h.dev,'String'));
    else
        B = [];
    end
    data = runmodel(xls,name,desc,B);

 % 3 - Update the project
    if ~isfield(GUI,'data'); nitm = 0;
    else nitm = length(GUI.data);
    end
    
 % 4 - Update the list   
    if ~isempty(m); % Re-evaluation
        GUI.data(m) = data;
        set(h.list,'Value',m);
    else % New evaluation
        set(h.list,'String',[str;name]);    
        GUI.data(nitm+1) = data;   
        set(h.list,'Value',nitm+1);
    end
    
 % 5 - Return data to GUI and select the new run   
    guidata(hObject,GUI);
    callback_selectproject(h.list,[]);
     
%--------------------------------------------------------------------------
function callback_newrun(hObject,eventdata)
% CALLBACK_NEWRUN allows user to execute the thermal model

% 1 - Gather information from GUI 
    h = guihandles(hObject);
    GUI = guidata(hObject);
    if ~isfield(GUI,'data'); nitm = 0;
    else
        nitm = length(GUI.data);
    end

% 2 - Toggle buttons    
    set([h.changebase],'ToolTipString','select a new file');
    set(h.newrun,'Enable','off');
      
% 3 - Toggle text box appearence    
    hh = [h.name,h.desc,h.base,h.changebase];
    set(hh,'enable','on');
    set(h.name,'String',['Run #',num2str(nitm+1)]);
    set(h.desc,'String','');

%--------------------------------------------------------------------------
function callback_deleterun(hObject,eventdata)
% CALLBACK_DELETERUN removes the current selection

% 1 - Gather information from the GUI
    h = guihandles(hObject);
    GUI = guidata(hObject);
    if ~isfield(GUI,'data'); nitm = 0; return;
    else
        nitm = length(GUI.data);
    end
    
% 2 - Gather string, value, and indices to retain    
    str = get(h.list,'String');
    val = get(h.list,'Value');
    idx = (1:nitm) ~= val;
    
% 3 - Re-build the data structure    
    GUI.data = GUI.data(idx);
    set(h.list,'String',str(idx'),'Value',1);
    guidata(hObject,GUI); 
    callback_selectproject(h.list,[]);
    
%--------------------------------------------------------------------------
function callback_editname(hObject,eventdata)
% CALLBACK_EDITNAME allows the run name to be changed

% 1 - Gather information from the GUI and exit if no data exists
    h = guihandles(hObject);
    GUI = guidata(hObject);
    if ~isfield(GUI,'data');return; end

% 2 - Gather string and value
    val = get(h.list,'Value');
    str = get(h.list,'String');
    
% 3 - Collect the new string  
    newname = inputdlg('Enter the new run name:','Edit...',1,...
        {GUI.data(val).name});
    if isempty(newname) || isempty(newname{1}); return; end
      
% 4 - Re-build the data structure and listbox items
    GUI.data(val).name = newname{1};
    str{val} = newname{1};
    set(h.list,'String',str);
    guidata(hObject,GUI); 
    callback_selectproject(h.list,[]);

%--------------------------------------------------------------------------
function callback_saveproject(hObject,eventdata)
% CALLBACK_SAVEPROJECT saves the current project

% 1 - Gather data from GUI
    GUI = guidata(hObject);
    data = GUI.data;
  
% 2 - Prompt user if the file already exists if it should be overwritten  
    q = 'no';
    if exist(GUI.prjfile,'file');
        q = questdlg(['The project already exists, do you want to ',...
            'overwrite this project?']);
    end  
    
% 3 - Prompt for filename if a new file is being created 
    if strcmpi(q,'no');
        spec = {'*.prj','Thermal model project (*.prj)'};
        [fn,pth] = uiputfile(spec,'Save project as...');
        if isnumeric(fn); return; end
        GUI.prjfile = [pth,fn];
        guidata(hObject,GUI);
    elseif strcmpi(q,'cancel'); return;
    end

 % 4 - Save the file   
    save(GUI.prjfile,'-mat','data');
    
%--------------------------------------------------------------------------
function createpref
% CREATPREF creates preferences for use by the thermal model

% 1 - Define prefences of program
    grp = 'TMv5';
    pref = {'lastprojdir','lastprojfile','lastxlsdir'};
    def = {[cd,filesep,'projects',filesep],'Morstad2004.prj',...
        [cd,filesep,'input',filesep]};
  
% 2 - Add the preferences    
    for i = 1:length(pref);
        if ~ispref(grp,pref{i}); addpref(grp,pref{i},def{i}); end
    end
    
%--------------------------------------------------------------------------
function [S,A,F,T] = getlists
% GETLABEL returns the approiate axis labels

    S{1} = '(none)';
    S{2} = 'Density';
    S{3} = 'Thermal conductivity';
    S{4} = 'Specific heat';
    S{5} = 'Initial snow temp.';
    S{6} = 'Extinction coefficient';
    S{7} = 'Extinction coefficient (NIR)';

    A{1} = '(none)';
    A{2} = 'Long-wave radiation';
    A{3} = 'Short-wave radiation';
    A{4} = 'Albedo';
    A{5} = 'Wind speed';
    A{6} = 'Air temperature';
    A{7} = 'Relative humidity';
    A{8} = 'Lower boundary temp.';
    A{9} = 'Air pressure';
    A{10} = 'Short-wave radiation (NIR)';
    A{11} = 'Albedo (NIR)';    

    F{1} = '(none)';
    F{2} = 'Latent heat flux';
    F{3} = 'Sensible heat flux';
    F{4} = 'Long-wave heat flux';
    F{5} = 'Short-wave heat flux';   
    F{6} = 'Short-wave heat flux (NIR)';

    T{1} = '(none)';
    T{2} = 'Temperature';
    T{3} = 'Temperature gradient';
    
%--------------------------------------------------------------------------
function callback_closerequestfcn(hObject,eventdata)
% CALLBACK_CLOSEREQUESTFCN operates when the main window closes

% 1 - Compare the saved project with the current project
    GUI = guidata(hObject); if isempty(GUI); delete(gcbf); return; end
    if ~exist(GUI.prjfile,'file') || ~isfield(GUI,'data'); 
        tf = 0;
    else
        tmp = load('-mat',GUI.prjfile); prj = tmp.data;
        tf = isequal(prj,GUI.data);
    end
    
% 2 - Prompt user to exit if the current project is unsaved    
    if tf == 0;
        mes = ['The current project has not been saved, ',...
            'are you sure you want to exit?'];  
        q = questdlg(mes,'Project not saved!','Exit','Cancel','Cancel');
        if strcmpi(q,'Cancel'); return; end
    end
    
    delete(gcbf);
    
%--------------------------------------------------------------------------
function callback_toggleci(hObject,eventdata)
% CALLBACK_TOGGLECI toggles the visibility of confidence interval items

vis = 'off';
if get(hObject,'value') == 1; vis = 'on'; end

h = guihandles(hObject);
set(get(h.cipanel,'Children'),'Enable',vis);

%--------------------------------------------------------------------------
function callback_plotbtn(hObject,eventdata)
% CALLBACK_PLOTBTN sets approiate enable actions when a plot button is hit

h = guihandles(hObject);
hh = [h.Tint,h.Tint_text; h.cilevel, h.cilevel_text; ...
    h.citime, h.citime_text; h.snw, h.snw_text; ...
    h.atm, h.atm_text; h.flux, h.flux_text; h.temp, h.temp_text];
set(hh,'Enable','on');

if get(h.input,'Value') == 1; 
    set(hh([1:3,6,7],:),'enable','off');
elseif get(h.contour,'Value') == 1; 
    set(hh(1:5,:),'enable','off'); 
elseif get(h.profile,'Value') == 1; 
    set(hh(2:5,:),'enable','off');
elseif get(h.ciprofile,'Value') == 1; 
    set(hh([1,6],:),'enable','off');
elseif get(h.cicontour,'Value') == 1; 
    set(hh([1,3:6],:),'enable','off');
end

%--------------------------------------------------------------------------
% CALLBACKS: help/abouts
function help(hObject,eventdata,gui); winopen('documentation\help.pdf');
function about(hObject,eventdata)
   GUI = guidata(hObject);
   m{1} = ['This program was created by Andrew E. Slaughter and ',...
       'cannot be used without expressed permission.'];
   m{2} = '';
   m{3} = ['Version: ',num2str(GUI.version)];
   m{4} = ['Last Updated: ',GUI.verdate];
   m{5} = '';
   m{6} = 'Copyright 2009, Andrew E. Slaughter';

   msgbox(m,'Snow Thermal Model software');
   