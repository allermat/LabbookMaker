#pragma rtGlobals = 3			    // Use modern global access method and strict wave access.
#pragma IgorVersion = 6.30       // The above pragma is valid from IGOR 6.30
#pragma version = 1.00
#pragma ModuleName = LB_PeakClipper  // I used a Regular Module to avoid name conflicts. 




//********************************************************************************************************************************************************************
//********************************************************************************************************************************************************************
//
// Labbook Maker: dFperFoPanel Functions
// Code for WaveMetrics Igor Pro
// 
// by Máté Aller (allermat@gmail.com)
//
// First Release: 
// Last Modified: 
//
//********************************************************************************************************************************************************************
//********************************************************************************************************************************************************************




//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                      CONSTANTS                                                                                   //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

 
// Naming conventions: see in LB_Main.ipf
//

Static Constant K_GROUP0_SIZE = 50
Static Constant K_GROUP1_SIZE = 95
Static Constant K_GROUP2_SIZE = 35
Static Constant K_GROUP3_SIZE = 125
Static Constant K_PC_CTRL_BAR_WIDTH_PIX = 200
Static Constant K_PC_HEIGHT_PIX = 370
Static Constant K_PC_SUB_WIDTH_PIX = 540
Static Constant K_PC_SUB_HEIGHT_PIX = 370
Static Constant K_PC_WIDTH_PIX = 740
Static Constant K_PC_XOFFSET_PIX = 40
Static Constant K_PC_YOFFSET_PIX = 100

// THESE CONSTANTS MUST BE PART OF ALL LB SOURCE FILES!
Static StrConstant KS_F_BGDCORR = "root:BGDCorrectedData"
Static StrConstant KS_F_CA = "root:CalciumData"
Static StrConstant KS_F_EXP_DETAILS = "root:ExperimentDetails"
Static StrConstant KS_F_IMP_TRACES = "root:RawData:Traces"
Static StrConstant KS_F_IMP_DETAILS = "root:RawData:ImportDetails"
Static StrConstant KS_F_MAIN = "root:Packages:LabbookControlPanel"
Static StrConstant KS_F_PEAKS = "root:PeakData"
Static StrConstant KS_F_PEAKS_BGD = "root:PeakData:BGD"
Static StrConstant KS_F_PEAKS_DFPERFO = "root:PeakData:dFperFo"
Static StrConstant KS_F_PEAKS_RATIO = "root:PeakData:Ratio"
Static StrConstant KS_F_PEAKS_CA = "root:PeakData:Calcium"
Static StrConstant KS_F_PEAK_CLIPPER_PACK = "root:Packages:PeakClipper"
Static StrConstant KS_F_RATIO = "root:RatioData"
Static StrConstant KS_F_RAW = "root:RawData"
Static StrConstant KS_F_WORK_BGDCORR = "root:Packages:LabbookControlPanel:work_BGDCorrTraces"
Static StrConstant KS_F_WORK_PEAKS = "root:Packages:PeakClipper:work_Peaks"
Static StrConstant KS_F_WORK_RATIO = "root:Packages:LabbookControlPanel:work_Ratio"
Static StrConstant KS_F_WORK_FO = "root:Packages:PeakClipper:work_Fo_data"

Static StrConstant KS_MAIN_PANEL_NAME = "LabbookControlPanel"
Static StrConstant KS_PEAK_CLIPPER_NAME = "PeakClipper"
Static StrConstant KS_TIMEVAL_ENDING = "_tv"
Static StrConstant KS_CALFILE_PATH = "\\Igor Procedures\\Labbook\\fura_calibrations.txt"


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                        FUNCTIONS FOR BUILDING AND CONTROLLING THE PANEL                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


Static Function DisplayPeakClipper()
// Synopsis: makes sure that all the variables and folders are set up and thend creates the panel. 
// Details: - 
// Parameters: - 
// Return Value(s): NaN
// Side effects: 
//               Creates certain data folders and variables inside them. 
//               Disables the Labboook Control Panel's "Make the Labbook" button.  
// Error message(s): -
//

	// If the panel is already created, just bring it to the front.
	DoWindow/F $KS_PEAK_CLIPPER_NAME
	if (V_Flag != 0)
		return 0
	endif
	
	// If there is no waves to work on, then do nothing. 
	DFREF work_BGDCorr = $KS_F_WORK_BGDCORR
	if (LB_Util#IsDataFolderEmpty(work_BGDCorr) == 1)
		return NaN
	endif
	
	// Create a data folder in Packages to store globals.
	NewDataFolder/O/S $KS_F_PEAK_CLIPPER_PACK
	NewDataFolder/O $KS_F_WORK_PEAKS
	
	DFREF Main = $KS_F_MAIN
	SVAR NormMode = Main:gStrNormMode
	if (StringMatch(NormMode, "dF/Fo") == 1)
		NewDataFolder/O $KS_F_WORK_FO
	endif
	
	// Create global variables used by the control panel.	
	Variable Tick_d = NumVarOrDefault(":gVarTick_d", 0)
	Variable/G gVarTick_d = Tick_d
	Variable Count = NumVarOrDefault(":gVarCount", 0)
	Variable/G gVarCount = Count
	Variable Peaks_delPop = NumVarOrDefault(":gVarPeaks_delPop", 0)
	Variable/G gVarPeaks_delPop = Peaks_delPop
	
	Make/n=3 Clicks
	
	SetDataFolder root:
	
	PeakClipperAssembly()                                      // Create control panel. 
	
	DFREF work_Peaks = $KS_F_WORK_PEAKS                        // If there is some peak data, display the peaks in the PeakClipper. 
	if (!LB_Util#IsDataFolderEmpty(work_Peaks))
		String subWinList = ChildWindowList(KS_PEAK_CLIPPER_NAME)
		Variable i = 0
	
		do
			String item = StringFromList(i, subWinList)
			
			if (StringMatch(item, "") == 1)
				break
			endif
			
			MarkPeaks(KS_PEAK_CLIPPER_NAME + "#" + item)
						
			i += 1
		while (1)

	endif
	
	ControlInfo/W=$KS_MAIN_PANEL_NAME main                        // The visibility of these controls are set according to the state of the tabcontrol in 
	if (V_Value == 3)                                             // which they are installed. 
		SetVariable SetNumTreat_main3,win=$KS_MAIN_PANEL_NAME, disable = 2
	endif
	
	Button ButtonLabbook,win=$KS_MAIN_PANEL_NAME,disable = 2            // Disable the Labboook Control Panel's "Make the Labbook" button while the Peak Clipper is visible.
End


Function PeakClipperAssembly()
// Synopsis: creates the Peak Clipper. 
// Details: - 
// Parameters: - 
// Return Value(s): NaN
// Side effects: 
//               Creates the control panel
// Error message(s): - 
//
	Variable x0Point, y0Point, x1Point, y1Point
	
	GetWindow/Z $KS_MAIN_PANEL_NAME, wsizeOuter
	
	x0Point = V_left + ((K_PC_XOFFSET_PIX / ScreenResolution) * 72)      // Absolute graph dimensions are given in points instead of pixels, but it is
	y0Point = V_top + ((K_PC_YOFFSET_PIX / ScreenResolution) * 72)       // more convenient to use pixels as general units becouse other absolute dimensions 
	x1Point = x0Point + ((K_PC_WIDTH_PIX / ScreenResolution) * 72)       // are given in pixels(e.g. control dimensions and positions, control panel 
	y1Point = y0Point + ((K_PC_HEIGHT_PIX / ScreenResolution) * 72)      // dimensions etc.). Therefore it is necessary to convert the pixel units to point units. 
	
	String name = KS_PEAK_CLIPPER_NAME
	
	Display/W=(x0Point,y0Point,x1Point,y1Point)/HIDE=1/K=3/N=$name as "Peak Clipper"
	Controlbar/R K_PC_CTRL_BAR_WIDTH_PIX
	
	DFREF work_BGD = $KS_F_WORK_BGDCORR
	DFREF workRatio = $KS_F_WORK_RATIO
	DFREF Main = $KS_F_MAIN
	SVAR NormMode = Main:gStrNormMode
	
	if (StringMatch(NormMode, "Ratio") == 1)
		DispGraphs(LB_Util#GetWaveRefsDFR(workRatio, 1), KS_PEAK_CLIPPER_NAME)      // Display the Ratio corrected waves. 
	else
		DispGraphs(LB_Util#GetWaveRefsDFR(work_BGD, 1), KS_PEAK_CLIPPER_NAME)       // Display the background corrected waves. 
	endif
	
	GroupBox mainFrame, win=$name, pos={540,0}, size={K_PC_CTRL_BAR_WIDTH_PIX,K_PC_HEIGHT_PIX}, frame=0
	
	Variable group0_start = 0
	
	Button clear,win=$name,pos={590,group0_start+10},size={100,27},disable=0,title="Clear", proc=LB_PeakClipper#ClearProc
	
	Variable group1_start = group0_start + K_GROUP0_SIZE
		
	GroupBox delSelectedFrame, win=$name, pos={550,group1_start}, size={180,85}, frame=1, title="Delete Selected Peak"
	
	PopupMenu peaks_del,win=$name, pos={564,group1_start+25}, size={152,20}, mode=1, bodyWidth=152
	PopupMenu peaks_del,value=LB_PeakClipper#MyPopupList("peaks_del")//, proc=LB_PeakClipper#Peaks_delProc
	
	Button delSel,win=$name,pos={590,group1_start+55},size={100, 20},disable=0,title="Del Selected", proc=LB_PeakClipper#delSelProc
	
	Variable group2_start = group1_start + K_GROUP1_SIZE
	
	GroupBox checkFrame, win=$name, pos={550,group2_start}, size={180,25}, frame=1
	
	CheckBox showTreats, win=$name,pos={580,group2_start+5},size={78,20},title="Show treatments",value=0,mode=0,proc=LB_PeakClipper#ShowTreatsProc
	
	Variable group3_start = group2_start + K_GROUP2_SIZE
	
	GroupBox linkPeaksFrame, win=$name, pos={550,group3_start}, size={180,115}, frame=1, title="Link Peaks to Treatments"
	
	PopupMenu peaks_link,win=$name, pos={564,group3_start+25}, size={152,20}, mode=1, bodyWidth=152
	PopupMenu peaks_link,value=LB_PeakClipper#MyPopupList("peaks_link")
	
	PopupMenu treats,win=$name, pos={564,group3_start+55}, size={152,20}, mode=1, bodyWidth=152
	PopupMenu treats,value=LB_PeakClipper#MyPopupList("treats")
	
	Button link, win=$name, pos={590,group3_start+85},size={100, 20},disable=0,title="Link", proc=LB_PeakClipper#LinkButtonProc
	
	Variable group4_start = group3_start + K_GROUP3_SIZE
	
	Button prev,win=$name,pos={564,group4_start},size={75,20},disable=0,title="< Prev", proc=LB_PeakClipper#SwitchButtonProc
	
	Button next,win=$name,pos={641,group4_start},size={75,20},disable=0,title="Next >", proc=LB_PeakClipper#SwitchButtonProc
	
	Button done,win=$name,pos={590,group4_start+30},size={100,27},disable=0,title="Done", proc=LB_PeakClipper#DoneButtonProc
	
	SetWindow $name hide = 0                                               // The panel is hidden till it is built up fully, so the initial
	                                                                       // changes cannot be seen. It's more fancy in this way. :)
	
	SetWindow $name, hook(MyHook)=LB_PeakClipper#PeakClipperHook           // Install window hook.
End


Static Function ClearProc(ctrlName) : ButtonControl
// Synopsis: 
// Details: 
// Parameters: 
//              String ctrlName: the name of the control, which called the function. 
// Return Value(s): NaN
// Side effects: 
//               
// Error message(s):
//                   
	String ctrlName
	
	DFREF PeakClipperPack = $KS_F_PEAK_CLIPPER_PACK
	NVAR Counter = PeakClipperPack:gVarCount
	WAVE Clicks = PeakClipperPack:Clicks
	
	String actWinName = GetVisibleWinName()
	
	if (Counter > 0)
		SetDrawLayer/W=$actWinName/K ProgAxes                          // Clear the temporary markers. 
		SetDrawLayer/W=$actWinName UserFront
		Counter = 0
		Clicks = 0
	endif
End


Static Function DelSelProc(ctrlName) : ButtonControl
// Synopsis: 
// Details: 
// Parameters: 
//              String ctrlName: the name of the control, which called the function. 
// Return Value(s): NaN
// Side effects: 
//               
// Error message(s):
//                   
	String ctrlName
	
	ControlInfo/W=$KS_PEAK_CLIPPER_NAME peaks_del
	
	if (!StringMatch(S_Value, "Peak_*"))
		return 0
	endif
	
	RemovePeak(GetVisibleWinName(), V_Value - 1)        // Numbering of V_Value starts from 1. 
	
	PopupMenu peaks_del,win=$KS_PEAK_CLIPPER_NAME, mode = 1    // Update the popup menus displaying peaks. 
	PopupMenu peaks_link,win=$KS_PEAK_CLIPPER_NAME, mode = 1
	
	return 0
End


Static Function ShowTreatsProc(CtrlName,checked) : CheckBoxControl
// Synopsis: 
// Details: 
// Parameters: 
//              String ctrlName: the name of the control, which called the function. 
//              Variable checked: 0 if the checkbox isn't checked, 1 if it's checked. 
// Return Value(s): 0
// Side effects: 
//               
// Error message(s):
//
	String CtrlName
	Variable checked
	
	String subWinList = ChildWindowList(KS_PEAK_CLIPPER_NAME)
	Variable i = 0

	do
		String item = StringFromList(i, subWinList)
		
		if (StringMatch(item, "") == 1)
			break
		endif
		
		String actWinName = KS_PEAK_CLIPPER_NAME + "#" + item
	
		if (checked)
			TreatGlobal(actWinName)
		else
			SetDrawLayer/W=$actWinName/K ProgBack
			SetDrawLayer/W=$actWinName UserFront
		endif
		
		i += 1
	while (1)
End


Static Function LinkButtonProc(ctrlName) : ButtonControl
// Synopsis: Procedure for the peak linking ("Link") button. 
// Details: 
// Parameters: 
//              String ctrlName: the name of the control, which called the function. 
// Return Value(s): 0
// Side effects: 
//               
// Error message(s):
// 
	String ctrlName
	
	DFREF work_Peaks = $KS_F_WORK_PEAKS
	DFREF work_Fo = $KS_F_WORK_FO
	DFREF dfSave = GetDataFolderDFR()
	DFREF Main = $KS_F_MAIN
	SVAR NormMode = Main:gStrNormMode
	
	ControlInfo/W=$KS_PEAK_CLIPPER_NAME peaks_link
	
	if (!StringMatch(S_Value, "Peak_*"))
		return 0
	endif
	
	Variable serialNo = V_Value - 1
	
	ControlInfo/W=$KS_PEAK_CLIPPER_NAME treats
	String treatVal = S_Value
	
	String expr = GetMainTraceName(GetVisibleWinName()) + "_P" + num2str(serialNo) + "(_*)([[:alpha:]]*)(_*)([[:alpha:]]*)"
	
	SetDataFolder work_Peaks
	
	String selectedWaves = GrepList(WaveList("*", ";", ""), expr)
	
	Variable i
	for (i = 0; i < ItemsInList(selectedWaves); i += 1)
		WAVE aWave = $StringFromList(i, selectedWaves)
		
		if (StringMatch(StringByKey("TREAT_LINK", note(aWave)), "") == 1)
			Note/K aWave, SortList(note(aWave) + "TREAT_LINK:" + treatVal + ";", ";", 16)
		else
			Note/K aWave, ReplaceStringByKey("TREAT_LINK", note(aWave), treatVal)
		endif
		
	endfor
	
	if (StringMatch(NormMode, "dF/Fo") == 1)
		
		SetDataFolder work_Fo
		
		selectedWaves = GrepList(WaveList("*", ";", ""), expr)
		
		for (i = 0; i < ItemsInList(selectedWaves); i += 1)
			WAVE aWave = $StringFromList(i, selectedWaves)
			
			if (StringMatch(StringByKey("TREAT_LINK", note(aWave)), "") == 1)
				Note/K aWave, SortList(note(aWave) + "TREAT_LINK:" + treatVal + ";", ";", 16)
			else
				Note/K aWave, ReplaceStringByKey("TREAT_LINK", note(aWave), treatVal)
			endif
			
		endfor
		
	endif
	
		SetDataFolder dfSave
		
		MarkPeaks(GetVisibleWinName())                                    // Update the peak markings in the current graph window. 
		
	return 0
End


Static Function SwitchButtonProc(ctrlName) : ButtonControl
// Synopsis: Procedure for the graph switching buttons (eg. Prev, Next)
// Details: 
// Parameters: 
//              String ctrlName: the name of the control, which called the function. 
// Return Value(s): NaN
// Side effects: 
//               Swithces the displayed graphs in the main window. 
//               Resets the mouse click counter. 
// Error message(s):
//                   
	String ctrlName
	
	String subWinList = ChildWindowList(KS_PEAK_CLIPPER_NAME)
	Variable activeInd = GetVisibleWinIndex(subWinList, hostWinName = KS_PEAK_CLIPPER_NAME)
	String actWinName = KS_PEAK_CLIPPER_NAME + "#" + StringFromList(activeInd, subWinList)
	
	DFREF PeakClipperPack = $KS_F_PEAK_CLIPPER_PACK
	NVAR counter = PeakClipperPack:gVarCount
	
	if (StringMatch(ctrlName, "prev") == 1)
		
		if (activeInd == 0)                                            // If the active subwindow is the first, start from the last. 
			activeInd += ItemsInList(subWinList) - 1
		else
			activeInd -= 1
		endif
		
		SetDrawLayer/W=$actWinName/K ProgAxes                          // Clear the temporary markers. 
		SetDrawLayer/W=$actWinName UserFront
		
		SetWindow $actWinName, hide = 1                                // Hide the active subwindow. 
		
		actWinName = KS_PEAK_CLIPPER_NAME + "#" + StringFromList(activeInd, subWinList)
		SetWindow $actWinName, hide = 0                                // Unhide the previous subwindow. 
		
		counter = 0                                                    // Reset the click counter. 
		
	elseif (StringMatch(ctrlName, "next") == 1)
		
		if (activeInd == ItemsInList(subWinList) - 1)                  // If the active subwindow is the last, start from the first.
			activeInd = 0
		else
			activeInd += 1
		endif
		
		SetDrawLayer/W=$actWinName/K ProgAxes                          // Clear the temporary markers. 
		SetDrawLayer/W=$actWinName UserFront
		
		SetWindow $actWinName, hide = 1                                // Hide the active subwindow.
		
		actWinName = KS_PEAK_CLIPPER_NAME + "#" + StringFromList(activeInd, subWinList)
		SetWindow $actWinName, hide = 0                                // Unhide the previous subwindow. 
		
		counter = 0                                                    // Reset the click counter. 
		
	endif
	
	PopupMenu peaks_del,win=$KS_PEAK_CLIPPER_NAME, mode = 1                  // Update the popup menus displaying peaks and treatments. 
	PopupMenu peaks_link,win=$KS_PEAK_CLIPPER_NAME, mode = 1
	PopupMenu treats,win=$KS_PEAK_CLIPPER_NAME, mode = 1
	
	return 0
End


Static Function DoneButtonProc(ctrlName) : ButtonControl
// Synopsis: procedure for the "Done" button in the Peak Clipper. 
// Details: 
//           Hides the Peak Clipper panel. 
//           Enables the "Make the Labbook" button in the Labbook Control Panel.  
// Parameters: 
//             String ctrlName: the name of the control, which called the function.  
// Return Value(s): NaN 
// Side effects: see above. 
// Error message(s):
//
	String ctrlName
	
	SetWindow $KS_PEAK_CLIPPER_NAME, hide = 1
	
	Button ButtonLabbook,win=$KS_MAIN_PANEL_NAME,disable=0
	
	return 0
End


Static Function PeakClipperHook(s)
// Synopsis: This function controls all the special behaviour of the Peak Clipper Panel. 
// Details: 
//          A perpendicular dashed line is drawn on the active graph in the actual position of the mouse (mousemoved event), and the position of the
//              mouse (relative to the x axis) is signed adjacent to the line as well. 
//          The left click of the mouse is handeled as follows(mouse down and mouse up) event: 
//              - Single click: it is handeled by the MouseClickProc(windowName, ...) function. See below it's API for further details. 
//              - Double mouse clicks: The default graph behaviour (summoning the Modify Graph Appearence menu) PLUS the firs click of 
//                                   the MouseClickProc(windowName, ...). It should be avoided, becouse of this two sided action. The 
//                                   Modify Graph Appearence dialog can be reached via the contextual menu by right clicking. This is
//                                   the suggested workflow. 
//              - Left button held down for > 1s : The default graph behaviour (adjacent to a trace to drag and offset it). 
//          The right click of the mouse: The default graph behaviour. 
//          Resize event: prevents the resizing by immediately resetting the Peak Clipper Panel to its original dimensions. 
//          Kill vote event: performs the DoneButtonProc(ctrlName) operation, see below. 
//          If the Panel is visible (show event), the Make the Labbook button on the Labbokk Panel is disabled. 
// Parameters: 
//              STRUCT WMWinHookStruct $s: contains all the necessary information about the events related to the panel. 
// Return Value(s): 
//                    0: if the event wasn't handled. 
//                    1: if the event was handled. 
// Side effects: 
//                See the comments in the body of the function's code. 
// Error message(s): -
//
	STRUCT WMWinHookStruct &s
	
	Variable rVal = 0
	
	DFREF PeakClipperPack = $KS_F_PEAK_CLIPPER_PACK
	NVAR tick_d = PeakClipperPack:gVarTick_d
	NVAR count = PeakClipperPack:gVarCount
	
	GetWindow $s.winName, psize                                         // Returns the position of the plot area relative to the graph's top left corner 
	Variable pleft = V_left                                             // in the variables V_left, V_right, V_top, V_bottom. The units are points. 
	Variable pright = V_right
	Variable ptop = V_top
	Variable pbottom = V_bottom
	
	Variable mouseLocPoint_h = (s.mouseLoc.h / ScreenResolution) * 72   // The mouse coordinates are returned in pixels, it is necessary to 
	Variable mouseLocPoint_v = (s.mouseLoc.v / ScreenResolution) * 72   // convert them to point units. 
	
	GetAxis/W=$s.winName/Q bottom                                       // Returns the min and max values of the bottom axis in the variables V_min and V_max. 
	
	Variable xAxisRelPos = V_min + (((mouseLocPoint_h - pLeft) / (pRight - pLeft)) * (V_max - V_min)) // Calculates the position of the cursor relative to
	                                                                                                  // the x axis. Units are the x axis units.
	switch(s.eventCode)
		
		case 3: // mouse down
			
			tick_d = ticks
			break
			
		case 4: // mousemoved
			
			if (StringMatch(s.winName, KS_PEAK_CLIPPER_NAME))                         // This prevents the calling of the mouse moved case if the
				return rVal                                                            // mouse is not above a subwindow. 
			endif
			
			if (mouseLocPoint_h > pleft && mouseLocPoint_h < pright && mouseLocPoint_v > ptop && mouseLocPoint_v < pbottom - 1)
				// If I use mouseLocPoint_v < pbottom, then there is a minor bug if the pointer is at pbottom, so I use pbottom - 1 instead. 
				
				SetDrawLayer/W=$s.winName/K ProgFront
				SetDrawEnv/W=$s.winName dash=3, fillpat=0, fillbgc=(65535,65535,65535), linefgc=(40960,65280,16384), linethick=1, xcoord=abs, ycoord=prel	
				SetDrawEnv/W=$s.winName fsize=8, textrgb=(40960,65280,16384),textyjust=2, save
				DrawLine/W=$s.winName mouseLocPoint_h, -0.05, mouseLocPoint_h, 1
				
				if (count == 0) 
					DrawText/W=$s.winName mouseLocPoint_h + 2, -0.05, num2str(xAxisRelPos)
				else
					DrawText/W=$s.winName mouseLocPoint_h + 2, -0.05, num2str(xAxisRelPos)
				endif	
				
				SetDrawLayer/W=$s.winName UserFront
				
			else

				SetDrawLayer/W=$s.winName/K ProgFront
				SetDrawLayer/W=$s.winName UserFront
				
			endif
			
		break
			
		case 5: // mouse up
			
			Variable tick_curr = ticks
			
			if (mouseLocPoint_h > pleft && mouseLocPoint_h < pright && mouseLocPoint_v > ptop && mouseLocPoint_v < pbottom)
				
				if ((tick_curr - tick_d) / 60 > 1)             // This part prevents the following action from execution if a trace is to be offset. 
					return rVal
				endif
				
				MouseClickProc(s.winName, xAxisRelPos)
			
			endif
			
			break
			
		case 6: // resize
			
			// This prevents the resizing of the Panel since - as far as I know - there is no option to disable the resizing of graphs. 
			// The width of the control bar must be subtracted from the overall width. 
			Variable width_point = ((K_PC_WIDTH_PIX - K_PC_CTRL_BAR_WIDTH_PIX) / ScreenResolution) * 72  
			Variable height_point = (K_PC_HEIGHT_PIX / ScreenResolution) * 72
			ModifyGraph/W=$s.winName width=width_point, height=height_point
			break
			
		case 16: // show
			
			Button ButtonLabbook,win=$KS_MAIN_PANEL_NAME,disable=2
			break
			
		case 17: // killVote
			
			DoneButtonProc("done")
			break
			
	endswitch
	
	return rVal
End


Static Function KillPeakClipper()
// Synopsis: takes the necessary steps to kill the dFperFpPanel. 
// Details: Kills the panel and the related folders with all the related data. 
//          Enables the dependent controls in the Main Panel. 
// Parameters: - 
// Return Value(s): -
// Side effects: see above. 
// Error message(s): - 
//
	KillWindow $KS_PEAK_CLIPPER_NAME
	
	KillDataFolder $KS_F_PEAK_CLIPPER_PACK
	
	ControlInfo/W=$KS_MAIN_PANEL_NAME main                                // The visibility of these controls are set according to the state of the tabcontrol in 
	if (V_Value == 3)                                                     // which they are installed. 
		SetVariable SetNumTreat_main3,win=$KS_MAIN_PANEL_NAME, disable = 0
	endif
	
	Button ButtonLabbook,win=$KS_MAIN_PANEL_NAME, disable = 0
End



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                       UTILITY FUNCTIONS                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


Static Function DispGraphs(workSet, hostName)
// Synopsis: Displays a set of waves individually in a host window. 
// 	Details: It should be used for the Peak Clipper panel assembly, as it designed for that. 
//          The waves are passed by a wave reference wave (WRW). The waves in the WRW must be
//              consistent. The function does not checks for consistency! 
//          The first displayed wave's graph will be initially  visible, the others will be hidden. 
// Parameters: 
//              WAVE/WAVE workSet: wave reference wave containing the references of waves to be displayed. 
//              String hostName: the name of the host window into wich the waves will be displayed. 
// Return Value(s): 
//                  NaN
// Side effects: see above. 
// Error message(s): -
//
	WAVE/WAVE workSet
	String hostName
	
	Variable right_point = (K_PC_SUB_WIDTH_PIX / ScreenResolution) * 72          // Variables for the graph's right bottom edge whithin the host window in points. 
	Variable bottom_point = (K_PC_SUB_HEIGHT_PIX / ScreenResolution) * 72
	
	DFREF Main = $KS_F_MAIN
	SVAR NormMode = Main:gStrNormMode
	SVAR WorkExpID = Main:gStrWorkExpID
	
	Variable i
	for (i = 0 ; i < numpnts(workSet) - 1; i += 2) 
		
		WAVE WaveToDisplay = workSet[i]
		WAVE Timeval = workSet[i + 1]
		
		String graphName = "w_" + WorkExpID + "_" + num2str(i / 2)
		
		Display/HOST=$hostName/N=$graphName/W=(0,0,right_point,bottom_point) WaveToDisplay vs Timeval
		if (StringMatch(NormMode, "Ratio") == 1)
			Label/W=$hostName#$graphName left, "\f01\Z10Ratio"
		else
			Label/W=$hostName#$graphName left, "\f01\Z10ROI-BGD (Arbitrary Units)"
		endif
		Label/W=$hostName#$graphName bottom, "\f01\Z10Time (s)"
		Textbox/C/N=text1/A=MT/B=1/E=1 "Trace_" + num2str(i / 2)
		ModifyGraph/W=$hostName#$graphName rgb=(0,0,0)
		
		if (i == 0)
			SetWindow $hostName#$graphName hide=0, needUpdate=1
		else
			SetWindow $hostName#$graphName hide=1, needUpdate=1
		endif
		
	endfor
End


Static Function/S MyPopupList(Name)
// Synopsis: 
// Details: 
// Parameters: 
//              
// Return Value(s): 
//                  
// Side effects: 
//               
// Error message(s):
//
	String Name
	
	DFREF dfSave = GetDataFolderDFR()
	String list = ""
	Variable num, i
	
	strswitch (Name)
		case "peaks_del":
		case "peaks_link":
			
			String subWinList = ChildWindowList(KS_PEAK_CLIPPER_NAME)
			Variable activeInd = GetVisibleWinIndex(subWinList, hostWinName = KS_PEAK_CLIPPER_NAME)
			String yTraceName = ReplaceString("w_", StringFromList(activeInd, subWinList), "")
			
			SetDataFolder $KS_F_WORK_PEAKS
			num = ItemsInList(WaveList(yTraceName + "_*", ";", "")) / 2
			
			if (num == 0)
				SetDataFolder dfSave
				return "There's no peak"
			endif
			
			for(i = 0; i < num; i += 1)
				list += "Peak_" + num2str(i) + ";"
			endfor
			break
		
		case "treats":
			
			DFREF expDetails = $KS_F_EXP_DETAILS
			NVAR numOfTreats = expDetails:gVarNumOfTreat
			
			if (numOfTreats == 0)
				return "Spontaneous"
			endif
			
			for(i = 0; i < numOfTreats; i += 1)
				list += "Treat_" + num2str(i) + ";"
			endfor
			
			list += "Spontaneous;"
			break
			
	endswitch
	
	SetDataFolder dfSave
	
	return list
End


Static Function MouseClickProc(windowName, mousePosXRel)
// Synopsis: this function controls the behavior of left mouse clicks within the Peak Clipper panel's graphs. It should be
//           called from the Peak Clipper panel's hook function
// Details: 
//          If the wave normalization method is none, or Ratio: 
//              The firts click specifies the start of the peak, while the second specifies the end of it. At the second click the 
//              so specified peak is saved in a temporary folder as an x-y wave pair. 
//          If the  wave normalization method is dF/Fo: 
//              The first click specifies the start of the peak, the second specifies the end of the baseline (Fo) and the third 
//              specifies the end of the peak. The start of the baseline is the start of the peak itself. 
//              At the third click the so specified peak is saved in a temporary folder as an x-y wave pair. 
//          Temporary markers are drawn after each click in the specified position, and they are deleted after the last click. 
//          The naming convention is the following for a sample y wave: 13425000_1_P0 (<Experiment ID>_<ROI ID>_P<Peak ID>).
//              For the corresponding x wave: 13425000_1_P0_tv (<Experiment ID>_<ROI ID>_P<Peak ID>_tv).
// Parameters: 
//              String windowName: the full name of the active (sub)window in which the the function is to be called 
//                                 (see subwindow syntax in the Igor Manual). 
//              Variable mousePosXRel: the horizontal position of the mouse on the graph with respect to the X axis. 
// Return Value(s): 
//                   NaN
// Side effects: 
//               The peaks_del and peaks_link popup menus are updated as a new peak is specified.  
// Error message(s): -
//	
	String windowName
	Variable mousePosXRel
	
	DFREF PeakClipperPack = $KS_F_PEAK_CLIPPER_PACK
	DFREF Main = $KS_F_MAIN
	SVAR NormMode = Main:gStrNormMode
	NVAR count = PeakClipperPack:gVarCount
	WAVE Clicks = PeakClipperPack:Clicks
	
	SetDrawLayer/W=$windowName ProgAxes
	SetDrawEnv/W=$windowName fillpat=0, linebgc=(0,65280,0), linefgc=(0,65280,0), linethick=1, xcoord=bottom, ycoord=prel	
	SetDrawEnv/W=$windowName fsize=8, textrgb=(0,65280,0),textyjust=2, save
	
	String yTraceName
	
	if (StringMatch(NormMode, "dF/Fo") == 1)
		
		if (numpnts(Clicks) == 2)
			Redimension/N=3 Clicks
		endif
		
		switch (count) // Different actions are performed, depending on the sequential number of klicks. 
			
			case 0:
				
				Clicks[0] = mousePosXRel
				DrawLine/W=$windowName mousePosXRel, 0, mousePosXRel, 1
//				DrawText/W=windowName mousePosXRel, 0, num2str(mousePosXRel)
				count += 1
				break
				
			case 1:
				
				Clicks[1] = mousePosXRel
				DrawLine/W=$windowName mousePosXRel, 0, mousePosXRel, 1
				count += 1
				break
								
			case 2:
				
				Clicks[2] = mousePosXRel
				
				Sort Clicks, Clicks
								
				SetDrawLayer/W=$windowName/K ProgAxes
				
				yTraceName = ReplaceString("w_", windowName[strsearch(windowName, "#", 0)+1, inf], "")
				WAVE yWave = TraceNameToWaveRef(windowName, yTraceName)
				WAVE xWave = XWaveRefFromTrace(windowName, yTraceName)
				
				AddPeak(windowName, yWave, xWave, Clicks[0], Clicks[2], foEnd_x = Clicks[1])
				
				ControlUpdate/W=$KS_PEAK_CLIPPER_NAME peaks_del            // Update the popup menus displaying peaks. 
				ControlUpdate/W=$KS_PEAK_CLIPPER_NAME peaks_link
				
				count = 0
				Clicks = 0
				break
				
		endswitch
	
	else
		
		if (numpnts(Clicks) == 3)
			Redimension/N=2 Clicks
		endif
		
		switch (count) // Different actions are performed, depending on the sequential number of klicks. 
			
			case 0:
				
				Clicks[0] = mousePosXRel
				DrawLine/W=$windowName mousePosXRel, 0, mousePosXRel, 1
//				DrawText/W=windowName mousePosXRel, 0, num2str(mousePosXRel)
				count += 1
				break
				
			case 1:
				
				Clicks[1] = mousePosXRel
				
				Sort Clicks, Clicks
								
				SetDrawLayer/W=$windowName/K ProgAxes
				
				yTraceName = ReplaceString("w_", windowName[strsearch(windowName, "#", 0)+1, inf], "")
				WAVE yWave = TraceNameToWaveRef(windowName, yTraceName)
				WAVE xWave = XWaveRefFromTrace(windowName, yTraceName)
				
				AddPeak(windowName, yWave, xWave, Clicks[0], Clicks[1])
								
				ControlUpdate/W=$KS_PEAK_CLIPPER_NAME peaks_del            // Update the popup menus displaying peaks. 
				ControlUpdate/W=$KS_PEAK_CLIPPER_NAME peaks_link
				
				count = 0
				Clicks = 0
				break
				
		endswitch
		
	endif
	
	SetDrawLayer/W=$windowName UserFront
End


Static Function AddPeak(windowName, yWave, xWave, peakStart_x, peakEnd_x, [foEnd_x])
// Synopsis: Saves a new peak on the specified trace with the specified parameters (peakStart_x, peakEnd_x, foEnd_x)
// Details: 
//          
// Parameters: 
//             String windowName: the full name of the active (sub)window of the trace on which the peak is about to be  
//                                saved(see subwindow syntax in the Igor Manual).
//             WAVE yWave: the yWave of the trace on which the peak is about to be saved. 
//             WAVE xWave: the xWave of the trace on which the peak is about to be saved. 
//             Variable peakStart_x: the position of the start of the peak relative to the xWave's x coordinates. 
//             Variable peakEnd_x: the position of the end of the peak relative to the xWave's x coordinates. 
//             Variable foEnd_x (OPTIONAL): the position of the peak's baseline relative to the xWave's x coordinates. 
//                                          Only used when the wave normalization method is dF/Fo. 
// Return Value(s): NaN
// Side effects: 
//               
// Error message(s): -
//                   
	String windowName
	WAVE yWave
	WAVE xWave
	Variable peakStart_x
	Variable peakEnd_x
	Variable foEnd_x
	
	DFREF work_Peaks = $KS_F_WORK_PEAKS
	DFREF work_Fo = $KS_F_WORK_FO
	DFREF dfSave = GetDataFolderDFR()
	
	Variable peakStart_p = LB_Util#FindClosestValue(peakStart_x, xWave)
	Variable peakEnd_p = LB_Util#FindClosestValue(peakEnd_x, xWave)
	Variable serialNo
	String addToNote
	
	if (!ParamIsDefault(foEnd_x))
	
		SetDataFolder work_Fo
		
		serialNo = GetPeakSerial(NameOfWave(yWave), peakStart_x)
		
		Variable foEnd_p = LB_Util#FindClosestValue(foEnd_x, xWave)
		
		String foY_name = NameOfWave(yWave) + "_P" + num2str(serialNo) + "_Fo"
		String foX_name = foY_name + KS_TIMEVAL_ENDING
		
			
		ShiftPeaks(NameOfWave(yWave), serialNo)
		
		Duplicate/O/R=[peakStart_p, foEnd_p] yWave, $foY_name
		Duplicate/O/R=[peakStart_p, foEnd_p] xWave, $foX_name
		
		WAVE foY = $foY_name
		Note/K foY, SortList(note(yWave) + "PEAK_ID:" + num2str(serialNo) + ";", ";", 16)
		
		WAVE foX = $foX_name
		Note/K foX, SortList(note(yWave) + "PEAK_ID:" + num2str(serialNo) + ";", ";", 16)
		
		Variable fo = mean(foY)
		
	endif
		
	SetDataFolder work_Peaks
	
	serialNo = GetPeakSerial(NameOfWave(yWave), peakStart_x)
	
	String yWave_name = NameOfWave(yWave) + "_P" + num2str(serialNo)
	String xWave_name = yWave_name + KS_TIMEVAL_ENDING
	
	ShiftPeaks(NameOfWave(yWave), serialNo)
	
	Duplicate/O/R=[peakStart_p, peakEnd_p] yWave, $yWave_name
	Duplicate/O/R=[peakStart_p, peakEnd_p] xWave, $xWave_name
	
	WAVE peak_Y = $yWave_name
	
	if (!ParamIsDefault(foEnd_x))
		
		// Calculate dF/Fo
		peak_Y = (peak_Y - fo) / fo                                                              
		
		// Create addition to the wavenote, which contains unique data for each peak (if dF/Fo is calculated, the start and endponints of 
		//    the Fo is saved in the respective fields). 
		addToNote = "PEAK_ID:" + num2str(serialNo) + ";" + "FO_START:" + num2str(peakStart_x) + ";" + "FO_END:" + num2str(FoEnd_x) + ";"
	
	else
		// Create addition to wavenote which contains unique data for this specific peak (just the peak id is necessary). 
		addToNote = "PEAK_ID:" + num2str(serialNo) + ";"
		
	endif
	
	Note/K peak_Y, SortList(note(yWave) + addToNote, ";", 16)
	
	WAVE peak_X = $xWave_name
	Note/K peak_X, SortList(note(yWave) + addToNote, ";", 16)
	
	SetDataFolder dfSave
	
	MarkPeaks(windowName)
End


Static Function RemovePeak(windowName, serialNo)
// Synopsis: 
// Details: 
// Parameters: 
//              
// Return Value(s): 
//                  
// Side effects: 
//               
// Error message(s):
//
	String windowName
	Variable serialNo
	
	DFREF dfSave = GetDataFolderDFR()
	DFREF work_Peaks = $KS_F_WORK_PEAKS
	DFREF work_Fo = $KS_F_WORK_FO
	DFREF Main = $KS_F_MAIN
	SVAR NormMode = Main:gStrNormMode
	
	String traceList = TraceNameList(windowName, ";", 1)
	String expr = GetMainTraceName(windowName) + "_P" + num2str(serialNo) + "(_*)([[:alpha:]]*)(_*)([[:alpha:]]*)"
	String selectedWaves = ""
	Variable i
	
	// If the normalization mode is dF/Fo, remove the selected peak's Fo trace from the graphs. 
	// Delete the corresponding Fo waves from as well. 
	if (StringMatch(NormMode, "dF/Fo") == 1)
		
		String foTraceName = StringFromList(0, GrepList(traceList, expr))
		
		if (strlen(foTraceName) == 0)
			Abort "In DelSelProc(ctrlName): \rMissing trace!"
		endif
		
		RemoveFromGraph/W=$windowName $foTraceName
		
		SetDataFolder work_Fo
		
		selectedWaves = GrepList(WaveList("*", ";", ""), expr)
		
		for (i = 0; i < ItemsInList(selectedWaves); i += 1)
			WAVE aWave = $StringFromList(i, selectedWaves)
			KillWaves/Z aWave
		endfor
		
		ShiftPeaks(GetMainTraceName(windowName), serialNo, backwards = 1)
		
	endif
	
	// Delete the waves belonging to the selected peak. 
		
	SetDataFolder work_Peaks
	
	selectedWaves = GrepList(WaveList("*", ";", ""), expr)
	
	for (i = 0; i < ItemsInList(selectedWaves); i += 1)
		WAVE aWave = $StringFromList(i, selectedWaves)
		KillWaves/Z aWave
	endfor
	
	ShiftPeaks(GetMainTraceName(windowName), serialNo, backwards = 1)
	
	SetDataFolder dfSave

	MarkPeaks(windowName)
End


Static Function ShiftPeaks(traceName, index [,backwards])
// Synopsis: 
// Details: 
// Parameters: 
//              
// Return Value(s): 
//                  
// Side effects: 
//               
// Error message(s):
//
	String traceName
	Variable index
	Variable backwards
	
	if (ParamIsDefault(backwards))
		backwards = 0
	endif
	
	if (backwards != 0 && backwards != 1)
		Abort "In ShiftPeaks(traceName, ...): \rWrong value for parameter!"
	endif
	
	String peakList = SortList(WaveList(traceName + "_*", ";", ""), ";", 16)
	
	if (strlen(peakList) == 0)
		return NaN	
	endif
	
	Variable i
	String item, newName, expID, year, month, day, serial, roiID, peakID, rest
	String expr = "([[:digit:]]{2})([[:alpha:]]{1}|[[:digit:]]{1})([[:digit:]]{2})([[:digit:]]{3})_([[:digit:]]+)_P([[:digit:]]+)(.*)"
	
	if (backwards)
		
		i = 0
		do
			if (i >= ItemsInList(peakList))
				break
			endif
			
			item = StringFromList(i, peakList)
			SplitString/E=(expr) item, year, month, day, serial, roiID, peakID, rest
			
			if (str2num(peakID) > index)
				
				expID = year + month + day + serial
				
				newName = expID + "_" + roiID + "_P" + num2str(str2num(peakID) - 1) + rest
				
				WAVE aWave = $item
				Rename aWave, $newName                                                          // Rename the wave.
				Note/K aWave, ReplaceNumberByKey("PEAK_ID", note(aWave), str2num(peakID) - 1)   // Update the PEAK_ID in the wavenote. 
				
			endif
			
			i += 1
		while (1)
		
	else
	
		i = ItemsInList(peakList) - 1
		do
			item = StringFromList(i, peakList)
			SplitString/E=(expr)item, year, month, day, serial, roiID, peakID, rest
			
			if (numtype(str2num(peakID)) == 2 || str2num(peakID) < index)
				break
			endif
			
			expID = year + month + day + serial
			
			newName = expID + "_" + roiID + "_P" + num2str(str2num(peakID) + 1) + rest
						
			WAVE aWave = $item
			Rename aWave, $newName                                                          // Rename the wave. 
			Note/K aWave, ReplaceNumberByKey("PEAK_ID", note(aWave), str2num(peakID) + 1)   // Update the PEAK_ID in the wavenote. 
			
			i -= 1
		while (1)
		
	endif	
End


Static Function MarkPeaks(windowName)
// Synopsis: 
// Details: 
// Parameters: 
//              
// Return Value(s): 
//                  
// Side effects: 
//               
// Error message(s):
//
	String windowName
	
	DFREF work_Peaks = $KS_F_WORK_PEAKS
	DFREF work_Fo = $KS_F_WORK_FO
	DFREF dfSave = GetDataFolderDFR()
	DFREF Main = $KS_F_MAIN
	SVAR NormMode = Main:gStrNormMode
	
	String traceName = GetMainTraceName(windowName)
	
	// Getting the sotred list of the timeval waves of all the peaks in the graph. 
	SetDataFolder work_Peaks
	String peakTvList = SortList(WaveList(traceName + "_P*" + KS_TIMEVAL_ENDING, ";", ""), ";", 16)
	
	// If the graph has no peaks in it, just clear the UserBack layer and return. 
	if (strlen(peakTvList) == 0)
		SetDrawLayer/W=$windowName/K UserBack
		SetDrawLayer/W=$windowName UserFront
		SetDataFolder dfSave
		return NaN	
	endif
	
	Variable i = 0
	String peakTvItem, foItem, foTvItem, text
	
	// Setting the draw environment for the graph. 
	SetDrawLayer/W=$windowName/K UserBack
	SetDrawEnv/W=$windowName fillpat=0, linebgc=(0,0,0), linefgc=(0,0,0), linethick=1, dash=3,xcoord=bottom, ycoord=prel	
	SetDrawEnv/W=$windowName fsize=8, textrgb=(0,0,0),textyjust=2, save
	
	if (StringMatch(NormMode, "dF/Fo") == 1)
		
		// Getting the sotred list of the Fo waves. 
		SetDataFolder work_Fo
		String foFullList = SortList(WaveList(traceName + "_P*", ";", ""), ";", 16)                
		String foTvList = ListMatch(foFullList, "*" + KS_TIMEVAL_ENDING)
		String foList = ListMatch(foFullList, "!*" + KS_TIMEVAL_ENDING)
		
		// Getting the sorted list of the displayed traces in the graph.
		String displayedTraces = SortList(TraceNameList(windowName,";",1), ";", 16)
		
		do
			peakTvItem = StringFromList(i, peakTVList)
			foItem = StringFromList(i, foList)
			foTvItem = StringFromList(i, foTvList)
			
			if (strlen(peakTvItem) == 0 || strlen(foItem) == 0 || strlen(foTvItem) == 0)
				break
			endif
			
			WAVE fo = $foItem
			WAVE foTv = $foTvItem
			
			SetDataFolder work_Peaks
			
			WAVE peakTv = $peakTvItem
			
			SetDataFolder work_Fo
			
			if (strsearch(displayedTraces, foItem, 0) == -1)
				AppendToGraph/W=$windowName/C=(65280,0,0) fo vs foTv
			endif
			
			if (StringMatch(StringByKey("TREAT_LINK", note(peakTv)), "") == 1)
				text = "Peak_" + StringByKey("PEAK_ID", note(peakTv))
			else
				text = "Peak_" + StringByKey("PEAK_ID", note(peakTv)) + " ->\r" + StringByKey("TREAT_LINK", note(peakTv))
			endif
			
			DrawLine/W=$windowName peakTv[0], 0, peakTv[0], 1
			DrawLine/W=$windowName peakTv[numpnts(peakTv) - 1], 0, peakTv[numpnts(peakTv) - 1], 1
			DrawText/W=$windowName peakTv[0], 0.05, text
			
			i += 1
		while(1)
	
	else

		do
			peakTvItem = StringFromList(i, peakTVList)
			
			if (strlen(peakTvItem) == 0)
				break
			endif
					
			WAVE peakTv = $peakTvItem
			
			if (StringMatch(StringByKey("TREAT_LINK", note(peakTv)), "") == 1)
				text = "Peak_" + StringByKey("PEAK_ID", note(peakTv))
			else
				text = "Peak_" + StringByKey("PEAK_ID", note(peakTv)) + " ->\r" + StringByKey("TREAT_LINK", note(peakTv))
			endif
			
			DrawLine/W=$windowName peakTv[0], 0, peakTv[0], 1
			DrawLine/W=$windowName peakTv[numpnts(peakTv) - 1], 0, peakTv[numpnts(peakTv) - 1], 1
			DrawText/W=$windowName peakTv[0], 0.05, text
			
			i += 1
		while(1)
		
	endif
	
	SetDataFolder dfSave
	SetDrawLayer/W=$windowName UserFront
End


Static Function TreatGlobal(windowName)
// Synopsis: displays the details of the treatment(s) of a wave in the wave's graph. 
// Details: 
//          Draws rectangles on the named graph according to the displayed wave's treatments. 
//          It also puts a legend in the rectangle's top left corner with the name of the treatment. 
//          Only the named wave's treatments (each) will be displayed. 
//          If window name is specified the named window will be brought front first and the function will be 
//          executed on that window.
// Parameters: 
//             WAVE displayedWave: the wave of which treatment's is to be displayed. 
//             String WindowName: 
// Return Value(s): - 
// Side effects: 
//               See details. 
// 
	String windowName
	
	DFREF expDetails = $KS_F_EXP_DETAILS
	NVAR NumOfTreat = expDetails:gVarNumOfTreat                      // 1 based!
	
	Variable i
	Variable PrevTreat_end = 0, fpatt = 4, YPercent = 0
	
	String treatName, startName, endName
	SetDrawLayer/W=$windowName ProgBack
	SetDrawEnv/W=$windowName xcoord=bottom,fillfgc=(34816,34816,34816),fsize=9, fillpat=fpatt, linethick=0.00, textyjust=2, save
	
	for (i = 0; i < NumOfTreat; i +=1)
		
		treatName = "gStrTreat" + num2str(i) + "_name"
		startName = "gVarTreat" + num2str(i) + "_start"
		endName = "gVarTreat" + num2str(i) + "_end"
		
		SVAR ActTreat_name = expDetails:$treatName
		NVAR ActTreat_start = expDetails:$startName
		NVAR ActTreat_end = expDetails:$endName
		
		if (ActTreat_start > ActTreat_end)                // If the start time is greater than the end time, exchange them. 
			NVAR ActTreat_start = expDetails:$endName
			NVAR ActTreat_end = expDetails:$startName
		endif
		
		// For clearity, if there are overlapping treatments, the latter one's rectangle's height will be reduced
		// and it's color will be darkend. 
		if (ActTreat_start < PrevTreat_end)																					
			fpatt -= 1
			SetDrawEnv/W=$windowName fillpat = fpatt, save
			Ypercent += 0.05
		endif
		
		DrawRect/W=$windowName ActTreat_start, Ypercent, ActTreat_end, 1
		DrawText/W=$windowName ActTreat_start, Ypercent, ActTreat_name
		
		PrevTreat_end = ActTreat_end
	endfor
	
	SetDrawLayer/W=$windowName UserFront
End


Static Function/S GetVisibleWinName()
// Synopsis: Returns the full name of the visible (topmost) graph in the Peak Clipper Panel. 
// Details: The full name contains the window's parent window's names as well (see subwindow syntax in the Igor Manual). 
// Parameters: - 
// Return Value(s): 
//                  A string containing the full name of the visible (topmost) graph in the Peak Clipper Panel. 
// Side effects: - 
// Error message(s): - 
//

	return KS_PEAK_CLIPPER_NAME + "#" + StringFromList(GetVisibleWinIndex(ChildWindowList(KS_PEAK_CLIPPER_NAME), hostWinName = KS_PEAK_CLIPPER_NAME),ChildWindowList(KS_PEAK_CLIPPER_NAME))
End


Static Function GetVisibleWinIndex(windowList, [hostWinName])
// Synopsis: Returns the index of the (first) visible window in the passed list of window names. 
// Details: 
//           If no visible windows are found, -1 is returned.
//           If hostWinName is specified, the window names in the list are searced within the 
//               host window's subwindows. 
//           The windowList can be easily generated eg. by the WinList or ChildWinList functions. 
// Parameters: 
//              String windowList: a semicolon-delimited list of window names. 
//              String hostWinName: contains the name of the host window. 
// Return Value(s): See above. 
// Side effects: - 
// Error message(s): - 
//
	String windowList
	String hostWinName
	
	Variable i = 0
	String objName, actWin
	do
		objName = StringFromList(i, windowList)
		if (StringMatch(objName, "") == 1)
			break
		endif
		
		if (ParamIsDefault(hostWinName))
			actWin = objName
		else
			actWin = hostWinName + "#" + objName
		endif
		
		GetWindow $actWin, hide
		
		if (V_Value == 0)
			return i
		endif
		
		i += 1
	while(1)
	
	return -1
End


Static Function GetPeakSerial(traceName, startX)
// Synopsis: Returns a serial number for a peak given it's startX value relative the other peaks belonging to the specified trace. 
// Details: -
// Parameters: 
//              String traceName: the name of the trace on which the peak is marked out. 
//              Variable startX: the start value of the peak in the 
// Return Value(s): 
//                  The serial number of the specified peak relative to the other existing peaks on the trace. 
// Side effects: -
// Error message(s): -
//
	String traceName
	Variable startX
	
	String traceList = SortList(WaveList(traceName + "_P*" + KS_TIMEVAL_ENDING, ";", ""), ";", 16)
	
	Variable i = 0
	String item
	
	do
		item = StringFromList(i, traceList)
		
		if (strlen(item) == 0)
			break
		endif
		
		WAVE aWave = $item
		
		if (startX < aWave[0])
			return i
		endif
		
		i += 1
	while (1)
	
	return i
End


Static Function/S GetMainTraceName(windowName)
// Synopsis: Returns the name of the main trace in the specified window. 
// Details: The main trace is the one on which the peaks are specified. 
// Parameters: 
//              String windowName: the name of the secified window. 
// Return Value(s): 
//                  see above. 
// Side effects: -
// Error message(s): - 
//
	String windowName
	
	String traceName = windowName[strsearch(windowName,"#w_",0) + 3, inf]
	
	return traceName
End



// **********
// Sample API
// **********
// Synopsis: 
// Details: 
// Parameters: 
//              
// Return Value(s): 
//                  
// Side effects: 
//               
// Error message(s):
//                   
//



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                       TESTING FUNCITONS                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Function TestCutOut()
//	
//	DFREF dest = root:
//	DFREF work = $KS_F_WORK_BGDCORR
//	WAVE xWave = work:exp_timeval
//	WAVE yWave = work:exp_1
//	Variable startX = 1600
//	Variable endX = 561
//	String xwName = "foo_timeval"
//	String ywName = "foo_1"
//	
//	CutOutWaveXY(xWave, yWave, startX, endX, dest, xwName, ywName)
//End


//Function TestShift(val)
//	Variable val
//	
//	SetDataFolder root:Packages:dFperFoPanel:work_Peaks
//	
//	ShiftPeaks("12906002_0", val)
//	
//	SetDataFolder root:
//End



//Function TestSerial(val)
//	Variable val
//	SetDataFolder root:Packages:dFperFoPanel:work_Peaks
//	
//	Print num2str(GetPeakSerial("12906002_0", val))
//	
//	SetDataFolder root: 
//End