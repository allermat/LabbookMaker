#pragma rtGlobals = 3			// Use modern global access method and strict wave access.
#pragma IgorVersion = 6.30   // The above pragma is valid from IGOR 6.30
#pragma version = 1.0.0
#pragma ModuleName = LB_Main	// I used a Regular Module to avoid name conflicts. 




//********************************************************************************************************************************************************************
//********************************************************************************************************************************************************************
//
// Labbook Maker: Main Panel Functions
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

 
// Naming conventions: 
//                     - All constant names are written with capitals. 
//                     - The names of constant variables start with K_. 
//                     - The names of constant strings start with KS_. 
//                     - Instead of " " use "_". 
//                     - "F_" means, that the constant contains a folder path string. 
//
Static Constant K_NB_GRAPH_WIDTH = 420
Static Constant K_NB_GRAPH_HEIGHT = 300
Static Constant K_MAIN_PANEL_BASE = 20
Static Constant K_MAIN_PANEL_WIDTH = 395
Static Constant K_MAIN_PANEL_HEIGHT = 520
Static Constant K_MAX_NUM_OF_TREAT = 4
Static Constant K_GRAPH_CTRL_BAR_HEIGHT_PIX = 30

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
Static StrConstant KS_F_WORK_RATIO = "root:Packages:LabbookControlPanel:work_Ratio"
Static StrConstant KS_F_WORK_PEAKS = "root:Packages:PeakClipper:work_Peaks"
Static StrConstant KS_F_WORK_FO = "root:Packages:PeakClipper:work_Fo_data"
////////////////////////////////////////////////////////////

Static StrConstant KS_COCHLEA_EXPSITE_LIST = "Whole Cochlea;Basal Corti;Basal SG;Middle Corti;Middle SG;Apical Corti;Apical SG;"
Static StrConstant KS_HIPPOCAMPUS_EXPSITE_LIST = "CA1;CA3;DG"
Static StrConstant KS_MAIN_PANEL_NAME = "LabbookControlPanel"
Static StrConstant KS_MOUSE_STRAINLIST = "BALB/C;C57/BL6;CD1;DFNB59-PEJ;DFNB9-OTO;SUCLA2;"
Static StrConstant KS_PEAK_CLIPPER_NAME = "PeakClipper"
Static StrConstant KS_RAT_STRAINLIST = "Whistar;"
Static StrConstant KS_TIMEVAL_ENDING = "_tv"
Static StrConstant KS_CALFILE_NAME = "fura_calibrations.txt"

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                 MENUS AND IGOR HOOK                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


Static Function BeforeExperimentSaveHook(refNum, fileNameStr, pathNameStr, fileTypeStr, fileCreatorStr, fileKind)
// Synopsis: Kills the LabbookControlPanel if the experiment is about to be saved. 
// Description: 
//              It is necessary to let the user to open a labbook file regardless of the version of the 
//                  LabbookControlPanel. If the panel is open as the experiment is saved, then as it is opened
//                  at any time later, it is possible that errors will occur becouse of the changings in the 
//                  LabbookControlPanel's code. In this way a labbook file can be opened even without the 
//                  LabbookControlPanel having installed. 
//              As its name suggests this function will be called right before an experiment is saved, 
//                  for details see the corresponding section of the User Defined Hook Functions part of the IGOR manual.
// Parameters: 
//              See the corresponding section of the User Defined Hook Functions part of the IGOR manual. 
// Return Value(s): 
//                  0 if we didn't handle the event. 
//                  1 if we did. 
// Side effects: Kills the LabbookControlPanel
//  
	Variable refNum
	String fileNameStr
	String pathNameStr
	String fileTypeStr
	String fileCreatorStr
	Variable fileKind
	
	DoWindow $KS_PEAK_CLIPPER_NAME
	if (V_Flag != 0)                           // If the window is present or present but hidden. 
		DoWindow/K $KS_PEAK_CLIPPER_NAME
	endif
	
	DoWindow $KS_MAIN_PANEL_NAME
	if (V_Flag != 0)                           // If the window is present or present but hidden. 
		DoWindow/K $KS_MAIN_PANEL_NAME
	endif
	
	return 0
End


// Add a menu item to display the control panel.
Menu "Labbook", dynamic
	"Show Labbook Maker",/Q, LB_Main#DisplayLabbookControlPanel()
	PeakClipperMenu(),/Q, LB_PeakClipper#DisplayPeakClipper()
	"-"
	Submenu "Options"
		
		AddCaCalibrationMenu(),/Q, LB_Main#AddCalibration()
		DelCaCalibrationMenu(),/Q, LB_Main#DeleteCalibration()
	
	End
End


Function/S PeakClipperMenu()
	ControlInfo/W=$KS_MAIN_PANEL_NAME CheckClip
	if (V_value)
		return "Show Peak Clipper"
	else
		return ""
	endif
End


Function/S AddCaCalibrationMenu()
	DoWindow $KS_MAIN_PANEL_NAME
	if (V_flag != 0)
		return "Add a New Calcium Calibration"
	else
		return ""
	endif
End


Function/S DelCaCalibrationMenu()
	DoWindow $KS_MAIN_PANEL_NAME
	if (V_flag != 0)
		return "Delete a Calcium Calibration"
	else
		return ""
	endif
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                 THE FUNCTIONS FOR BUILDING AND CONTROLLING THE MAIN PANEL                                                        //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


Static Function DisplayLabbookControlPanel()
// Synopsis:  This is the top level routine which makes sure that the globals
//            and their enclosing data folders exist and then makes sure that
//            the control panel is displayed
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
	
	// If the experiment is a formerly saved labbook throw a message and terminate execution. 
	if (CheckIfSavedLabbook())
		Abort "This experiment seems to be a formerly saved labbook. \rDo not modify a saved labbook! \rIf any change is necessary make a new one. \rLabbook Maker terminates execution. \rSorry! "
	endif
	
//	// If the experiment is a formerly saved labbook check if the version of it is identical with the current Labbook Package version. 
//	if (!CheckLabbookPackageVersion())
//		Abort "Can't open Labbook Maker becouse the version of this labbook \ris different from the current Labbook Maker version. "
//	endif
	
	// If the panel is already created, just bring it to the front.
	DoWindow/F $KS_MAIN_PANEL_NAME
	if (V_Flag != 0)
		return 0
	endif
	
	// Create data folders for raw data and experiment details
	NewDataFolder/O $KS_F_RAW
	NewDataFolder/O/S $KS_F_EXP_DETAILS
	
	// Create global variables for experiment details
	String bgdMode = StrVarOrDefault(":gStrBGDmode", "whole trace")
	String/G gStrBGDmode = bgdMode
	
	String Cut_sol = StrVarOrDefault(":gStrCut_sol", "Na-Gluk-HCS")
	String/G gStrCut_sol = Cut_sol
	
	String Dye_name = StrVarOrDefault(":gStrDye_name", "")
	String/G gStrDye_name = Dye_name
	
	String Exp_code = StrVarOrDefault(":gStrExp_code", "")
	String/G gStrExp_code = Exp_code
	
	String Exp_note = StrVarOrDefault(":gStrExp_note", "")
	String/G gStrExp_note = Exp_note	
	
	String Exp_site = StrVarOrDefault(":gStrExp_site", "Whole Cochlea")
	String/G gStrExp_site = Exp_site
		
	String Exp_sol = StrVarOrDefault(":gStrExp_sol", "Na-Gluk-HCS")
	String/G gStrExp_sol = Exp_sol
	
	String Exp_temp = StrVarOrDefault(":gStrExp_temp", "Room Temperature")
	String/G gStrExp_temp = Exp_temp
	
	String Genotype = StrVarOrDefault(":gStrGenotype", "+/+")
	String/G gStrGenotype = Genotype
	
	String Loading_proc = StrVarOrDefault(":gStrLoading_proc", "")
	String/G gStrLoading_proc = Loading_proc
	
	String Prep_type = StrVarOrDefault(":gStrPrep_type", "Hemicochlea")
	String/G gStrPrep_type = Prep_type
		
	String Reg_num = StrVarOrDefault(":gStrReg_num", "")
	String/G gStrReg_num = Reg_num
	
	String ROI_Names = StrVarOrDefault(":gStrROI_Names", "")
	String/G gStrROI_Names = ROI_Names
	
	String Sex = StrVarOrDefault(":gStrSex", "male")
	String/G gStrSex = Sex
	
	String Species = StrVarOrDefault(":gStrSpecies", "mouse")
	String/G gStrSpecies = Species
	
	String Strain = StrVarOrDefault(":gStrStrain", "BALB/C")
	String/G gStrStrain = Strain
	
	String Unique_num = StrVarOrDefault(":gStrUnique_num", "")
	String/G gStrUnique_num = Unique_num
	
	String WaveNote = StrVarOrDefault(":gStrWaveNote", "")
	String/G gStrWaveNote = WaveNote
	
	Variable Age = NumVarOrDefault(":gVarAge", 0)
	Variable/G gVarAge = Age
	
	Variable Exp_start = NumVarOrDefault(":gVarExp_start", 0)
	Variable/G gVarExp_start = Exp_start
	
	Variable NumOfTreat = NumVarOrDefault(":gVarNumOfTreat", 0)
	Variable/G gVarNumOfTreat = NumOfTreat
	
	// Create a data folder in Packages to store globals.
	NewDataFolder/O root:Packages
	NewDataFolder/O/S $KS_F_MAIN
	NewDatafolder/O $KS_F_WORK_BGDCORR
	NewDatafolder/O $KS_F_WORK_RATIO
	
	// Create global variables used by the control panel.	
	String BGD0Name = StrVarOrDefault(":gStrBGD0Name", "")
	String/G gStrBGD0Name = BGD0Name
	
	String BGD1Name = StrVarOrDefault(":gStrBGD1Name", "")
	String/G gStrBGD1Name = BGD1Name
	
	String Calib = StrVarOrDefault(":gStrCalib", "")
	String/G gStrCalib = Calib
	
	String Chan0List = StrVarOrDefault(":gStrChan0List", "")
	String/G gStrChan0List = Chan0List
	
	String Chan1List = StrVarOrDefault(":gStrChan1List", "")
	String/G gStrChan1List = Chan1List
	
	String Chan0MatchStr = StrVarOrDefault(":gStrChan0MatchStr", "")
	String/G gStrChan0MatchStr = Chan0MatchStr
	
	String Chan1MatchStr = StrVarOrDefault(":gStrChan1MatchStr", "")
	String/G gStrChan1MatchStr = Chan1MatchStr
	
	String NormMode = StrVarOrDefault(":gStrNormMode", "BGD")
	String/G gStrNormMode = NormMode
	
	String PopupCut_sol = StrVarOrDefault(":gPopupCut_sol", "Na-Gluk-HCS;Na-Gluk-HCS-1.4Ca;NaCl-HCS;")
	String/G gPopupCut_sol = PopupCut_sol
	
	String PopupExp_site = StrVarOrDefault(":gPopupExp_site", KS_COCHLEA_EXPSITE_LIST)
	String/G gPopupExp_site = PopupExp_site
	
	String PopupExp_sol = StrVarOrDefault(":gPopupExp_sol", "Na-Gluk-HCS;Na-Gluk-HCS-1.4Ca;NaCl-HCS;")
	String/G gPopupExp_sol = PopupExp_sol
	
	String PopupExp_temp = StrVarOrDefault(":gPopupExp_temp", "Room Temperature;36 °C;")
	String/G gPopupExp_temp = PopupExp_temp
	
	String PopupGenotype = StrVarOrDefault(":gPopupGenotype", "+/+;+/-;-/-;?;")
	String/G gPopupGenotype = PopupGenotype
	
	String PopupLoadingCC_unit = StrVarOrDefault(":gPopupLoading_unit", "uM;mM;w/v%;")
	String/G gPopupLoadingCC_unit = PopupLoadingCC_unit
	
	String PopupLoading_proc = StrVarOrDefault(":gPopupLoading_proc", "Choose...;---;Bulk loading;Continuous perfusion;Electroporation;Micropipette loading;")
	String/G gPopupLoading_proc = PopupLoading_proc
	
	String PopupLoading_temp = StrVarOrDefault(":gPopupLoading_temp", "Room Temperature;36 °C;")
	String/G gPopupLoading_temp = PopupLoading_temp
	
	String PopupSex = StrVarOrDefault(":gPopupSex", "male;female;?;")
	String/G gPopupSex = PopupSex
	
	String PopupSpecies = StrVarOrDefault(":gPopupSpecies", "mouse;rat;")
	String/G gPopupSpecies = PopupSpecies
	
	String PopupStrain = StrVarOrDefault(":gPopupStrain", KS_MOUSE_STRAINLIST)
	String/G gPopupStrain = PopupStrain
	
	String PopupPrep_type = StrVarOrDefault(":gPopupPrep_type", "Hemicochlea;Hippocampus Slice;")
	String/G gPopupPrep_type = PopupPrep_type
	
	String sTreatFake = StrVarOrDefault(":gStrTreatFake", "")
	String/G gStrTreatFake = sTreatFake
	
	String TimevalName = StrVarOrDefault(":gStrTimevalName", "")
	String/G gStrTimevalName = TimevalName
	
	String WorkExpID = StrVarOrDefault(":gStrWorkExpID", "")
	String/G gStrWorkExpID = WorkExpID
	
	Variable BackgroundMode = NumVarOrDefault(":gVarBGDmode", 0)
	Variable/G gVarBGDmode = BackgroundMode
	
	Variable ChanNum = NumVarOrDefault(":gVarChanNum", 1)
	Variable/G gVarChanNum = ChanNum
	
	Variable CheckVal = NumVarOrDefault(":gVarCheckVal", 1)
	Variable/G gVarCheckVal = CheckVal
	
	Variable LB_Version = NumVarOrDefault(":gVarLB_Version", LB_Main#LabbookPackageVersion())
	Variable/G gVarLB_Version = LB_Version
	
	Variable vTreatFake = NumVarOrDefault(":gVarTreatFake", 0)
	Variable/G gVarTreatFake = vTreatFake
	
	WAVE/Z CalibW = CalibWave	
	
	if (!WaveExists(CalibW))
		Make/N=(1,6)/T CalibWave
		GetCalibrationData(CalibWave)
	endif
	
	// Create the control panel.
	LabbookControlPanel()
	SetWindow $KS_MAIN_PANEL_NAME, hook(MyHook)=LB_Main#LabbookControlPanelHook  // Install window hook
	
	DFREF work_Peaks = $KS_F_WORK_PEAKS                                      // If there is some peak data in the experiment, open the Peak Clipper Panel as well. 
	if (LB_Util#IsDataFolderEmpty(work_Peaks) == 0)
		CheckBox CheckdFperFo, win=$KS_MAIN_PANEL_NAME, value=1, disable = 2
		LB_PeakClipper#DisplayPeakClipper()
		LB_PeakClipper#DoneButtonProc("done")
	endif
	 
	PopLoadProc_main2_SideEffects(Loading_proc)                          // If the panel is reopened (after saving the experiment), this ensures, that the proper
	TabProc("main", 0)                                                   // loading method settings are visible. TabProc brings front the first tab in this case. 
	
	DFREF raw = $KS_F_RAW
	if (LB_Util#IsDataFolderEmpty(raw))
		SetDataFolder raw
	else
		SetDataFolder root:
	endif
	
End


Static Function LabbookControlPanel()
// Synopsis: This is the panel creation function. 
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
	
	Variable screenWidth, screenHeight, panelWidth = K_MAIN_PANEL_WIDTH, panelHeight = K_MAIN_PANEL_HEIGHT
	LB_Util#GetScreenDimsPix(screenWidth, screenHeight)
	
	Variable x0,y0
	x0 = (screenWidth - panelWidth) / 2
	y0 = (screenHeight - panelHeight) / 7
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(x0, y0, x0 + panelWidth, y0 + panelHeight)/K=3/N=$KS_MAIN_PANEL_NAME as "Labbook Maker"
	ModifyPanel fixedSize=1, noEdit=1
	
	DFREF ExpDetails = $KS_F_EXP_DETAILS
	DFREF MainPack = $KS_F_MAIN
	
	SVAR Species = ExpDetails:gStrSpecies
	SVAR Strain = ExpDetails:gStrStrain
	SVAR Genotype = ExpDetails:gStrGenotype
	SVAR Sex = ExpDetails:gStrSex
	NVAR Age = ExpDetails:gVarAge
	SVAR RegNum = ExpDetails:gStrReg_num
	SVAR UniqueNum = ExpDetails:gStrUnique_num
	SVAR PrepType = ExpDetails:gStrPrep_type
	SVAR Cut_sol = ExpDetails:gStrCut_sol
	SVAR Exp_sol = ExpDetails:gStrExp_sol
	SVAR Exp_temp = ExpDetails:gStrExp_temp
	NVAR Exp_start = ExpDetails:gVarExp_start
	SVAR Exp_site = ExpDetails:gStrExp_site
	SVAR Loading_proc = ExpDetails:gStrLoading_proc
	NVAR NumOfTreat = ExpDetails:gVarNumOfTreat
		
	String name = KS_MAIN_PANEL_NAME
	Variable base = K_MAIN_PANEL_BASE
	
	TabControl main,win=$name,pos={22,base},size={351,318},proc=LB_Main#TabProc,tabLabel(0)="Animal"
	TabControl main,win=$name,tabLabel(1)="Preparation",tabLabel(2)="Dye"
	TabControl main,win=$name,tabLabel(3)="Treatment",tabLabel(4)="Notes", value = 0
	
	PopupMenu PopSpecies_main0,win=$name,pos={37,base+35}, title="Species: ", value = #"root:Packages:LabbookControlPanel:gPopupSpecies"
	PopupMenu PopSpecies_main0,win=$name, proc = LB_Main#PopupSetProc, mode=1, popValue = Species
	
	PopupMenu PopStrain_main0,win=$name,pos={37,base+70}, size={270,20}, title="Strain: ", value = #"root:Packages:LabbookControlPanel:gPopupStrain"
	PopupMenu PopStrain_main0,win=$name, proc = LB_Main#PopupSetProc, mode=1, popValue = Strain
	
	PopupMenu PopGen_main0,win=$name,pos={37,base+105}, size={270,20}, title="Genotype: ", value = #"root:Packages:LabbookControlPanel:gPopupGenotype"
	PopupMenu PopGen_main0,win=$name, proc = LB_Main#PopupSetProc, mode=1, popValue = Genotype
	
	PopupMenu PopSex_main0,win=$name,pos={37,base+140}, size={270,20}, title="Sex: ", value = #"root:Packages:LabbookControlPanel:gPopupSex"
	PopupMenu PopSex_main0,win=$name, proc = LB_Main#PopupSetProc, mode=1, popValue = Sex
	
	SetVariable SetAge_main0,win=$name,pos={37,base+175}, size={168, 20}, title="Age (days): "
	SetVariable SetAge_main0,win=$name,limits={0,200,1}, value = Age
	
	SetVariable SetRegNum_main0,win=$name,pos={37,base+210}, size={270, 20}, title="Registration number: ", value = RegNum
	
	SetVariable SetUnNum_main0,win=$name,pos={37,base+245}, size={270, 20}, title="Unique number: ", value = UniqueNum

	PopupMenu PopPrepType_main1,win=$name,pos={37,base+35}, disable=1, title="Preparation Type: ",value = #"root:Packages:LabbookControlPanel:gPopupPrep_type"
	PopupMenu PopPrepType_main1,win=$name, proc = LB_Main#PopupSetProc, mode=1, popValue = PrepType
	
	PopupMenu PopCutSol_main1,win=$name,pos={37,base+70}, disable=1, title="Cutting Solution: ", value = #"root:Packages:LabbookControlPanel:gPopupCut_sol"
	PopupMenu PopCutSol_main1,win=$name, proc = LB_Main#PopupSetProc, mode=1, popValue = Cut_sol
	
	PopupMenu PopExpSol_main1,win=$name,pos={37,base+105}, disable=1, title="Experiment Solution: ", value = #"root:Packages:LabbookControlPanel:gPopupExp_sol"
	PopupMenu PopExpSol_main1,win=$name, proc = LB_Main#PopupSetProc, mode=1, popValue = Exp_sol
	
	PopupMenu PopExpTemp_main1,win=$name,pos={37,base+140}, disable=1, title="Experiment Temperature: ", value = #"root:Packages:LabbookControlPanel:gPopupExp_temp"
	PopupMenu PopExpTemp_main1,win=$name, proc = LB_Main#PopupSetProc, mode=1, popValue = Exp_temp
	
	SetVariable SetExpStart_main1,win=$name,pos={37,base+175}, disable=1, size={270, 20}, title="Experiment Start Time (min): "
	SetVariable SetExpStart_main1,win=$name,limits={0,10000,1}, value = Exp_start
	
	PopupMenu PopExpSite_main1,win=$name,pos={37,base+210}, disable=1, title="Experiment Site: ", value = #"root:Packages:LabbookControlPanel:gPopupExp_site"
	PopupMenu PopExpSite_main1,win=$name, proc = LB_Main#PopupSetProc, mode=1, popValue = Exp_site
	
	Button ButtonSetROIs_main1,win=$name,pos={250,base+210},size={100,20},disable=0,title="Set ROI Names", proc=LB_Main#ButtonSetROIs_main1Proc
	
	PopupMenu PopDye_main2,win=$name,pos={37,base+35}, disable=1, title="Dye Name: ", value = LB_Main#PopDyeList()
	PopupMenu PopDye_main2,win=$name, proc = LB_Main#PopDye_main2Proc, mode=1
	
	PopupMenu PopLoadProc_main2,win=$name,pos={37,base+70}, disable=1, title="Loading Procedure: ", value = #"root:Packages:LabbookControlPanel:gPopupLoading_proc"
	PopupMenu PopLoadProc_main2,win=$name, proc = LB_Main#PopLoadProc_main2Proc, mode=1, popValue = Loading_proc
	
	SetVariable SetNumTreat_main3,win=$name,pos={37,base+35}, disable=1, size={180, 20}, title="Number of Treatments: ", proc= LB_Main#NumOfTreatProc
	SetVariable SetNumTreat_main3,win=$name,limits={0,K_MAX_NUM_OF_TREAT,1}, value = NumOfTreat
	
	TabControl treat_main3,win=$name,pos={26,base+70},size={343,244},disable=1, proc=LB_Main#TabProc,tabLabel(0)="#0", tabLabel(1)="#1",tabLabel(2)="#2"
	TabControl treat_main3,win=$name,tabLabel(3)="#3",value = 0
	
	SetVariable SetTreatName_treat0_main3,win=$name,pos={41,base+105}, disable=1, size={250, 20}, title="Treatment Name: "
	SetVariable SetTreatName_treat0_main3,win=$name, value = MainPack:gStrTreatFake
	
	SetVariable SetStartTime_treat0_main3,win=$name,pos={41,base+140}, disable=1, size={150, 20}, title="Start Time (s): "
	SetVariable SetStartTime_treat0_main3,win=$name,limits={0,10000,1}, value = MainPack:gVarTreatFake
	
	SetVariable SetEndTime_treat0_main3,win=$name,pos={41,base+175}, disable=1, size={150, 20}, title="End Time (s): "
	SetVariable SetEndTime_treat0_main3,win=$name,limits={0,10000,1}, value = MainPack:gVarTreatFake
	
	SetVariable SetTreatName_treat1_main3,win=$name,pos={41,base+105}, disable=1, size={250, 20}, title="Treatment Name: "
	SetVariable SetTreatName_treat1_main3,win=$name,value = MainPack:gStrTreatFake
	
	SetVariable SetStartTime_treat1_main3,win=$name,pos={41,base+140}, disable=1, size={150, 20}, title="Start Time (s): "
	SetVariable SetStartTime_treat1_main3,win=$name,limits={0,10000,1}, value = MainPack:gVarTreatFake
	
	SetVariable SetEndTime_treat1_main3,win=$name,pos={41,base+175}, disable=1, size={150, 20}, title="End Time (s): "
	SetVariable SetEndTime_treat1_main3,win=$name,limits={0,10000,1}, value = MainPack:gVarTreatFake
	
	SetVariable SetTreatName_treat2_main3,win=$name,pos={41,base+105}, disable=1, size={250, 20}, title="Treatment Name: "
	SetVariable SetTreatName_treat2_main3,win=$name,value = MainPack:gStrTreatFake
	
	SetVariable SetStartTime_treat2_main3,win=$name,pos={41,base+140}, disable=1, size={150, 20}, title="Start Time (s): "
	SetVariable SetStartTime_treat2_main3,win=$name,limits={0,10000,1}, value = MainPack:gVarTreatFake
	
	SetVariable SetEndTime_treat2_main3,win=$name,pos={41,base+175}, disable=1, size={150, 20}, title="End Time (s): "
	SetVariable SetEndTime_treat2_main3,win=$name,limits={0,10000,1}, value = MainPack:gVarTreatFake
	
	SetVariable SetTreatName_treat3_main3,win=$name,pos={41,base+105}, disable=1, size={250, 20}, title="Treatment Name: "
	SetVariable SetTreatName_treat3_main3,win=$name,value = MainPack:gStrTreatFake
	
	SetVariable SetStartTime_treat3_main3,win=$name,pos={41,base+140}, disable=1, size={150, 20}, title="Start Time (s): "
	SetVariable SetStartTime_treat3_main3,win=$name,limits={0,10000,1}, value = MainPack:gVarTreatFake
	
	SetVariable SetEndTime_treat3_main3,win=$name,pos={41,base+175}, disable=1, size={150, 20}, title="End Time (s): "
	SetVariable SetEndTime_treat3_main3,win=$name,limits={0,10000,1}, value = MainPack:gVarTreatFake
	
	NewNotebook/F=1/N=Notes/K=3/HOST=$KS_MAIN_PANEL_NAME/W=(26,base+35,366,base+312)
	SetWindow LabbookControlPanel#Notes hide=1, needUpdate=1
	
	Variable block1 = base + 328
	
	GroupBox GroupNormMode,win=$name,pos={22,block1+5}, size={190,30}, frame=1, title=""
	
	PopupMenu PopNormMode,win=$name,pos={30,block1+9},disable=0, mode=1, title="Normalization mode: ", value = LB_Main#PopNormModeList()
	PopupMenu PopNormMode,win=$name, proc = LB_Main#PopNormModeProc
	
	GroupBox GroupClip,win=$name,pos={238,block1+5}, size={135,30}, frame=1, title=""
	
	CheckBox CheckClip,win=$name,pos={260,block1+12},size={78,20},title="Clip peaks",value=0,mode=0,proc=LB_Main#CheckBoxProc
	
	Variable block2 = block1 + 55
	
	GroupBox GroupCorrections,win=$name,pos={22,block2}, size={350,55}, frame=1, title="Corrections"
	
	Button ButtonResetBGD,win=$name,pos={86,block2+25},size={100,20},disable=0,title="Reset BGD", proc=LB_Main#ResetBGDButtonProc
	
	Button ButtonDelPoints,win=$name,pos={208,block2+25},size={100,20},disable=0,title="Delete Points", proc=LB_Main#DeletePointsButtonProc
	
	Variable block3 = block2 + 65
	
	Button ButtonLabbook,win=$name,pos={97,block3},size={200,40},disable=0,title="Make the Labbook", proc=LB_Main#LabbookButtonProc
	
End


Static Function LabbookControlPanelHook(s)
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
	STRUCT WMWinHookStruct &s

	switch(s.eventCode)
		case 0: // Activate
		case 4: // Mouse moved
			
			DFREF working_DIR = $KS_F_WORK_BGDCORR
			DFREF raw = $KS_F_RAW
			DFREF imported = $KS_F_IMP_TRACES			
			
			if (CountObjectsDFR(raw, 1) == 0)                                          // Returns if no waves were loaded jet. 
				return 0
			endif
			
			if (DataFolderExists(KS_F_IMP_TRACES) && LB_Util#IsDataFolderEmpty(imported) == 0)
				return 0                                                                // Returns if OrderData was run before. 
			endif
						
			OrderData()
			UpdateBGDCorr()
			
			SetDataFolder root:
			
			break
	endswitch
	
	return 0 // If non-zero, we handled event and Igor will ignore it.
End


Static Function CheckBoxProc(CtrlName,checked) : CheckBoxControl
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
	String CtrlName
	Variable checked
	
	DFREF Main = $KS_F_MAIN
	SVAR NormMode = Main:gStrNormMode
	
	if (StringMatch(ctrlName, "CheckClip") == 1)
		
		DFREF work_BGDCorr = $KS_F_WORK_BGDCORR
		if (LB_Util#IsDataFolderEmpty(work_BGDCorr) == 1)                  // If no data were loaded throw an error message. 
			CheckBox CheckClip, win=$KS_MAIN_PANEL_NAME,value = 0           // Deselect the checkbox. 
			Abort "Please load some data to work on!\rUse any menu items of Data-> Load Waves->..."
		endif
		
		if (checked)
			
			PopupMenu PopNormMode,win=$KS_MAIN_PANEL_NAME, disable = 2
			Button ButtonResetBGD,win=$KS_MAIN_PANEL_NAME, disable = 2
						
			LB_PeakClipper#DisplayPeakClipper()
			
		else
			
			DFREF work_Peaks = $KS_F_WORK_PEAKS
			if (LB_Util#IsDataFolderEmpty(work_Peaks) == 0)              // If there is alredy some peak data, and the checkbox is about to be unchecked,
			                                                             // throw an alert.
				DoAlert 1, "This will delete all your Peak data! \rDo you want to proceed? "
				
				if (V_flag == 2)                                          // If No is clicked, just keep the checkbox selected. 
					
					CheckBox CheckClip, win=$KS_MAIN_PANEL_NAME, value = 1
					
				else                                                      // Otherwise kill the Peak Clipper panel and enable the nomalization mode choosing popup menu.
					
					if (StringMatch(NormMode, "dF/Fo") == 1)
						
						PopupMenu PopNormMode, win=$KS_MAIN_PANEL_NAME, mode = 1, disable = 0
						ControlInfo/W=$KS_MAIN_PANEL_NAME PopNormMode
						PopNormModeProc("PopNormMode",V_value,S_value)                         // Set the dependent popupmenu's global
						
						Button ButtonResetBGD,win=$KS_MAIN_PANEL_NAME, disable = 0
						
					else
						
						PopupMenu PopNormMode,win=$KS_MAIN_PANEL_NAME, disable = 0
						Button ButtonResetBGD,win=$KS_MAIN_PANEL_NAME, disable = 0
						
					endif
					
					LB_PeakClipper#KillPeakClipper()
					
				endif
				
			else                                                          // If there is no peak data, just kill the Peak Clipper panel and enable the nomalization 
			                                                              // mode choosing popup menu.
				if (StringMatch(NormMode, "dF/Fo") == 1)
						
						PopupMenu PopNormMode, win=$KS_MAIN_PANEL_NAME, mode = 1, disable = 0
						ControlInfo/W=$KS_MAIN_PANEL_NAME PopNormMode
						PopNormModeProc("PopNormMode",V_value,S_value)                         // Set the dependent popupmenu's global
						
						Button ButtonResetBGD,win=$KS_MAIN_PANEL_NAME, disable = 0
						
				else
					
					PopupMenu PopNormMode,win=$KS_MAIN_PANEL_NAME, disable = 0
					Button ButtonResetBGD,win=$KS_MAIN_PANEL_NAME, disable = 0
					
				endif
				
				LB_PeakClipper#KillPeakClipper()
				
			endif
			
		endif
		
	endif
	
	return 0
End


Static Function TabProc(ctrlName,tabNum) : TabControl
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
	String ctrlName
	Variable tabNum
	String postfix = GetTabPostfix(ctrlName)
	String controlsInATab= ControlNameList(KS_MAIN_PANEL_NAME,";","*" + postfix + "*")
	String curTabMatch= "*" + postfix + num2istr(tabNum) + "*"
	String controlsInCurTab= ListMatch(controlsInATab, curTabMatch)
	String controlsInOtherTabs=ListMatch(controlsInATab,"!"+curTabMatch)
	
	if (StringMatch(ctrlName, "main") == 1)
		ModifyControlList controlsInOtherTabs win=$KS_MAIN_PANEL_NAME, disable=1           // hide controls in other tabs
		ModifyControlList controlsInCurTab win=$KS_MAIN_PANEL_NAME, disable=0 			     // show controls in the current tab
		
		DFREF Main = $KS_F_MAIN
		DFREF BGDCorr = $KS_F_BGDCORR                                                      // The dye selection popup menu must be treated differently. 
		if (tabNum == 2 && LB_Util#IsDataFolderEmpty(BGDCorr) == 0)
			PopupMenu PopDye_main2,win=$KS_MAIN_PANEL_NAME, disable = 2
		endif
		
		ControlInfo/W=$KS_MAIN_PANEL_NAME CheckClip
		if (tabNum == 3 && V_Value == 1)
			SetVariable SetNumTreat_main3,win=$KS_MAIN_PANEL_NAME, disable = 2
		endif
		
		if (tabNum == 3)													                            // if tab3 is active it is necessary to run the
			ControlInfo/W=$KS_MAIN_PANEL_NAME treat_main3                                   // treattab controlling function. 
			TabProc("treat_main3", V_value)
		endif
		
		if (tabNum == 4)
			SetWindow LabbookControlPanel#Notes hide=0, needUpdate=1
		else
			SetWindow LabbookControlPanel#Notes hide=1, needUpdate=1
		endif
	
	elseif (StringMatch(ctrlName, "treat_main3") == 1)
		DFREF ExpDetails = $KS_F_EXP_DETAILS
		NVAR NumOfTreat = ExpDetails:gVarNumOfTreat
		ModifyControlList controlsInOtherTabs win=$KS_MAIN_PANEL_NAME, disable=1            // hide controls in other subtabs
		
		if (tabNum > (NumOfTreat - 1))									 							   // show or gray out the current subtab	
			ModifyControlList controlsInCurTab win=$KS_MAIN_PANEL_NAME, disable=2
		else 
			ModifyControlList controlsInCurTab win=$KS_MAIN_PANEL_NAME, disable=0
		endif
	
	endif
	
	return 0
End


Static Function PopupSetProc(ctrlName,popNum,popStr) : PopupMenuControl
// Synopsis: Sets the globals of the popup menus and accomplishes their side effect if they have any. 
// Details: -
// Parameters: 
//             String ctrlName: The name of the control activated. 
//             Variable popNum: The number of the menu item selected in the popup menu. 
//             String popStr: The name of the menu item selected in the popup menu. 
// Return Value(s): - 
// Side effects: 
//               See below the popupmenu's corresponding side effect functions. 
//
	String ctrlName
	Variable popNum
	String popStr
	
	String dfSave = GetDataFolder(1)
	SetDataFolder $KS_F_EXP_DETAILS
	
	// Set the globals controlled by popup menus
	strswitch (ctrlName)
		case "PopSpecies_main0":
			SVAR gStrTowrite = gStrSpecies
			PopSpecies_main0_SideEffects(popNum)
			break
		case "PopStrain_main0":
			SVAR gStrTowrite = gStrStrain
			break
		case "PopGen_main0":
			SVAR gStrTowrite = gStrGenotype
			break
		case "PopSex_main0":
			SVAR gStrTowrite = gStrSex
			break
		case "PopPrepType_main1":
			SVAR gStrTowrite = gStrPrep_type
			PopPrepType_main1_SideEffects(popNum)
			break
		case "PopCutSol_main1":
			SVAR gStrTowrite = gStrCut_sol
			break
		case "PopExpSol_main1":
			SVAR gStrTowrite = gStrExp_sol
			break
		case "PopExpTemp_main1":
			SVAR gStrTowrite = gStrExp_temp
			break
		case "PopExpSite_main1":
			SVAR gStrTowrite = gStrExp_site
			break
		case "PopLoadCcUnit_main2":
			SVAR gStrTowrite = gStrLoadingCC_unit
			break
		case "PopLoadTemp_main2":
			SVAR gStrTowrite = gStrLoading_temp
			break		
	endswitch
	
	gStrTowrite = popStr

	SetDataFolder dfSave
	
	return 0
End


Static Function PopSpecies_main0_SideEffects(popNum)
// Synopsis: Performs the Popup0_main0 pupup menu's side effects. 
// Details: 
//          The menu has a dependent pupup menu (PopStrain_main0). 
//          The dependent pupup menu's popup list will be set according to the
//              selected menu item. 
// Parameters: 
//              Variable popNum: The number of the menu item selected in the popup menu. 
// Return Value(s): -
// Side effects: see above. 
//
	Variable popNum
	DFREF Main = $KS_F_MAIN
	SVAR gPopupToSet = Main:gPopupStrain
	
	if (popNum == 2)
		gPopupToSet = KS_RAT_STRAINLIST                                          // Set the dependent popupmenu's popuplist
		ControlUpdate/W=$KS_MAIN_PANEL_NAME PopStrain_main0
		ControlInfo/W=$KS_MAIN_PANEL_NAME PopStrain_main0
		PopupSetProc ("PopStrain_main0",V_value,S_value)                         // Set the dependent popupmenu's global
		PopupMenu PopStrain_main0, win=$KS_MAIN_PANEL_NAME, mode = 1             // Reset the dependent popmenu's popvalue to 1
	else
		gPopupToSet = KS_MOUSE_STRAINLIST                                        // Set the dependent popupmenu's popuplist
		ControlUpdate/W=$KS_MAIN_PANEL_NAME PopStrain_main0
		ControlInfo/W=$KS_MAIN_PANEL_NAME PopStrain_main0
		PopupSetProc ("PopStrain_main0",V_value,S_value)                         // Set the dependent popupmenu's global
		PopupMenu PopStrain_main0, win=$KS_MAIN_PANEL_NAME, mode = 1             // Reset the dependent popmenu's popvalue to 1
	endif
End


Static Function PopPrepType_main1_SideEffects(popNum)
// Synopsis: Performs the PopPrepType_main1 pupup menu's side effects. 
// Details: 
//          The menu has a dependent pupup menu (PopExpSite_main1). 
//          The dependent pupup menu's popup list will be set according to the
//              selected menu item.
// Parameters: 
//              Variable popNum: The number of the menu item selected in the popup menu.
// Return Value(s): - 
// Side effects: see above. 
//
	Variable popNum
	DFREF Main = $KS_F_MAIN
	SVAR gPopupToSet = Main:gPopupExp_site
	
	if (popNum == 2)
		gPopupToSet = KS_HIPPOCAMPUS_EXPSITE_LIST                           // Set the dependent popupmenu's popuplist
		ControlUpdate/W=$KS_MAIN_PANEL_NAME PopExpSite_main1
		ControlInfo/W=$KS_MAIN_PANEL_NAME PopExpSite_main1
		PopupSetProc ("PopExpSite_main1",V_value,S_value)                         // Set the dependent popupmenu's global
		PopupMenu PopExpSite_main1, win=$KS_MAIN_PANEL_NAME, mode = 1             // Reset the dependent popmenu's popvalue to 1
	else
		gPopupToSet = KS_COCHLEA_EXPSITE_LIST                                     // Set the dependent popupmenu's popuplist
		ControlUpdate/W=$KS_MAIN_PANEL_NAME PopExpSite_main1
		ControlInfo/W=$KS_MAIN_PANEL_NAME PopExpSite_main1
		PopupSetProc ("PopExpSite_main1",V_value,S_value)                         // Set the dependent popupmenu's global
		PopupMenu PopExpSite_main1, win=$KS_MAIN_PANEL_NAME, mode = 1             // Reset the dependent popmenu's popvalue to 1
	endif
End


Static Function PopDye_main2Proc(ctrlName,popNum,popStr) : PopupMenuControl
// Synopsis: Performs the PopDye_main2 pupup menu's procedure.
// Details: 
//          
// Parameters: 
//             Variable popStr: The selected item's string.
// Return Value(s): -
// Side effects: see above. 
//
	String ctrlName
	Variable popNum
	String popStr
	
	DFREF ExpDetails = $KS_F_EXP_DETAILS
	DFREF SaveDf = GetDataFolderDFR()
	SVAR DyeName = ExpDetails:gStrDye_name
	
	// Popup menu behaviour. 
	if (StringMatch(popStr, "Choose...") == 1 || StringMatch(popStr, "---") == 1)
		
		PopupMenu PopDye_main2, win=$KS_MAIN_PANEL_NAME, mode = 1
		DyeName = ""
		
	else
		
		DyeName = popStr
		
	endif
	
	// Popup menu side effects
	if (StringMatch(popStr, "*Fura*") == 1)
		
		Variable base = K_MAIN_PANEL_BASE
		
		Button ButtonSetCalib_main2,win=$KS_MAIN_PANEL_NAME,pos={240,base+35}, size={110,20}, disable=0, title="Set Ca-calibration", proc=LB_Main#ButtonSetCalibProc
				
	else
		
		DFREF MainPack = $KS_F_MAIN
		SVAR Calib = MainPack:gStrCalib
		Calib = ""
		
		KillControl/W=$KS_MAIN_PANEL_NAME ButtonSetCalib_main2
		
	endif
	
	TabProc("main", 2)
	
	return 0
End


Static Function PopLoadProc_main2Proc(ctrlName,popNum,popStr) : PopupMenuControl
// Synopsis: Performs the PopDye_main2 pupup menu's procedure.
// Details: 
//          
// Parameters: 
//             Variable popStr: The selected item's string.
// Return Value(s): -
// Side effects: see above. 
//
	String ctrlName
	Variable popNum
	String popStr
	
	DFREF ExpDetails = $KS_F_EXP_DETAILS
	SVAR LoadProc = ExpDetails:gStrLoading_proc
	
	if (StringMatch(popStr, "Choose...") == 1 || StringMatch(popStr, "---") == 1)
		
		PopupMenu PopLoadProc_main2, win=$KS_MAIN_PANEL_NAME, mode = 1
		LoadProc = ""
		
	else
		
		LoadProc = popStr
		
	endif
	
	PopLoadProc_main2_SideEffects(popStr)

	return 0
End


Static Function PopLoadProc_main2_SideEffects(popStr)
// Synopsis: Performs the PopLoadProc_main2 pupup menu's side effects.
// Details: 
//          
// Parameters: 
//             Variable popNum: The number of the menu item selected in the popup menu.
// Return Value(s): -
// Side effects: see above. 
//
	String popStr
	
	DFREF ExpDetails = $KS_F_EXP_DETAILS
	DFREF MainPackage = $KS_F_MAIN
	DFREF SaveDf = GetDataFolderDFR()
	
	KillControl/W=$KS_MAIN_PANEL_NAME SetLoadCC_main2
	KillControl/W=$KS_MAIN_PANEL_NAME PopLoadCcUnit_main2
	KillControl/W=$KS_MAIN_PANEL_NAME SetLoadTime_main2
	KillControl/W=$KS_MAIN_PANEL_NAME PopLoadTemp_main2
	KillControl/W=$KS_MAIN_PANEL_NAME SetImpAmpl_main2
	KillControl/W=$KS_MAIN_PANEL_NAME SetImpDur_main2
	KillControl/W=$KS_MAIN_PANEL_NAME SetPipetteRes_main2
	KillControl/W=$KS_MAIN_PANEL_NAME SetImpCount_main2
		
	String popLoadCC_unit_path = KS_F_MAIN + ":gPopupLoadingCC_unit"
	String popLoadTemp_path = KS_F_MAIN + ":gPopupLoading_temp"
	
	Variable base = K_MAIN_PANEL_BASE
	
	SetDataFolder ExpDetails
		
	Variable Loading_cc = NumVarOrDefault(":gVarLoading_cc", 0) 
	Variable/G gVarLoading_cc = Loading_cc
	String LoadingCC_unit = StrVarOrDefault(":gStrLoadingCC_unit", "uM")
	String/G gStrLoadingCC_unit = LoadingCC_unit
	
	if (StringMatch(popStr, "Bulk loading") == 1 || StringMatch(popStr, "Continuous perfusion") == 1)
		
		String Loading_temp = StrVarOrDefault(":gStrLoading_temp", "Room Temperature")
		String/G gStrLoading_temp = Loading_temp
		Variable Loading_time = NumVarOrDefault(":gVarLoading_time", 0)
		Variable/G gVarLoading_time = Loading_time
			
		SetVariable SetLoadCC_main2,win=$KS_MAIN_PANEL_NAME,pos={37,base+105}, disable=1, size={120, 20}, title="Loading cc.: "
		SetVariable SetLoadCC_main2,win=$KS_MAIN_PANEL_NAME,limits={0,1000,1}, value = ExpDetails:gVarLoading_cc
		
		PopupMenu PopLoadCcUnit_main2,win=$KS_MAIN_PANEL_NAME,pos={170,base+105}, disable=1, title="", value = #popLoadCC_unit_path
		PopupMenu PopLoadCcUnit_main2,win=$KS_MAIN_PANEL_NAME, proc = LB_Main#PopupSetProc, mode=1, popValue = LoadingCC_unit
		
		SetVariable SetLoadTime_main2,win=$KS_MAIN_PANEL_NAME,pos={37,base+140}, disable=1, size={165, 20}, title="Loading Time (min): "
		SetVariable SetLoadTime_main2,win=$KS_MAIN_PANEL_NAME,limits={0,1000,1}, value = ExpDetails:gVarLoading_time
		
		PopupMenu PopLoadTemp_main2,win=$KS_MAIN_PANEL_NAME,pos={37,base+175}, disable=1, title="Loading Temperature: ", value = #popLoadTemp_path
		PopupMenu PopLoadTemp_main2,win=$KS_MAIN_PANEL_NAME, proc = LB_Main#PopupSetProc, mode=1, popValue = Loading_temp
	
	elseif (StringMatch(popStr, "Electroporation") == 1)
		
		Variable Impulse_amplitude = NumVarOrDefault(":gVarImpulse_amplitude", 0)
		Variable/G gVarImpulse_amplitude = Impulse_amplitude
		Variable Impulse_duration = NumVarOrDefault(":gVarImpulse_duration", 0)
		Variable/G gVarImpulse_duration = Impulse_duration
		Variable Pipette_resist = NumVarOrDefault(":gVarPipette_resist", 0)
		Variable/G gVarPipette_resist = Pipette_resist
		Variable Impulse_count = NumVarOrDefault(":gVarImpulse_count", 0)
		Variable/G gVarImpulse_count = Impulse_count
				
		SetVariable SetLoadCC_main2,win=$KS_MAIN_PANEL_NAME,pos={37,base+105}, disable=1, size={120, 20}, title="Loading cc.: "
		SetVariable SetLoadCC_main2,win=$KS_MAIN_PANEL_NAME,limits={0,1000,1}, value = ExpDetails:gVarLoading_cc
		
		PopupMenu PopLoadCcUnit_main2,win=$KS_MAIN_PANEL_NAME,pos={170,base+105}, disable=1, title="", value = #popLoadCC_unit_path
		PopupMenu PopLoadCcUnit_main2,win=$KS_MAIN_PANEL_NAME, proc = LB_Main#PopupSetProc, mode=1, popValue = LoadingCC_unit
		
		SetVariable SetImpAmpl_main2,win=$KS_MAIN_PANEL_NAME,pos={37,base+140}, disable=1, size={200, 20}, title="Impulse amplitude (uA): "
		SetVariable SetImpAmpl_main2,win=$KS_MAIN_PANEL_NAME,limits={0,1000,1}, value = ExpDetails:gVarImpulse_amplitude
		
		SetVariable SetImpDur_main2,win=$KS_MAIN_PANEL_NAME,pos={37,base+175}, disable=1, size={200, 20}, title="Impulse duration (ms): "
		SetVariable SetImpDur_main2,win=$KS_MAIN_PANEL_NAME,limits={0,1000,1}, value = ExpDetails:gVarImpulse_duration
		
		SetVariable SetPipetteRes_main2,win=$KS_MAIN_PANEL_NAME,pos={37,base+210}, disable=1, size={220, 20}, title="Pipette resistance (MOhm): "
		SetVariable SetPipetteRes_main2,win=$KS_MAIN_PANEL_NAME,limits={0,1000,1}, value = ExpDetails:gVarPipette_resist
		
		SetVariable SetImpCount_main2,win=$KS_MAIN_PANEL_NAME,pos={37,base+245}, disable=1, size={200, 20}, title="Number of impulses: "
		SetVariable SetImpCount_main2,win=$KS_MAIN_PANEL_NAME,limits={0,1000,1}, value = ExpDetails:gVarImpulse_count
		
	elseif (StringMatch(popStr, "Micropipette loading") == 1)
		
		SetVariable SetLoadCC_main2,win=$KS_MAIN_PANEL_NAME,pos={37,base+105}, disable=1, size={120, 20}, title="Loading cc.: "
		SetVariable SetLoadCC_main2,win=$KS_MAIN_PANEL_NAME,limits={0,1000,1}, value = ExpDetails:gVarLoading_cc
		
		PopupMenu PopLoadCcUnit_main2,win=$KS_MAIN_PANEL_NAME,pos={170,base+105}, disable=1, title="", value = #popLoadCC_unit_path
		PopupMenu PopLoadCcUnit_main2,win=$KS_MAIN_PANEL_NAME, proc = LB_Main#PopupSetProc, mode=1, popValue = LoadingCC_unit	
	
	endif
	
	SetDataFolder SaveDf
	
	KillOtherLoadProcGlobals(popStr)                   // Delete the unnecessary globals related to other loading methods. 
	
	TabProc("main", 2)                                 // To make the changes visibel, refresh the controls tab. 
End


Static Function KillOtherLoadProcGlobals(loadProcName)
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
	String loadProcName
	
	DFREF ExpDetails = $KS_F_EXP_DETAILS
	DFREF SaveDf = GetDataFolderDFR()
	
	SetDataFolder ExpDetails
	
	String gStrList = "", gVarList = ""
	
	if (StringMatch(loadProcName, "Bulk loading") == 1 || StringMatch(loadProcName, "Continuous perfusion") == 1)
		gVarList += VariableList("*Impulse*", ";", 4); gVarList += VariableList("*Pipette*", ";", 4);
	elseif (StringMatch(loadProcName, "Electroporation") == 1)
		gVarList += VariableList("gVarLoading_time", ";", 4)
		gStrList += StringList("gStrLoading_temp", ";")
	elseif (StringMatch(loadProcName, "Micropipette loading") == 1)
		gVarList += VariableList("*Impulse*", ";", 4); gVarList += VariableList("*Pipette*", ";", 4); gVarList += VariableList("gVarLoading_time", ";", 4);
		gStrList += StringList("gStrLoading_temp", ";")
	else
		gVarList += VariableList("*Impulse*", ";", 4); gVarList += VariableList("*Pipette*", ";", 4); gVarList += VariableList("gVarLoading_time", ";", 4);
		gVarList += VariableList("gVarLoading_cc", ";", 4)
		gStrList += StringList("gStrLoading_temp", ";"); gStrList += StringList("gStrLoadingCC_unit", ";")
	endif
	
	SetDataFolder SaveDf
	
	LB_Util#KillGlobalList(ExpDetails, gVarList, 0)
	LB_Util#KillGlobalList(ExpDetails, gStrList, 1)
End


Static Function PopNormModeProc(ctrlName,popNum,popStr) : PopupMenuControl
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
	String ctrlName
	Variable popNum
	String popStr
	
	DFREF work_BGDCorr = $KS_F_WORK_BGDCORR
	if (LB_Util#IsDataFolderEmpty(work_BGDCorr) == 1)                  // If no data were loaded throw an error message. 
		PopupMenu PopNormMode, win=$KS_MAIN_PANEL_NAME, mode = 1
		Abort "Please load some data to work on!\rUse any menu items of Data-> Load Waves->..."
	endif
	
	DFREF MainPack = $KS_F_MAIN
	SVAR NormMode = MainPack:gStrNormMode
	
	NormMode = popStr
	
	if (StringMatch(popStr, "dF/Fo") == 1)
		
		CheckBox CheckClip,win=$KS_MAIN_PANEL_NAME, value = 1
		CheckBoxProc("CheckClip",1)
		
	endif	
	
	return 0
End


Static Function/S PopNormModeList()
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
	
	DFREF MainPack = $KS_F_MAIN
	NVAR ChanNum = MainPack:gVarChanNum
	
	String list = ""
	
	if (ChanNum == 1)
		list = "BGD;dF/Fo;"
	elseif (ChanNum == 2)
		list = "Ratio;"
	endif
	
	return list
End


Static Function/S PopDyeList()
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

	DFREF MainPack = $KS_F_MAIN
	NVAR ChanNum = MainPack:gVarChanNum
	
	String list = ""
	
	if (ChanNum == 1)
		list = "Choose...;---;HEt;OGB1/Dextran;OGB1/K;Rh123;TMRM;"
	elseif (ChanNum == 2)
		list = "Choose...;---;Fura2/AM;Fura2/K;"
	endif
	
	return list
End


Static Function NumOfTreatProc(ctrlName,varNum,varStr,varName) : SetVariableControl
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
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	CreateTreatControlGlobals(varNum)
	
	SetTreatControlGlobals(varNum)
	
	// Shadow out the respective treatment tab elements in the treat tabs out of range of the choosen number of treatments.
	ControlInfo/W=$KS_MAIN_PANEL_NAME treat_main3
	TabProc("treat_main3", V_value)

	return 0
End


Static Function CreateTreatControlGlobals(varNum)
// Synopsis: Creates the globals of the controls of the treatments, and deletes the ones, that are not needed anymore. 
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
	Variable varNum
	
	DFREF SaveDf = GetDataFolderDFR()
	DFREF ExpDetails = $KS_F_EXP_DETAILS
	
	SetDataFolder ExpDetails
	
	Variable i; String gStrList = "", gVarList = ""                       // Creating the list of unnecessary globals variables and strings. 
	for (i = varNum ; i < K_MAX_NUM_OF_TREAT; i += 1)                 // 0-3 
		gVarList += VariableList("*Treat" + num2str(i) + "*", ";", 4)
		gStrList += StringList("*Treat" + num2str(i) + "*", ";")
	endfor
	
	LB_Util#KillGlobalList(ExpDetails, gVarList, 0)                       // Deleting the unnecessary globals variables and strings. 
	LB_Util#KillGlobalList(ExpDetails, gStrList, 1)
	
	String NameGlobal, StartGlobal, EndGlobal                             // Creating the necessary global variables and strings. 
	for (i = 0; i < varNum; i += 1)                                       // 0-3 
		
		NameGlobal = "gStrTreat" + num2str(i) + "_name"
		StartGlobal = "gVarTreat" + num2str(i) + "_start"
		EndGlobal = "gVarTreat" + num2str(i) + "_end"
		
		String ActTreat_name = StrVarOrDefault(":" + NameGlobal, "")
		String/G $NameGlobal = ActTreat_name
		Variable ActTreat_start = NumVarOrDefault(":" + StartGlobal, 0)
		Variable/G $StartGlobal = ActTreat_start
		Variable ActTreat_end = NumVarOrDefault(":" + EndGlobal, 0)
		Variable/G $EndGlobal = ActTreat_end
		
	endfor
	
	SetDataFolder SaveDf
End


Static Function SetTreatControlGlobals(varNum)
// Synopsis: Sets the globals of the controls of the treatments. 
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
	Variable varNum
	
	DFREF MainPack = $KS_F_MAIN
	
	// Assign meaningful globals to the enabled number of treatments controls
	Variable i; String NameGlobalPath, StartGlobalPath, EndGlobalPath, SetNameControl, SetStartControl, SetEndControl
	for (i = 0; i < varNum; i += 1)
		NameGlobalPath = KS_F_EXP_DETAILS + ":gStrTreat" + num2str(i) + "_name"
		StartGlobalPath = KS_F_EXP_DETAILS + ":gVarTreat" + num2str(i) + "_start"
		EndGlobalPath = KS_F_EXP_DETAILS + ":gVarTreat" + num2str(i) + "_end"
		
		SetNameControl = "SetTreatName_treat" + num2str(i) + "_main3"
		SetStartControl = "SetStartTime_treat" + num2str(i) + "_main3"
		SetEndControl = "SetEndTime_treat" + num2str(i) + "_main3"
		
		SetVariable $SetNameControl, win=$KS_MAIN_PANEL_NAME, value = $(NameGlobalPath)
		SetVariable $SetStartControl, win=$KS_MAIN_PANEL_NAME, value = $(StartGlobalPath)
		SetVariable $SetEndControl, win=$KS_MAIN_PANEL_NAME, value = $(EndGlobalPath)
	endfor
	
	// Assign a fake global to the other treatment's controls
	for (i = varNum; i < K_MAX_NUM_OF_TREAT; i += 1)
		SetNameControl = "SetTreatName_treat" + num2str(i) + "_main3"
		SetStartControl = "SetStartTime_treat" + num2str(i) + "_main3"
		SetEndControl = "SetEndTime_treat" + num2str(i) + "_main3"
		
		SetVariable $SetNameControl, win=$KS_MAIN_PANEL_NAME, value = MainPack:gStrTreatFake
		SetVariable $SetStartControl, win=$KS_MAIN_PANEL_NAME, value = MainPack:gVarTreatFake
		SetVariable $SetEndControl, win=$KS_MAIN_PANEL_NAME, value = MainPack:gVarTreatFake
	endfor
End


Static Function ButtonSetCalibProc(ctrlName) : ButtonControl
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
	String ctrlName
	
	DFREF MainPack = $KS_F_MAIN
	WAVE/T CalibWave = MainPack:CalibWave
	SVAR Calib = MainPack:gStrCalib
	
	String list = "", item 
	Variable i, choosenNo // One based!
	
	for (i = 0; i < DimSize(CalibWave, 0); i += 1)
		list += num2Str(i + 1) + ":   " + CalibWave[i][0] + "   " + CalibWave[i][1] + ";"
	endfor
	
	Prompt item, "Calibrations: ", popup, list
	DoPrompt "Select the calibration to use! ", item
	
	if (V_Flag)
		return 0
	endif
	
	String num = item[0, StrSearch(":", item, 0) + 1]
	choosenNo = str2num(num)
	
	Calib = "DATE=" + CalibWave[choosenNo - 1][0] + ",NAME=" + CalibWave[choosenNo - 1][1] + ",KD=" + CalibWave[choosenNo - 1][2] + ",RMIN=" + CalibWave[choosenNo - 1][3] + ",RMAX=" + CalibWave[choosenNo - 1][4] + ",BETA=" + CalibWave[choosenNo - 1][5] + ","
	
	return 0
End


Static Function ButtonSetROIs_main1Proc(ctrlName) : ButtonControl
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
	String ctrlName
	
	DFREF work_BGDCorr = $KS_F_WORK_BGDCORR
	if (LB_Util#IsDataFolderEmpty(work_BGDCorr) == 1)                  // If no data were loaded throw an error message. 
		PopupMenu PopNormMode, win=$KS_MAIN_PANEL_NAME, mode = 1
		Abort "Please load some data to work on!\rUse any menu items of Data-> Load Waves->..."
	endif
	
	DFREF MainPack = $KS_F_MAIN
	DFREF ExpDetails = $KS_F_EXP_DETAILS
	
	SVAR BGD0Name = MainPack:gStrBGD0Name
	SVAR Chan0List = MainPack:gStrchan0List
	SVAR ROINames = ExpDetails:gStrROI_Names
	
	Variable i, numOfROIs = ItemsInList(Chan0List)
	String item, aROIName
	
	ROINames = ""
	
	for (i = 0; i < numOfROIs ; i += 1)
		
		item = StringFromList(i, Chan0List)
		
		if (StringMatch(item, BGD0Name) == 1)
			
			DoAlert 0, "ROI_" + num2str(i) + " was selected for background. "
			//ROINames += "ROI_" + num2str(i) + "=BGD,"
			
		else
			
			aROIName = ""
			
			Prompt aROIName, "Please type in the name of ROI_" + num2str(i) + "! "
			DoPrompt "ROI names..." , aROIName
			
			if (V_Flag)              // If cancelled, end the process and reset ROINames to "". 
				ROINames = ""
				break
			endif
			
			ROINames += "ROI_" + num2str(i) + "=" + LB_Util#CheckText(aROIName, mode = 1) + ","
		
		endif
		
	endfor
	
End


Static Function ResetBGDButtonProc(ctrlName) : ButtonControl
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
	String ctrlName
	
	DFREF Imported = $KS_F_IMP_TRACES			
	
	if (!DataFolderExists(KS_F_IMP_TRACES) || LB_Util#IsDataFolderEmpty(imported) == 1)
		Abort "Please load some data to work on!\rUse any menu items of Data-> Load Waves->..." 
	endif
	
	UpdateBGDCorr()
End


Static Function DeletePointsButtonProc(ctrlName) : ButtonControl
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
	String ctrlName
	
	DFREF BGDCorr = $KS_F_BGDCORR
	
	if (DataFolderRefStatus(BGDCorr) == 0 || LB_Util#IsDataFolderEmpty(BGDCorr) == 1)
		Abort "Please make the labbook before you delete any points from the traces! " 
	endif
	
	Variable i, j, startX, endX, startP = NaN, endP = NaN, numOfDelPoints, areThereDeletedPoints = 0
	
	Prompt startX, "Please give the time (s) values From: "
	Prompt endX, "Please give the time (s) values To : "
	DoPrompt "Delete points from all traces in the experiment: ", startX, endX
	
	if (V_Flag)
		return NaN
	endif
	
	if (startX < 0 || endX < 0)
		Abort "Please give positive numbers! " 
	endif
	
	if (startX > endX)
		Abort "'From' must be less than or equal to 'To'! "
	endif
	
	if (CheckWholeWaveDel(startX, endX))                                          // This guarantees, that no waves in any of the datafolders would be deleted. 
		Abort "At least one trace would be completely deleted with the given 'From' and 'To' values. \rPlease choose other values! "
	endif
	
	WAVE/DF DfWave = LB_Util#GetFoldersDFRWave()
		
	for (i = 0; i < numpnts(DfWave); i += 1)
		
		if (DataFolderRefStatus(DfWave[i]) == 1 && CountObjectsDFR(DfWave[i], 1) > 0)
			
			WAVE/WAVE WaveSetWRW = LB_Util#GetWaveRefsDFR(DfWave[i], 1)
			
			for (j = 0; j < numpnts(WaveSetWRW); j += 2)
				
				WAVE ActWave = WaveSetWRW[j]
				WAVE ActTimeval = WaveSetWRW[j + 1]
								
				if (startX > ActTimeval[numpnts(ActTimeVal) - 1] || endX < ActTimeval[0])
					startP = NaN
					endP = NaN
				endif
				
				if (startX < ActTimeval[0] && endX <= ActTimeval[numpnts(ActTimeVal) - 1])
					startP = 0
					endP = LB_Util#FindClosestValue(endX, ActTimeval)
				endif
				
				if (startX >= ActTimeval[0] && endX > ActTimeval[numpnts(ActTimeVal) - 1])
					startP = LB_Util#FindClosestValue(startX, ActTimeval)
					endP = numpnts(ActTimeVal) - 1
				endif
				
				if (startX >= ActTimeval[0] && endX <= ActTimeval[numpnts(ActTimeVal) - 1])
					startP = LB_Util#FindClosestValue(startX, ActTimeval)
					endP = LB_Util#FindClosestValue(endX, ActTimeval)
				endif
				
				if (numtype(startP) == 0 && numtype(endP) == 0)
					
					numOfDelPoints = (endP - StartP) + 1
					DeletePoints startP, numOfDelPoints, ActWave, ActTimeval
					
					areThereDeletedPoints = 1
				endif
				
			endfor
			
		endif
		
	endfor
	
	if (areThereDeletedPoints)
		
		DFREF DfSave = GetDataFolderDFR()
		
		SetDataFolder KS_F_EXP_DETAILS
		
		String Deleted_Points = StrVarOrDefault(":gStrDeleted_Points", "")
		Deleted_Points += num2str(startX) + "s-" + num2str(endX) + "s,"
		String/G gStrDeleted_Points = Deleted_Points
		
		SetDataFolder DfSave
		
		LabbookButtonProc("ButtonLabbook")
	endif
End


Static Function CheckWholeWaveDel(startX, endX)
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
	Variable startX, endX
	
	if (startX < 0 || endX < 0)
		Abort "Error in CheckWholeWaveDel(startX, endX): \rPlease give positive numbers! " 
	endif
	
	if (startX > endX)
		Abort "Error in CheckWholeWaveDel(startX, endX): \rStartX must be less than or equal to endX! "
	endif
	
	Variable i, j
	
	WAVE/DF DfWave = LB_Util#GetFoldersDFRWave()
		
	for (i = 0; i < numpnts(DfWave); i += 1)
		
		if (DataFolderRefStatus(DfWave[i]) == 1 && CountObjectsDFR(DfWave[i], 1) > 0)
			
			WAVE/WAVE WaveSetWRW = LB_Util#GetWaveRefsDFR(DfWave[i], 1)
			
			for (j = 0; j < numpnts(WaveSetWRW); j += 2)
				
				WAVE ActWave = WaveSetWRW[j]
				WAVE ActTimeval = WaveSetWRW[j + 1]
								
				if (startX <= ActTimeval[0] && endX >= ActTimeval[numpnts(ActTimeVal) - 1])
					return 1
				endif
												
			endfor
						
		endif
				
	endfor
	
	return 0
End


Static Function LabbookButtonProc(ctrlName) : ButtonControl
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
	String ctrlName
	
	DFREF raw = $KS_F_RAW
	if (LB_Util#IsDataFolderEmpty(raw) == 1)                                  // If no data were loaded throw an error message. 
		Abort "Please load some data to work on!\rUse any menu items of Data-> Load Waves->..."
	endif
	
	GetRemainingDetails()
	MergeGlobals()
	
	DFREF workPeaks = $KS_F_WORK_PEAKS
	DFREF MainPack = $KS_F_MAIN
	SVAR NormMode = MainPack:gStrNormMode
	
	LB_Util#DeleteWindows(3, KS_PEAK_CLIPPER_NAME, exclude = 1)   // Deletes all graphs and tables in the experimet (except the Peak Clipper panel). 
	                                                              //   This ensures that no waves are in use. 
	ManageOutputFolders(NormMode, !LB_Util#IsDataFolderEmpty(workPeaks))
	
	SaveDataToOutputFolders(NormMode, !LB_Util#IsDataFolderEmpty(workPeaks))
	
	Execute/Q/Z "StackWindows/O=1"
	
	AssembleTheLabbook()
	
	PopupMenu PopNormMode,win=$KS_MAIN_PANEL_NAME, disable = 2
	
	ControlInfo/W=$KS_MAIN_PANEL_NAME main
	if (V_Value == 2)
		PopupMenu PopDye_main2,win=$KS_MAIN_PANEL_NAME, disable = 2
	endif
	
	CheckBox CheckClip,win=$KS_MAIN_PANEL_NAME, disable = 2
	Button ButtonResetBGD, win=$KS_MAIN_PANEL_NAME, disable = 2
		
	DoWindow/F $KS_MAIN_PANEL_NAME
	SetDataFolder root:
	
	return 0
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                           THE FUNCTIONS RELATED TO THE LABBOOKBUTTON                                                             //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


Static Function OrderData()
// Synopsis: Orders the loaded raw data into separate folders in the RawData folder. 
// Prerequisites: There has to be a root:RawData folder. 
// Return Value(s): - 
// Side effects: 
//               1) Creates two data folders in the root:RawData folder, namely: Waves, ImportDetails
//               2) Moves the waves into the Waves folder and all the global variables and strings generated 
//                  by the LoadWaves dialog into the ImportDetails folder. 
// 
	if (DataFolderExists(KS_F_IMP_TRACES) && DataFolderExists(KS_F_IMP_DETAILS))									// If the procedure was run before, then return
		return NaN
	endif
	
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder $KS_F_RAW
	
	NewDataFolder/O $KS_F_IMP_TRACES
	NewDataFolder/O $KS_F_IMP_DETAILS

	DFREF destDFR = $KS_F_IMP_TRACES
	LB_Util#BatchMove(WaveList("*",";",""), 3, destDFR)

	destDFR = $KS_F_IMP_DETAILS
	LB_Util#BatchMove(VariableList("*",";",4), 1, destDFR)
	LB_Util#BatchMove(StringList("*",";"), 2, destDFR)
	
	SetDataFolder saveDFR
	
	CheckFileName()
End


Static Function CheckFileName()
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
	DFREF ImpDetails = $KS_F_IMP_DETAILS
	DFREF MainPack = $KS_F_MAIN
	SVAR FileName = ImpDetails:S_fileName
	SVAR WorkExpID = MainPack:gStrWorkExpID
	
	String exprID = "([[:digit:]]{2})([[:alpha:]]{1}|[[:digit:]]{1})([[:digit:]]{2})([[:digit:]]{3})"
		
	if (!GrepString(LB_Util#RemoveExt(FileName), exprID))
		
		String alert = "The name of the imported file doesn't match the criterions for the experiment code. "
		alert += "\rDo you want to create a suitable code for the experiment? "
		alert += "\r\rIf no, IGOR will automatically create a suitable experiment code based on the current day. "
		
		DoAlert 1, alert
		
		String year, month, day, serialStr, exprDate
		
		if (V_Flag == 1)
			
			Variable serial
			
			Prompt year, "Year: ", popup LB_Util#DateLists("Year", from = 2000, to = 2020)
			Prompt month, "Month: ", popup LB_Util#DateLists("Month")
			Prompt day, "Day: ", popup LB_Util#DateLists("Day")
			Prompt serial, "Serial (0-999): "
			DoPrompt "Please give the desired date and serial number for the experiment code ", year, month, day, serial
			
			if (V_Flag)
		
				exprDate = "([[:digit:]]{4})-([[:digit:]]{2})-([[:digit:]]{2})"
				SplitString/E=exprDate Secs2Date(DateTime,-2), year, month, day
				
				WorkExpID = year[2,3] + LB_Util#OneCharMonth(month) + day + "000"
				
			endif
			
			serialStr = num2str(serial)
			
			if (strlen(serialStr) == 1)
				serialStr = "00" + serialStr
			elseif (strlen(serialStr) == 2)
				serialStr = "0" + serialStr
			elseif (strlen(serialStr) == 3)
			else
				serialStr = "000"
			endif
			
			WorkExpID = year[2,3] + LB_Util#MonthStr2NumChar(month, mode = 1) + day + serialStr
			
		else
			
			exprDate = "([[:digit:]]{4})-([[:digit:]]{2})-([[:digit:]]{2})"
			SplitString/E=exprDate Secs2Date(DateTime,-2), year, month, day
			
			WorkExpID = year[2,3] + LB_Util#OneCharMonth(month) + day + "000"
			
		endif
		
	else
		
		WorkExpID = LB_Util#RemoveExt(FileName)
		
	endif
	
End


Static Function UpdateBGDCorr()
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
	
	DFREF WorkBGDCorr = $KS_F_WORK_BGDCORR
	DFREF Imported = $KS_F_IMP_TRACES
	DFREF ImportDetails = $KS_F_IMP_DETAILS
	DFREF MainPack = $KS_F_MAIN
	
	if (LB_Util#IsDataFolderEmpty(imported) == -1 || LB_Util#IsDataFolderEmpty(imported) == 1)    // If there are no imported waves jet, do nothing. 
		return NaN                                                                                 // (if the imported datafolder do not exists, or it's empty.)
	endif
	
	do
	while(BGDInputDialog())                                     // Get further information for background substracion. Repeat the dialog until there are no failures.
	
	NVAR ChanNum = MainPack:gVarChanNum
	NVAR BGDMode = MainPack:gVarBGDMode
	SVAR TimevalName = MainPack:gStrTimevalName
	SVAR Chan0List = MainPack:gStrChan0List
	SVAR BGD0Name = MainPack:gStrBGD0Name
	SVAR WorkExpID = MainPack:gStrWorkExpID
	
	if (ChanNum == 1)
		
		LB_Util#ZapDataInFolderTree(KS_F_WORK_BGDCORR)              // Deleting the contents of the target folder. 
		
		ROIMinusBGD(LB_Util#GetWaveRefsDFR(Imported, 0), WorkBGDCorr, BGDMode, TimevalName, BGD0Name, WorkExpID)   // Performing the background substraction. 
	
	elseif (ChanNum == 2)
		
		DFREF WorkRatio = $KS_F_WORK_RATIO
		
		SVAR Chan1List = MainPack:gStrChan1List
		SVAR BGD1Name = MainPack:gStrBGD1Name
		SVAR Chan0MatchStr = MainPack:gStrChan0MatchStr
		SVAR Chan1MatchStr = MainPack:gStrChan1MatchStr

		LB_Util#ZapDataInFolderTree(KS_F_WORK_BGDCORR)              // Deleting the contents of the target folder. 
		
		ROIMinusBGD(LB_Util#GetWaveRefsList(Imported, TimevalName + ";" + Chan0List), WorkBGDCorr, BGDMode, TimevalName, BGD0Name, WorkExpID, postfix = "_Ex" + Chan0MatchStr)
		ROIMinusBGD(LB_Util#GetWaveRefsList(Imported, TimevalName + ";" + Chan1List), WorkBGDCorr, BGDMode, TimevalName, BGD1Name, WorkExpID, postfix = "_Ex" + Chan1MatchStr)
		
		MakeRatio(LB_Util#GetWaveRefsDFR(WorkBGDCorr, 1, match = "*_Ex" + Chan0MatchStr + "*"), LB_Util#GetWaveRefsDFR(WorkBGDCorr, 1, match = "*_Ex" + Chan1MatchStr + "*"), WorkRatio, WorkExpID)
		
	endif
	
	ControlUpdate/W=$KS_MAIN_PANEL_NAME PopNormMode
	ControlInfo/W=$KS_MAIN_PANEL_NAME PopNormMode
	PopNormModeProc("PopNormMode",V_value,S_value)
	
End


Static Function BGDInputDialog()
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
	DFREF MainPack = $KS_F_MAIN
	DFREF Imported = $KS_F_IMP_TRACES
	DFREF dfSave = GetDataFolderDFR()
	
	NVAR BGDMode = MainPack:gVarBGDMode
	NVAR ChanNum = MainPack:gVarChanNum
	SVAR BGD0Name = MainPack:gStrBGD0Name
	SVAR BGD1Name = MainPack:gStrBGD1Name
	SVAR TimevalName = MainPack:gStrtimevalName
	SVAR Chan0List = MainPack:gStrchan0List
	SVAR Chan1List = MainPack:gStrchan1List	
	SVAR Chan0MatchStr = MainPack:gStrChan0MatchStr
	SVAR Chan1MatchStr = MainPack:gStrChan1MatchStr
	
	SetDataFolder Imported
	String importedWaveList = WaveList("*",";","")
	SetDataFolder dfSave
	
	String strChanNum = "", strBGDMode = ""
	String locBGD0Name = "", locBGD1Name = "", locTimevalName = "", locChan0MatchStr = "", locChan1MatchStr = "", locChan0List = "", locChan1List = ""
	Variable i
	
	// Displaying a simple input dialog box to obtain further information for the background subtracion. 
	Prompt strChanNum, "Number of channels:", popup "1 Channel (Normal);2 Channels (Ratio);"
	Prompt strBGDMode, "Background to be subtracted:", popup "Whole trace;Background constant;"
	DoPrompt "Background subtraction method settings...", strChanNum, strBGDMode
	
	if (V_Flag)   // Default values if cancel clicked. 
		strChanNum = "1 Channel (Normal)"
		strBGDMode = "Whole trace"
	endif
	
	// Setting the globals according to the choosen values. 
	strswitch (strChanNum)
		case "1 Channel (Normal)":
			ChanNum = 1
			break
		case "2 Channels (Ratio)":
			ChanNum = 2
			break
	endswitch
	
	strswitch (strBGDMode)
		case "Whole trace":
			BGDMode = 0
			break
		case "Background Constant":
			BGDMode = 1
			break
	endswitch
	
	// Displaying a simple input dialog box to obtain further information for the background subtracion. 
	if (StringMatch(strChanNum, "1 Channel (Normal)") == 1)
	
		Prompt locTimevalName, "Timeval trace:", popup importedWaveList
		Prompt locBGD0Name, "Background trace:", popup importedWaveList	
		DoPrompt "Select traces", locTimevalName, locBGD0Name
		
		if (V_Flag)    // Default values if cancel clicked.
			
			// Setting the trace names (note that the globals are set directly). 
			TimevalName = StringFromList(0, importedWaveList)
			BGD0Name = StringFromList(ItemsInList(importedWaveList) - 1, importedWaveList)
			
			// The traces form 1 to the (number of traces) -1 are included channel 1 list (zero based). 
			for (i = 1; i <= ItemsInList(importedWaveList) - 1; i += 1)
				Chan0List += StringFromList(i, importedWaveList) + ";"
			endfor
			
			return 0
			
		endif
		
	else
	
		Prompt locTimevalName, "Timeval trace:", popup importedWaveList
		Prompt locChan0MatchStr, "First channel's trace match string:"	
		Prompt locBGD0Name, "First channel's background trace:", popup importedWaveList	
		Prompt locChan1MatchStr, "Second channel's trace match string:"
		Prompt locBGD1Name, "Second channel's background trace:", popup importedWaveList
		DoPrompt "Select traces", locTimevalName, locChan0MatchStr, locBGD0Name, locChan1MatchStr, locBGD1Name
		
		if (V_Flag)    // Default values if cancel clicked.
			
			// Setting the trace names (note that the globals are set directly). 
			TimevalName = StringFromList(0, importedWaveList)
			BGD0Name = StringFromList(ItemsInList(importedWaveList) / 2, importedWaveList)
			BGD1Name = StringFromList(ItemsInList(importedWaveList) - 1, importedWaveList)
			
			// The traces form 1 to the (number of traces) / 2 are included channel 1 list (zero based). 
			for (i = 1; i <= ItemsInList(importedWaveList) / 2; i += 1)
				Chan0List += StringFromList(i, importedWaveList) + ";"
			endfor
			
			// The traces form ((number of traces) / 2) + 1 to the last are included in the channel 2 list (zero based). 
			for (i = (ItemsInList(importedWaveList) / 2) + 1; i <= ItemsInList(importedWaveList) ; i += 1)
				Chan1List += StringFromList(i, importedWaveList) + ";"
			endfor
			
			return 0
			
		endif
		
	endif
	
	// This part of the function checks if there is any failure in the given data and in the end of the day sets the globals accordingly. 
	
	// Checking if any of the timeval and background trace names are identical, if yes throw an error message and return 1. 
	if (StringMatch(locBGD0Name, locTimevalName) == 1 || StringMatch(locBGD1Name, locTimevalName) == 1 || StringMatch(locBGD0Name, locBGD1Name) == 1)
		DoAlert 0, "Identical trace names! Please specify the timeval and background trace names again, make sure that none of them is identical!"
		return 1
	endif
	
	// Setting and checking the channels trace lists. 
	if (StringMatch(strChanNum, "1 Channel (Normal)") == 1)
		// If just one channel has been used, there is no need to specify a match string for the first (and only) channel. 
		// All traces except the timeval trace are included in the channel's trace list (zero based). 
		
		for (i = 0; i <= ItemsInList(importedWaveList) - 1; i += 1)
			locChan0List += StringFromList(i, importedWaveList) + ";"   // Include all traces first... 
		endfor
		
		locChan0List = RemoveFromList(locTimevalName, locChan0List)    // ...then remove the specified timeval trace. 
		
	else	 // If two channels have bee used. 
			
		if (StringMatch(locChan0MatchStr, "") == 1 || StringMatch(locChan1MatchStr, "") == 1)
		   // If any of the two match strings is missing (i.e. equals "") then set the timeval and background traces and 
		   // channel lists to the default as well (same if cancel would have been clicked). 
		   
		   // Setting the trace names (note that the globals are set directly). 
		   TimevalName = StringFromList(0, importedWaveList)
			BGD0Name = StringFromList(ItemsInList(importedWaveList) / 2, importedWaveList)
			BGD1Name = StringFromList(ItemsInList(importedWaveList) - 1, importedWaveList)
		   
		   // The traces form 1 to the (number of traces) / 2 are included channel 1 list (zero based). 
			for (i = 1; i <= ItemsInList(importedWaveList) / 2; i += 1)
				Chan0List += StringFromList(i, importedWaveList) + ";"
			endfor
			
			// The traces form ((number of traces) / 2) + 1 to the last are included in the channel 2 list (zero based). 
			for (i = (ItemsInList(importedWaveList) / 2) + 1; i <= ItemsInList(importedWaveList) ; i += 1)
				Chan1List += StringFromList(i, importedWaveList) + ";"
			endfor
			
			DoAlert 0, "Missing match string(s)! Background substraction has been performed with default settings. "
			
			return 0
			
		else      // If the match strings have been specified successfully, check if no further failure has been done.
			
			// Setting the two lists according to the match strings. 
			locChan0List = ListMatch(importedWaveList, "*" + locChan0MatchStr + "*")
			locChan1List = ListMatch(importedWaveList, "*" + locChan1MatchStr + "*")
			
			// This is just for safety, if the timeval trace would have been included in any of the two channel's list. 
			// This code removes it from the lists.  
			locChan0List = RemoveFromList(locTimevalName, locChan0List)
			locChan1List = RemoveFromList(locTimevalName, locChan1List)
			
			// If the two match strings are identical, throw an error message and return 1. 
			if (StringMatch(locChan0MatchStr, locChan1MatchStr))
				DoAlert 0, "The match strings for the two channels are identical, please specify another match string!"
				return 1
			endif
			
			// If the match string couldn't match any traces, throw an error message and return 1. 
			if (ItemsInList(locChan0List) == 0 || ItemsInList(locChan1List) == 0)
				DoAlert 0, "There are no matching traces for at least one channel, please specify other match strings!"
				return 1
			endif
			
			// If the number of elements in the two lists are not identical, throw an error message and retrun 1. 
			if (ItemsInList(locChan0List) != ItemsInList(locChan1List))
				DoAlert 0, "The number of traces in the two channels are not identical, please check your input data, or specify other match strings!"
				return 1
			endif
			
			// If there are overlappings among the traces of the two channels, throw an error message and return 1. 
			if (LB_Util#CmpLists(locChan0List, locChan1List) == 1)
				DoAlert 0, "There is at least one overlaping element in the two channels lists, please specify other match strings!"
				return 1
			endif
			
			// If the BGD traces are not among the traces of the corresponding channels throw an error message and return 1. 
			if (StringMatch(ListMatch(locChan0List, locBGD0Name), "") == 1)
				DoAlert 0, "The BGD trace for channel 0 is not among the traces of channel 0! "
				return 1
			elseif (StringMatch(ListMatch(locChan1List, locBGD1Name), "") == 1)
				DoAlert 0, "The BGD trace for channel 1 is not among the traces of channel 1! "
				return 1
			endif
			
		endif
		
	endif
	
	// Setting the globals according to the choosen values. 
	TimevalName = locTimevalName
	BGD0Name = locBGD0Name
	BGD1Name = locBGD1Name
	Chan0List = locChan0List
	Chan1List = locChan1List
	Chan0MatchStr = locChan0MatchStr
	Chan1MatchStr = locChan1MatchStr
	
	return 0
End


Static Function GetRemainingDetails()
// Synopsis:  Saves or sets the remaining experiment details, not written by controls. 
// Description/Details: These details are: 
//                      1) the experiment code (gStrExp_code)
//                      2) the experiment note (gStrExp_note)
// Parameters: -
// Return Value(s): - 
// Side effects: 
//               1) Extracts the experiment code from the imported file name and saves it 
//                  in the Exp_code global string. 
//               2) Selects the contents of the LabbookControlPanel#Notes notebook and
//                  saves it as the Exp_note global string. 
// 
	DFREF ExpDetails = $KS_F_EXP_DETAILS
	DFREF MainPack = $KS_F_MAIN
	
	SVAR Exp_code = ExpDetails:gStrExp_code, Exp_note = ExpDetails:gStrExp_note
	SVAR WorkExpID = MainPack:gStrWorkExpID
	
	// Saving the experiment code into the respective global string. 
	Exp_code = WorkExpID
	
	// Saving the experiment note into the respective global string. 
	Notebook LabbookControlPanel#Notes selection={startOfFile, endOfFile}
	Getselection notebook, LabbookControlPanel#Notes, 2	
	Exp_note = S_selection
	Notebook LabbookControlPanel#Notes selection={startOfFile, startOfFile}	 // Deselecting the selected part of the notebook
End


Static Function MergeGlobals()
// Synopsis: Creates a KEY:value; pair list from the globals found in the ExperimentDetails folder 
//           and saves it in the gStrWaveNote global in the same directory. 
// Description/Details: 
//                      The globals are written eiter by the corresponding controls in the
//                          LabbookControlPanel, or by the GetRemainingDetails() function. 
// Parameters: -
// Return Value(s): - 
// Side effects: 
//               Merges the names and values of the globals into a KEY:value; list string, named
//                   gStrWaveNote. This string will be the wave note of all waves in the experiment. 
// 
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder $KS_F_EXP_DETAILS
	
	// Appending the NVAR-s to the WaveNote
	String objName, KeyName
	Variable index = 0
	SVAR WaveNote = :gStrWaveNote
	WaveNote = ""																		// Reset the WaveNote
	
	do
		
		objName = GetIndexedObjName(":", 2, index)
		
		if (strlen(objName) == 0)
			break
		endif
		
		NVAR ActualNVAR = :$objName
		KeyName = UpperStr(ReplaceString("gVar", objName, ""))					//create actual key
		
		WaveNote = WaveNote + KeyName + ":" + num2str(ActualNVAR) + ";"		//append the actual KEY:value; to the WaveNote
		
		index += 1
	while(1)
	
	// Appending the SVAR-s to the WaveNote
	
	index = 0
	do
		
		objName = GetIndexedObjName(":", 3, index)
		
		if (strlen(objName) == 0)
			break
		endif
		
		if (!stringmatch(objName, "gStrWaveNote") && !stringmatch(objName, "gStrExp_note"))    // Avoid appanding WaveNote and Exp_note
		// Use this part if you want to add the Exp_note to each wave's wavenote. 
		//	if (stringmatch(objName, "gStrExp_note"))
		//		Exp_note = LB_Util#CheckText(Exp_note)
		//	endif
			
			SVAR ActualSVAR = :$objName
			KeyName = UpperStr(ReplaceString("gStr", objName, ""))                              //create actual key
			
			WaveNote = WaveNote + KeyName + ":" + LB_Util#CheckText(ActualSVAR) + ";"           //append the actual KEY:value; to the WaveNote
		
		endif
		
		index += 1
	while(1)
	
	SetDataFolder saveDFR
End



Static Function ROIMinusBGD(waveSetWRW, Destination, whole, timevalName, bgdName, name [, postfix])
// Synopsis: Creates background corrected waves from the waves found in the waveSetWRW wave reference wave.
// Description: 
//              The function has two distinct modes (set by the ratio parameter). The first mode is used if the recorded traces are from 
//                  a single channel recording (only one excitation wavelength). The second mode is for two
//                  channel recordings, where there are two distinct excitation wavelengths. This can be called
//                  Ratiometric recording, as the data obtained from one channel are divided by the other. In this 
//                  case there has to be two background traces for each of the channels. 
//              The timeval and background trace are set by the corresponding global variables (wave names). These
//                  globals can be set by an input dialog (see: BGDInputDialog()). 
//              It subtracts the whole background trace or a background constant from the traces.	This is 
//                  controlled by the whole parameter (see below). 
//              If the background constant is used, than it is calculated by taking the mean of the values of 
//                  the first three number points of the background wave. 
//              It's up to the programmer, to avoid wave name conflicts in the destination data folder. 
// Parameters: 
//             WAVE/WAVE waveSetWRW: A wave reference wave containing the target waves in the right order (see above). 
//             Variable ratio: sets the background subtraction mode. 0 is the normal mode, 1 is ratio mode. 
//             DFREF destination: 
//             Variable whole: if it's value is 1, than the whole background trace is to be subtracted. 
//                             if it's value is 0, than the background constant is to be subtracted. 
//             String name: The common name of the created waves. The individual waves are distinguised by their
//                          endings after the comon name(e.g. name_0, name_1 etc. for YWaves, and name_timeval for the XWave). 
// Return Value(s): - 
// Side effects: 
//               1) saves the background corrected waves in that folder
//               2) also saves a copy of the timeval wave in that foder
//               3) appends the wavenote and the roi code to the background corrected waves
//               4) appends the wavenote to the timeval wave
//
	WAVE/WAVE waveSetWRW
	DFREF destination
	Variable whole
	String timevalName, bgdName, name, postfix
	
	if (WaveType(waveSetWRW, 1) != 4)
		Abort "In ROIMinusBGD(waveSetWRW, ...): \rWrong wave type!"
	endif
	
	if (DataFolderRefStatus(Destination) == 0)
		Abort "In ROIMinusBGD(waveSetWRW, ...): \rInvalid DFREF for Destination!"
	endif	
	
//	if (LB_Util#IsDataFolderEmpty(destination) == 0)
//		Abort "In ROIMinusBGD(waveSetWRW, ...): \rDestination is not empty!"
//	endif
	
	if (whole != 0 && whole != 1)
		Abort "In ROIMinusBGD(waveSetWRW, ...): \rInvalid value for whole!"
	endif
	
	if (LB_Util#GetWaveIndexWRW(waveSetWRW, timevalName) != 0)
		Abort "In ROIMinusBGD(waveSetWRW, ...): \rTimeval wave is not the first in waveSetWRW"
	endif
	
	if (ParamIsDefault(postfix))
		postfix = ""
	endif
	
	Variable i  
	
	Variable bgdNo = LB_Util#GetWaveIndexWRW(waveSetWRW, bgdName)                   // The background trace must be the last one in the list. 
	WAVE BGD = waveSetWRW[bgdNo]
	Variable BGDConst = 0
	
	DFREF dfSave = GetDatafolderDFR()                                               // To avoid possible wave name conflicts I use a free data folder for
	SetDataFolder NewFreeDataFolder()                                               //   temporary wave storage.
	
	String wave_name = "", wnAdd
	for (i = 1 ; i < numpnts(waveSetWRW); i += 1)                                   // Process all the waves in the WRW except of the timeval and the backround
		
		if (i == bgdNo)                                                               // Skip the BGD wave
			continue
		endif
		
		wave_name = name + "_" + num2str(i - 1) + postfix                            // waves. 
		
		WAVE ROI = waveSetWRW[i]
		
		Duplicate/O ROI, w 
		
		if (whole == 0)
			w = ROI - BGD
		else
			BGDConst = (BGD[0]+BGD[1]+BGD[2])/3
			w = ROI - BGDConst
		endif
		
		wnAdd = "ROI_CODE:" + num2str(i - 1) + ";"
		
		Duplicate/O w, $wave_name
		Note/K $wave_name, SortList(note($wave_name) + wnAdd, ";", 16)
		
		MoveWave $wave_name, destination
		
		WAVE timeval = waveSetWRW[0]
		
		timevalName = wave_name + KS_TIMEVAL_ENDING                                   // Creating timeval wave for each individual wave
		
		Duplicate timeval, $timevalName
		Note/K $timevalName, SortList(note($timevalName) + wnAdd, ";", 16)
		
		MoveWave $timevalName, destination
		
	endfor
	
	KillWaves /Z w

	SetDataFolder dfSave                                                             // The free data folder is now killed
End


Static Function MakeRatio(chan0WRW, chan1WRW, Destination, name)
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
	WAVE/WAVE chan0WRW, chan1WRW
	DFREF Destination
	String name
	
	if (WaveType(chan0WRW, 1) != 4)
		Abort "In MakeRatio(chan0WRW, ...): \rWrong wave type for chan0WRW!"
	elseif (WaveType(chan1WRW, 1) != 4)
		Abort "In MakeRatio(chan0WRW, ...): \rWrong wave type for chan1WRW!"
	endif
	
	if (DataFolderRefStatus(Destination) == 0)
		Abort "In MakeRatio(chan0WRW, ...): \rInvalid DFREF for Destination!"
	endif
	
	if (numpnts(chan0WRW) != numpnts(chan1WRW))
		Abort "In MakeRatio(chan0WRW, ...): \rIncompatible wave reference waves for the two channels!"
	endif
	
	DFREF SaveDf = GetDataFolderDFR()
	
	SetDataFolder Destination
	
	Variable i; String wave_name, timevalName
	for (i = 0; i < numpnts(chan0WRW); i += 2)
		
		WAVE aChan0Wave = chan0WRW[i]
		WAVE achan1Wave = chan1WRW[i]
		WAVE aChan0TimevalWave = chan0WRW[i + 1]
		
		if (numpnts(aChan0Wave) != numpnts(aChan1Wave))
			Abort "In MakeRatio(chan0WRW, ...): \rIncompatible waves in the two channels! "
		endif
		
		Duplicate/O aChan0Wave, aRatioWave
		
		aRatioWave = aChan0Wave / aChan1Wave
		
		wave_name = name + "_" + num2str(i / 2)
		timevalName = wave_name + KS_TIMEVAL_ENDING
		
		Duplicate aRatioWave, $wave_name
		Duplicate aChan0TimevalWave, $timevalName
		
	endfor
	
	KillWaves/Z aRatioWave
	
	SetDataFolder SaveDf
End


Static Function ManageOutputFolders(normMode, isThereAnyPeakData)
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
	String normMode
	Variable isThereAnyPeakData
	
	if (isThereAnyPeakData != 0 && isThereAnyPeakData != 1)
		Abort "In ManageOuputFolder(NormMode, ...) \rInvalid value for isThereAnyPeakData! "
	endif
	
	if (StringMatch(normMode, "BGD") == 1)
		
		NewDataFolder/O $KS_F_BGDCORR
		
		if (isThereAnyPeakData)
			NewDataFolder/O $KS_F_PEAKS
			NewDataFolder/O $KS_F_PEAKS_BGD
		endif
	
	elseif (StringMatch(normMode, "Ratio") == 1)
		
		DFREF MainPack = $KS_F_MAIN
		SVAR Calib = MainPack:gStrCalib
		
		NewDataFolder/O $KS_F_BGDCORR
		NewDataFolder/O $KS_F_RATIO
		
		if (strlen(Calib) != 0)
			NewDataFolder/O $KS_F_CA
		endif
		
		if (isThereAnyPeakData)
			
			NewDataFolder/O $KS_F_PEAKS
			NewDataFolder/O $KS_F_PEAKS_RATIO
			
			if (strlen(Calib) != 0)
				NewDataFolder/O $KS_F_PEAKS_CA
			endif
			
		endif
		
	elseif (StringMatch(normMode, "dF/Fo") == 1)
		
		NewDataFolder/O $KS_F_BGDCORR
		
		if (isThereAnyPeakData)
			NewDataFolder/O $KS_F_PEAKS
			NewDataFolder/O $KS_F_PEAKS_DFPERFO
		endif
		
	endif
End


Static Function SaveDataToOutputFolders(normMode, isThereAnyPeakData)
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
	String normMode
	Variable isThereAnyPeakData
	
	if (isThereAnyPeakData != 0 && isThereAnyPeakData != 1)
		Abort "In ManageOuputFolder(NormMode, ...) \rInvalid value for isThereAnyPeakData! "
	endif
	
	DFREF workBGDCorr = $KS_F_WORK_BGDCORR
	DFREF workPeaks = $KS_F_WORK_PEAKS
	DFREF ExpDetails = $KS_F_EXP_DETAILS
	
	SVAR waveNote = ExpDetails:gStrWaveNote
	
	DFREF BGDCorr = $KS_F_BGDCORR
	
	if (StringMatch(normMode, "BGD") == 1)
	
		LB_Util#ZapDataInFolderTree(KS_F_BGDCORR)                     // Deletes the contents of the BGDCorrectedData folder. 
		
		CopyWaves(LB_Util#GetWaveRefsDFR(workBGDCorr, 0), BGDCorr, waveNote = waveNote + "NORM_MODE:BGD;")
		
		if (isThereAnyPeakData)
			
			DFREF PeaksBGD = $KS_F_PEAKS_BGD
			
			LB_Util#ZapDataInFolderTree(KS_F_PEAKS_BGD)
			CopyWaves(LB_Util#GetWaveRefsDFR(workPeaks, 0), PeaksBGD, waveNote = waveNote + "NORM_MODE:BGD;")
			
		endif
		
		Disp(0, isThereAnyPeakData)
		
	elseif(StringMatch(normMode, "Ratio") == 1)
		
		DFREF workRatio = $KS_F_WORK_RATIO
		DFREF Ratio = $KS_F_RATIO
		DFREF Ca = $KS_F_CA
		DFREF MainPack = $KS_F_MAIN
		
		SVAR Calib = MainPack:gStrCalib
				
		LB_Util#ZapDataInFolderTree(KS_F_BGDCORR)                     // Deletes the contents of the BGDCorrectedData folder. 
		LB_Util#ZapDataInFolderTree(KS_F_RATIO)
		
		CopyWaves(LB_Util#GetWaveRefsDFR(workBGDCorr, 0), BGDCorr, waveNote = waveNote + "NORM_MODE:BGD;")
		CopyWaves(LB_Util#GetWaveRefsDFR(workRatio, 0), Ratio, waveNote = waveNote + "NORM_MODE:Ratio;")
		
		if (strlen(Calib) != 0)
			
			LB_Util#ZapDataInFolderTree(KS_F_CA)
			CalculateCalcium(LB_Util#GetWaveRefsDFR(workRatio, 0), Ca, waveNote = waveNote + "NORM_MODE:Ca;")
			
		endif
		
		if (isThereAnyPeakData)
			
			DFREF PeaksRatio = $KS_F_PEAKS_RATIO
			DFREF PeaksCa = $KS_F_PEAKS_CA
			
			LB_Util#ZapDataInFolderTree(KS_F_PEAKS_RATIO)
			CopyWaves(LB_Util#GetWaveRefsDFR(workPeaks, 0), PeaksRatio, waveNote = waveNote + "NORM_MODE:Ratio;")
			
			if (strlen(Calib) != 0)
				
				LB_Util#ZapDataInFolderTree(KS_F_PEAKS_CA)
				CalculateCalcium(LB_Util#GetWaveRefsDFR(workPeaks, 0), PeaksCa, waveNote = waveNote + "NORM_MODE:Ca;")
				
			endif
			
		endif
		
		Disp(2, isThereAnyPeakData)
		
	elseif(StringMatch(normMode, "dF/Fo") == 1)
		
		LB_Util#ZapDataInFolderTree(KS_F_BGDCORR)
		CopyWaves(LB_Util#GetWaveRefsDFR(workBGDCorr, 0), BGDCorr, waveNote = waveNote + "NORM_MODE:BGD;")
		
		if (isThereAnyPeakData)
			
			DFREF PeaksdFperFo = $KS_F_PEAKS_DFPERFO
			
			LB_Util#ZapDataInFolderTree(KS_F_PEAKS_DFPERFO)
			CopyWaves(LB_Util#GetWaveRefsDFR(workPeaks, 0), PeaksdFperFo, waveNote = waveNote + "NORM_MODE:dF/Fo;")
			
		endif
		
		Disp(1, isThereAnyPeakData)
		
	endif
End


Static Function CalculateCalcium(waveSetWRW, dest, [waveNote])
// Synopsis: Computes the calcium waves from the selected ratio waves. 
// Details: The references of the selected waves are passed in a wave reference wave (waveSetWRW). 
//          If the parameter name is specified then the common name of the waves are set to be equal 
//              name. This presumes, that the waves are named according the trace naming conventions. 
//              More on this in the help. 
//          If the parameter waveNote is specified, this string is added to all waves as a wave note. 
//              The individual name of the waves are added to each individual wave's wave note as well. 
//              See parameters section.  
// Parameters: 
//             WAVE/WAVE waveSetWRW: a wave reference wave containing the wave references of
//                                   the selected waves. 
//             DFREF dest: a data folder reference to the destination folder. 
//             String waveNote (OPTIONAL): a string containing the wave note, which is to be added 
//                                         to the waves. The wave note must follow the structure of a
//                                         KEY:value; list. The wave name is appended to each individual 
//                                         wave's wave note with the key ROI_CODE (i.e. ROI_CODE:waveName;). 
// Return Value(s): -
// Side effects: see above. 
// Error message(s):
//                   1) If the input wave is not a wave reference wave. 
//                   2) If the data folder reference for destination is not valid. 
//                   3) If the destination data folder is not empty. 
//
	WAVE/WAVE waveSetWRW
	DFREF dest
	
	String waveNote
	
	if (WaveType(waveSetWRW, 1) != 4)
		Abort "In CalculateCalcium(waveSetWRW, ...): \rWrong wave type!"
	endif
	
	if (DataFolderRefStatus(dest) == 0)
		Abort "In CalculateCalcium(waveSetWRW, ...): \rInvalid DFREF for destination!"
	endif
 	
	if (!LB_Util#IsDataFolderEmpty(dest))
		Abort "In CalculateCalcium(waveSetWRW, ...): \rDestination is not empty!"
	endif
	
	DFREF MainPack = $KS_F_MAIN
	SVAR Calib = MainPack:gStrCalib
	
	if (strlen(Calib) == 0)
		Abort "In CalculateCalcium(waveSetWRW, ...): \rMissing calibration data!"
	endif
	
	Variable kD, rMin, rMax, b
	
	kD = str2num(StringByKey("KD", Calib, "=", ",", 0))
	rMin = str2num(StringByKey("RMIN", Calib, "=", ",", 0))
	rMax = str2num(StringByKey("RMAX", Calib, "=", ",", 0))
	b = str2num(StringByKey("BETA", Calib, "=", ",", 0))
	
	if (numtype(kD) != 0 || numtype(rMin) != 0 || numtype(rMax) != 0 || numtype(b) != 0)
		Abort "In CalculateCalcium(waveSetWRW, ...): \rWrong values for calibration data!"
	endif
	
	DFREF dfSave = GetDataFolderDFR()
	
	SetDataFolder dest
	
	String wave_name, tv_name, wnAdd = "CALIB:" + Calib + ";"
	Variable i
	
	for (i = 0 ; i < numpnts(waveSetWRW); i += 2) 
		
		WAVE w = waveSetWRW[i]
		WAVE tv = waveSetWRW[i + 1]
		
		wave_name = NameOfWave(w)
				
		Duplicate/FREE/O w, temp
		temp = ((temp - rMin) / (rMax - temp)) * kD * b                           // Calculating the calcium wave. 
				
		Duplicate temp, $wave_name
		Note/K $wave_name, SortList(note($wave_name) + wnAdd, ";", 16)
		
		tv_name = NameOfWave(tv)
		Duplicate tv, $tv_name
		Note/K $tv_name, SortList(note($tv_name) + wnAdd, ";", 16)
		
		if (!ParamIsDefault(waveNote))
			Note/K $wave_name, SortList(note($wave_name) + WaveNote, ";", 16)      // Appends the the specified text to the wave's wavenote and sortst it. 
			Note/K $tv_name, SortList(note($tv_name) + WaveNote, ";", 16)
		endif
		
	endfor
	
	SetDataFolder dfSave
End


Static Function CopyWaves(waveSetWRW, dest, [name, waveNote])
// Synopsis: Copies the selected waves in the destination data folder. 
// Details: The references of the selected waves are passed in a wave reference wave (waveSetWRW). 
//          If the parameter name is specified then the common name of the waves are set to be equal 
//              name. This presumes, that the waves are named according the trace naming conventions. 
//              More on this in the help. 
//          If the parameter waveNote is specified, this string is added to all waves as a wave note. 
//              The individual name of the waves are added to each individual wave's wave note as well. 
//              See parameters section.  
// Parameters: 
//             WAVE/WAVE waveSetWRW: a wave reference wave containing the wave references of
//                                   the selected waves. 
//             DFREF dest: a data folder reference to the destination folder. 
//             String name (OPTIONAL): a name with wich the common names of the waves are replaced. 
//             String waveNote (OPTIONAL): a string containing the wave note, which is to be added 
//                                         to the waves. The wave note must follow the structure of a
//                                         KEY:value; list. The wave name is appended to each individual 
//                                         wave's wave note with the key ROI_CODE (i.e. ROI_CODE:waveName;). 
// Return Value(s): -
// Side effects: see above. 
// Error message(s):
//                   1) If the input wave is not a wave reference wave. 
//                   2) If the data folder reference for destination is not valid. 
//                   3) If the destination data folder is not empty. 
//
	WAVE/WAVE waveSetWRW
	DFREF dest
	String name
	String waveNote
	
	if (WaveType(waveSetWRW, 1) != 4)
		Abort "In CopyWaves(waveSetWRW, ...): \rWrong wave type!"
	endif
	
	if (DataFolderRefStatus(dest) == 0)
		Abort "In CopyWaves(waveSetWRW, ...): \rInvalid DFREF for destination!"
	endif
 	
	if (!LB_Util#IsDataFolderEmpty(dest))
		Abort "In CopyWaves(waveSetWRW, ...): \rDestination is not empty!"
	endif
	
	DFREF dfSave = GetDataFolderDFR()
	SetDataFolder dest
	
	String wave_name
	Variable i
	for (i = 0 ; i < numpnts(waveSetWRW); i += 1) 
		WAVE w = waveSetWRW[i]
		
		if (!ParamIsDefault(name))
			wave_name = NameOfWave(w)
			wave_name[0, strsearch(wave_name, "_", 0) - 1] = name	
			Duplicate w, $wave_name
		else
			wave_name = NameOfWave(w)
			Duplicate w, $wave_name
		endif
		 
		if (!ParamIsDefault(waveNote))
			Note/K $wave_name, SortList(note($wave_name) + WaveNote, ";", 16)      // Appends the the specified text to the wave's wavenote and sortst it. 
		endif
		
	endfor
	
	SetDataFolder dfSave
End


Static Function Disp(mode, isThereAnyPeakData, [name, treat])
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
	Variable mode, isThereAnyPeakData
	String name
	Variable treat
	
	if (mode != 0 && mode != 1 && mode != 2)
		Abort "In Disp(mode, ...): \rWrong value for mode"
	endif
	
	if (isThereAnyPeakData != 0 && isThereAnyPeakData != 1)
		Abort "In Disp(mode, ...) \rInvalid value for isThereAnyPeakData! "
	endif
	
	if (ParamIsDefault(name))
		name = "Graph"
	endif
	
	if (ParamIsDefault(treat))
		treat = 1
	endif
	
	if (treat != 0 && treat != 1)
		Abort "In Disp(mode, ...): \rWrong value for treat"
	endif
	
	DFREF BGDCorr = $KS_F_BGDCORR
	DFREF MainPack = $KS_F_MAIN
		
	SVAR Calib = MainPack:gStrCalib
	Variable areThereCalciumData = (strlen(Calib) != 0)
	
	switch(mode)
		
		case 0:		
			
			DFREF PeaksBGD = $KS_F_PEAKS_BGD
			
			if (!isThereAnyPeakData)
				DispDefault(LB_Util#GetWaveRefsDFR(BGDCorr, 1), name, treat)
			else
				DispDefault(LB_Util#GetWaveRefsDFR(BGDCorr, 1), name, treat, BGDPeakWRW = LB_Util#GetWaveRefsDFR(PeaksBGD, 1))
			endif
			
			break
		case 1:		
			
			DFREF PeaksdFperFo = $KS_F_PEAKS_DFPERFO
			
			if (!isThereAnyPeakData)
				DispdFperFo(LB_Util#GetWaveRefsDFR(BGDCorr, 1), name, treat)
			else
				DispdFperFo(LB_Util#GetWaveRefsDFR(BGDCorr, 1), name, treat, PeaksWRW = LB_Util#GetWaveRefsDFR(PeaksdFperFo, 1))
			endif
			
			break
		case 2:		
			
			DFREF MainPack = $KS_F_MAIN
			DFREF Ratio = $KS_F_RATIO
			DFREF Ca = $KS_F_Ca
			DFREF PeaksRatio = $KS_F_PEAKS_RATIO
			DFREF PeaksCa = $KS_F_PEAKS_CA
			
			SVAR Chan0MatchStr = MainPack:gStrChan0MatchStr
			SVAR Chan1MatchStr = MainPack:gStrChan1MatchStr
			
			String ch0MS = "*" + Chan0MatchStr + "*", ch1MS = "*" + Chan1MatchStr + "*"
			
			if (isThereAnyPeakData)
				
				if (areThereCalciumData)
					DispRatio(LB_Util#GetWaveRefsDFR(BGDCorr, 1, match = ch0MS), LB_Util#GetWaveRefsDFR(BGDCorr, 1, match = ch1MS), LB_Util#GetWaveRefsDFR(Ratio, 1), name, treat, CaWRW = LB_Util#GetWaveRefsDFR(Ca, 1), RPeakWRW =LB_Util#GetWaveRefsDFR(PeaksRatio, 1), CaPeakWRW =LB_Util#GetWaveRefsDFR(PeaksCa, 1))
				else
					DispRatio(LB_Util#GetWaveRefsDFR(BGDCorr, 1, match = ch0MS), LB_Util#GetWaveRefsDFR(BGDCorr, 1, match = ch1MS), LB_Util#GetWaveRefsDFR(Ratio, 1), name, treat, RPeakWRW =LB_Util#GetWaveRefsDFR(PeaksRatio, 1))
				endif
			
			else
				
				if (areThereCalciumData)
					DispRatio(LB_Util#GetWaveRefsDFR(BGDCorr, 1, match = ch0MS), LB_Util#GetWaveRefsDFR(BGDCorr, 1, match = ch1MS), LB_Util#GetWaveRefsDFR(Ratio, 1), name, treat, CaWRW = LB_Util#GetWaveRefsDFR(Ca, 1))
				else
					DispRatio(LB_Util#GetWaveRefsDFR(BGDCorr, 1, match = ch0MS), LB_Util#GetWaveRefsDFR(BGDCorr, 1, match = ch1MS), LB_Util#GetWaveRefsDFR(Ratio, 1), name, treat)
				endif
			
			endif
			
			break
	endswitch
End 


Static Function DispDefault(WRW, name, treat, [BGDPeakWRW])
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
	WAVE/WAVE WRW, BGDPeakWRW
	String name
	Variable treat
	
	if (WaveType(WRW, 1) != 4)
		Abort "In DispDefault(WRW, ...): \rWrong wave type"
	endif
	
	Variable i, j, isThereAnyPeak = 0, arePeaksInTheGraph
	String graphName, titleStr, roiName, annotation
	
	if (!ParamIsDefault(BGDPeakWRW))
		
		if (WaveType(BGDPeakWRW, 1) != 4)
			Abort "In DispDefault(WRW, ...): \rWrong wave type"
		endif
		
		if (numpnts(BGDPeakWRW) == 0)
			Abort "In DispDefault(WRW, ...): \rEmpty wave reference wave!"
		endif
	
		isThereAnyPeak = 1
		
	endif
	
	for (i = 0 ; i < numpnts(WRW); i += 2) 
		
		WAVE WaveToDisplay = WRW[i]
		WAVE Timeval = WRW[i + 1]
		
		graphName = name + num2str(i / 2); titleStr = StringByKey("ROI_" + num2str(i/2), StringByKey("ROI_NAMES", note(WaveToDisplay)),"=",",",0)
		
		
		if (StringMatch(titleStr, "") != 1)                                                     // Displaying the first wave
			Display/N=$graphName WaveToDisplay vs Timeval as titleStr
		else
			Display/N=$graphName WaveToDisplay vs Timeval
		endif
		
		if (StringMatch(StringByKey("ROI_NAMES", note(WaveToDisplay)), "") != 1)
			// If the ROI names are specified append the each ROI name to the graph's annotation
			roiName = StringByKey("ROI_" + StringByKey("ROI_CODE", note(WaveToDisplay)), StringByKey("ROI_NAMES", note(WaveToDisplay)), "=", ",", 0)
			annotation = StringByKey("EXP_CODE", note(WaveToDisplay)) + "_" + StringByKey("ROI_CODE", note(WaveToDisplay)) + " (" + roiName + ")"
		else
			annotation = StringByKey("EXP_CODE", note(WaveToDisplay)) + "_" + StringByKey("ROI_CODE", note(WaveToDisplay))
		endif
		
		if (isThereAnyPeak)	
			
			arePeaksInTheGraph = 0
			
			for (j = 0 ; j < numpnts(BGDPeakWRW); j += 2) 
				
				WAVE BGDPeakWave = BGDPeakWRW[j]
				
				if (StringMatch(NameOfWave(BGDPeakWave), NameOfWave(WaveToDisplay) + "_*"))
					
					WAVE BGDPeakTimeval = BGDPeakWRW[j + 1]
					AppendToGraph/L=L2 BGDPeakWave vs BGDPeakTimeval                              // Appending the others. 
					
					arePeaksInTheGraph = 1
					
				endif
				
			endfor
			
			if (arePeaksInTheGraph)
				
				ModifyGraph axisEnab(left)={0.525,1}, lblPos(left)=60, fSize(left)=10, fSize(bottom)=10
				ModifyGraph axisEnab(L2)={0,0.475},lblPos(L2)=60, freePos(L2)={Timeval[0],bottom}, fSize(L2)=10
				Label left, "\f01\Z10ROI-BGD\r(Arbitrary Units)"
				Label L2, "\f01\Z10ROI-BGD\r(Arbitrary Units)"
				Label bottom, "\f01\Z10Time (s)"	
				Textbox/C/N=text1/A=MT/B=1/E=1 annotation
				
			else
				
				ModifyGraph fSize(bottom)=10, fSize(left)=10
				Label left, "\f01\Z10ROI-BGD\r(Arbitrary Units)"
				Label bottom, "\f01\Z10Time (s)"	
				Textbox/C/N=text1/A=MT/B=1/E=1 annotation
				
			endif
		
		else
			
			ModifyGraph fSize(bottom)=10, fSize(left)=10
			Label left, "\f01\Z10ROI-BGD\r(Arbitrary Units)"
			Label bottom, "\f01\Z10Time (s)"	
			Textbox/C/N=text1/A=MT/B=1/E=1 annotation
			
		endif
		
		if (treat)
			Treatment(WaveToDisplay, graphName)
		endif
		
	endfor
End


Static Function DispdFperFo(BGDCorrWRW, name, treat, [PeaksWRW])
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
	WAVE/WAVE BGDCorrWRW, PeaksWRW
	String name
	Variable treat
	
	if (WaveType(BGDCorrWRW, 1) != 4)
		Abort "In DispdFperFo(BGDCorrWRW, ...): \rWrong wave type"
	endif
	
	if (numpnts(BGDCorrWRW) == 0)
			Abort "In DispdFperFo(BGDCorrWRW, ...): \rEmpty wave reference wave!"
	endif
	
	Variable i, j, isThereAnyPeak = 0, arePeaksInTheGraph
	String graphName, titleStr, roiName, annotation
	
	if (!ParamIsDefault(PeaksWRW))
		
		if (WaveType(PeaksWRW, 1) != 4)
			Abort "In DispdFperFo(BGDCorrWRW, ...): \rWrong wave type"
		endif
		
		if (numpnts(PeaksWRW) == 0)
			Abort "In DispdFperFo(BGDCorrWRW, ...): \rEmpty wave reference wave!"
		endif
		
		isThereAnyPeak = 1
		
	endif
	
	
	for (i = 0 ; i < numpnts(BGDCorrWRW); i += 2) 
		
		WAVE WaveToDisplay = BGDCorrWRW[i]
		WAVE Timeval = BGDCorrWRW[i + 1]
		
		graphName = name + num2str(i / 2); titleStr = StringByKey("ROI_" + num2str(i/2), StringByKey("ROI_NAMES", note(WaveToDisplay)),"=",",",0)
		
		if (StringMatch(titleStr, "") != 1)
			Display/N=$graphName WaveToDisplay vs Timeval as titleStr
		else
			Display/N=$graphName WaveToDisplay vs Timeval
		endif
		
		if (StringMatch(StringByKey("ROI_NAMES", note(WaveToDisplay)), "") != 1)
			// If the ROI names are specified append the each ROI name to the graph's annotation
			roiName = StringByKey("ROI_" + StringByKey("ROI_CODE", note(WaveToDisplay)), StringByKey("ROI_NAMES", note(WaveToDisplay)), "=", ",", 0)
			annotation = StringByKey("EXP_CODE", note(WaveToDisplay)) + "_" + StringByKey("ROI_CODE", note(WaveToDisplay)) + " (" + roiName + ")"
		else
			annotation = StringByKey("EXP_CODE", note(WaveToDisplay)) + "_" + StringByKey("ROI_CODE", note(WaveToDisplay))
		endif
		
		if (isThereAnyPeak)	
			
			arePeaksInTheGraph = 0
			
			for (j = 0 ; j < numpnts(PeaksWRW) - 1; j += 2) 
				
				WAVE Curr = PeaksWRW[j]
				
				if (StringMatch(NameOfWave(Curr), NameOfWave(WaveToDisplay) + "_*"))
					
					WAVE CurrTimeval = PeaksWRW[j + 1]
					AppendToGraph/L=L2 Curr vs CurrTimeval
					
					arePeaksInTheGraph = 1
				endif
				
			endfor
			
			if (arePeaksInTheGraph)
				
				ModifyGraph axisEnab(left)={0.525,1}, lblPos(left)=60, fSize(left)=10, fSize(bottom)=10
				ModifyGraph axisEnab(L2)={0,0.475}, freePos(L2)={Timeval[0],bottom}, lblPos(L2)=60, fSize(L2)=10
				Label left, "\f01ROI-BGD\r(Arbitrary Units)"
				Label L2, "\f01dF/F\B0"
				Label bottom, "\f01Time (s)"	
				Textbox/C/N=text1/A=MT/B=1/E=1 annotation
			
			else
				
				ModifyGraph fSize(bottom)=10, fSize(left)=10
				Label left, "\f01ROI-BGD\r(Arbitrary Units)"
				Label bottom, "\f01Time (s)"	
				Textbox/C/N=text1/A=MT/B=1/E=1 annotation
			
			endif
		
		else
		
			ModifyGraph fSize(bottom)=10, fSize(left)=10
			Label left, "\f01ROI-BGD\r(Arbitrary Units)"
			Label bottom, "\f01Time (s)"	
			Textbox/C/N=text1/A=MT/B=1/E=1 annotation
		
		endif
		
		if (treat)
			Treatment(WaveToDisplay, graphName)
		endif
		
	endfor
End


Static Function DispRatio(Chan0WRW, Chan1WRW, RatioWRW, name, treat, [CaWRW, RPeakWRW, CaPeakWRW])
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
	WAVE/WAVE Chan0WRW, Chan1WRW, RatioWRW, CaWRW, RPeakWRW, CaPeakWRW
	String name
	Variable treat
	
	if (WaveType(Chan0WRW, 1) != 4)
		Abort "In DispRatio(Chan0WRW, ...): \rWrong wave type"
	elseif (WaveType(Chan1WRW, 1) != 4)
		Abort "In DispRatio(Chan0WRW, ...): \rWrong wave type"
	elseif (WaveType(RatioWRW, 1) != 4)
		Abort "In DispRatio(Chan0WRW, ...): \rWrong wave type"
	endif
	
	if (numpnts(chan0WRW) == 0 || numpnts(chan1WRW) == 0 || numpnts(RatioWRW) == 0)
		Abort "In DispRatio(Chan0WRW, ...): \rEmpty wave reference wave!"
	endif
	
	if (numpnts(chan1WRW) != numpnts(chan0WRW) || numpnts(RatioWRW) != numpnts(chan0WRW))
		Abort "In DispRatio(Chan0WRW, ...): \rIncompatible wave reference waves!"
	endif
	
	DFREF MainPack = $KS_F_MAIN
	SVAR Calib = MainPack:gStrCalib
	
	Variable i, j, isThereAnyPeak = 0, areThereCalciumData = 0, arePeaksInTheGraph, peakSerialInGraph
	String graphName, titleStr, rTraceName, cTraceName, roiName, annotation
	
	if (!ParamIsDefault(CaWRW))
		
		if (WaveType(CaWRW, 1) != 4)
			Abort "In DispRatio(Chan0WRW, ...): \rWrong wave type"
		endif
		
		if (numpnts(CaWRW) == 0)
			Abort "In DispRatio(Chan0WRW, ...): \rEmpty wave reference wave!"
		endif
		
		if (numpnts(CaWRW) != numpnts(chan0WRW))
			Abort "In DispRatio(Chan0WRW, ...): \rIncompatible wave reference waves!"
		endif
		
		areThereCalciumData = 1
		
	endif
	
	if (!ParamIsDefault(RPeakWRW))
		
		if (WaveType(RPeakWRW, 1) != 4)
			Abort "In DispRatio(Chan0WRW, ...): \rWrong wave type"
		endif
		
		if (numpnts(RPeakWRW) == 0)
			Abort "In DispRatio(Chan0WRW, ...): \rEmpty wave reference wave!"
		endif
		
		if (areThereCalciumData && ParamIsDefault(CaPeakWRW))
			Abort "In DispRatio(Chan0WRW, ...): \rMissing optional parameter!"
		endif
		
		isThereAnyPeak = 1
		
	endif
	
	if (!ParamIsDefault(CaPeakWRW))
		
		if (WaveType(CaPeakWRW, 1) != 4)
			Abort "In DispRatio(Chan0WRW, ...): \rWrong wave type"
		endif
		
		if (numpnts(CaPeakWRW) == 0)
			Abort "In DispRatio(Chan0WRW, ...): \rEmpty wave reference wave!"
		endif
		
		if (numpnts(RPeakWRW) != numpnts(CaPeakWRW))
			Abort "In DispRatio(Chan0WRW, ...): \rIncompatible wave reference waves!"
		endif
		
	endif
	
	for (i = 0 ; i < numpnts(Chan0WRW); i += 2) 
		
		WAVE Ch0Wave = Chan0WRW[i]
		WAVE Ch0Timeval = Chan0WRW[i + 1]
		WAVE Ch1Wave = Chan1WRW[i]
		WAVE Ch1Timeval = Chan1WRW[i + 1]
		WAVE RatioWave = RatioWRW[i]
		WAVE RatioTimeval = RatioWRW[i + 1]
		
		graphName = name + num2str(i / 2); titleStr = StringByKey("ROI_" + num2str(i/2), StringByKey("ROI_NAMES", note(Ch0Wave)),"=",",",0)
		
		
		if (StringMatch(titleStr, "") != 1)
			Display/N=$graphName Ch0Wave/TN=Channel0 vs Ch0Timeval as titleStr
		else
			Display/N=$graphName Ch0Wave/TN=Channel0 vs Ch0Timeval
		endif
		
		AppendToGraph/L=left Ch1Wave/TN=Channel1 vs Ch1Timeval
		AppendToGraph/L=lRATIO RatioWave/TN=Ratio vs RatioTimeval
		
		if (areThereCalciumData)
			
			WAVE CaWave = CaWRW[i]
			WAVE CaTimeval = CaWRW[i + 1]
			
			ControlBar/T/W=$graphName K_GRAPH_CTRL_BAR_HEIGHT_PIX
			
			AppendToGraph/L=lCALC CaWave/TN=Calcium vs CaTimeval
			ModifyGraph/W=$graphName hideTrace(Ratio)=1
		endif
		
		if (StringMatch(StringByKey("ROI_NAMES", note(Ch0Wave)), "") != 1)
			// If the ROI names are specified append each ROI name to the graph's annotation
			roiName = StringByKey("ROI_" + StringByKey("ROI_CODE", note(Ch0Wave)), StringByKey("ROI_NAMES", note(Ch0Wave)), "=", ",", 0)
			annotation = StringByKey("EXP_CODE", note(Ch0Wave)) + "_" + StringByKey("ROI_CODE", note(Ch0Wave)) + " (" + roiName + ")"
		else
			annotation = StringByKey("EXP_CODE", note(Ch0Wave)) + "_" + StringByKey("ROI_CODE", note(Ch0Wave))
		endif
		
		if (isThereAnyPeak)	
			
			arePeaksInTheGraph = 0
			peakSerialInGraph = 0
			
			for (j = 0 ; j < numpnts(RPeakWRW); j += 2) 
				
				WAVE RPeak = RPeakWRW[j]
				
				if (StringMatch(NameOfWave(RPeak), NameOfWave(RatioWave) + "_*"))
					
					WAVE RTimeval = RPeakWRW[j + 1]
					rTraceName = "RatioPeak_" + num2str(peakSerialInGraph)
					AppendToGraph/L=lRATIOPEAK  RPeak/TN=$rTraceName vs RTimeval
					
					if (areThereCalciumData)
						
						WAVE CaPeak = CaPeakWRW[j]
						WAVE CaTimeval = CaPeakWRW[j + 1]
						
						cTraceName = "CalciumPeak_" + num2str(peakSerialInGraph)
						
						AppendToGraph/L=lCALCPEAK CaPeak/TN=$cTraceName vs CaTimeval
						ModifyGraph/W=$graphName hideTrace($rTraceName)=1
					endif
					
					arePeaksInTheGraph = 1
					peakSerialInGraph += 1
										
				endif
			
			endfor
				
			if (arePeaksInTheGraph)
					
					ModifyGraph axisEnab(bottom)={0,1}, minor(bottom)=1, sep(bottom)=20, fSize(bottom)=10
					ModifyGraph axisEnab(left)={0.68,1}, nticks(left)=2, minor(left)=1, sep(left)=20, lblPos(left)=60, fSize(left)=10
					ModifyGraph axisEnab(lRATIO)={0.34,0.65}, freePos(lRATIO)={Ch0Timeval[0],bottom}, nticks(lRATIO)=2, minor(lRATIO)=1, sep(lRATIO)=20, lblPos(lRATIO)=60, fSize(lRATIO)=10
					ModifyGraph axisEnab(lRATIOPEAK)={0,0.31}, freePos(lRATIOPEAK)={Ch0Timeval[0],bottom}, nticks(lRATIOPEAK)=2, minor(lRATIOPEAK)=1, sep(lRATIOPEAK)=20,lblPos(lRATIOPEAK)=60, fSize(lRATIOPEAK)=10
					Label left, "\f01ROI-BGD\r(Arbitrary Units)"
					Label bottom, "\f01Time (s)"	
					Label lRATIO, "\f01Ratio"
					Label lRATIOPEAK, "\f01Ratio"
					
					Textbox/C/N=text1/A=MT/B=1/E=1 annotation
					
					if (areThereCalciumData)
						
						Button ButtonSwitchTrace win=$graphName, pos={5,5}, size={100,20}, title="Show ratio", userData="CA", proc=LB_Main#ButtonSwitchTraceProc
						
						ModifyGraph axRGB(lRATIO)=(65535,65535,65535),tlblRGB(lRATIO)=(65535,65535,65535), alblRGB(lRATIO)=(65535,65535,65535)
						ModifyGraph axRGB(lRATIOPEAK)=(65535,65535,65535),tlblRGB(lRATIOPEAK)=(65535,65535,65535), alblRGB(lRATIOPEAK)=(65535,65535,65535)
						
						ModifyGraph axisEnab(lCALC)={0.34,0.65}, freePos(lCALC)={Ch0Timeval[0],bottom}, nticks(lCALC)=2, minor(lCALC)=1, sep(lCALC)=20,lblPos(lCALC)=60, fSize(lCALC)=10
						ModifyGraph axisEnab(lCALCPEAK)={0,0.31}, freePos(lCALCPEAK)={Ch0Timeval[0],bottom}, nticks(lCALCPEAK)=2, minor(lCALCPEAK)=1, sep(lCALCPEAK)=20,lblPos(lCALCPEAK)=60, fSize(lCALCPEAK)=10
						Label lCALC, "\f01[Ca\S2+\M]\Bi\M (uM)"
						Label lCALCPEAK, "\f01[Ca\S2+\M]\Bi\M (uM)"
						
					endif
						
				else
					
					ModifyGraph axisEnab(bottom)={0,1}, fSize(bottom)=10
					ModifyGraph axisEnab(left)={0.525,1}, lblPos(left)=60, fSize(left)=10
					ModifyGraph axisEnab(lRATIO)={0,0.475}, freePos(lRATIO)={Ch0Timeval[0],bottom}, lblPos(lRATIO)=60, fSize(lRATIO)=10
					Label left, "\f01ROI-BGD\r(Arbitrary Units)"
					Label bottom, "\f01Time (s)"	
					Label lRATIO, "\f01Ratio"
					
					Textbox/C/N=text1/A=MT/B=1/E=1 annotation
				
					if (areThereCalciumData)
						
						Button ButtonSwitchTrace win=$graphName, pos={5,5}, size={100,20}, title="Show ratio", userData="CA", proc=LB_Main#ButtonSwitchTraceProc
						
						ModifyGraph axRGB(lRATIO)=(65535,65535,65535),tlblRGB(lRATIO)=(65535,65535,65535), alblRGB(lRATIO)=(65535,65535,65535)
						
						ModifyGraph axisEnab(lCALC)={0,0.475}, freePos(R2)={Ch0Timeval[0],bottom}, lblPos(lCALC)=60, fSize(lCALC)=10
						Label lCALC, "\f01[Ca\S2+\M]\Bi\M (uM)"
						
					endif
					
				endif
			
		else
			
			ModifyGraph axisEnab(bottom)={0,1}, fSize(bottom)=10
			ModifyGraph axisEnab(left)={0.525,1}, lblPos(left)=60, fSize(left)=10
			ModifyGraph axisEnab(lRATIO)={0,0.475}, freePos(lRATIO)={Ch0Timeval[0],bottom}, lblPos(lRATIO)=60, fSize(lRATIO)=10
			Label left, "\f01ROI-BGD\r(Arbitrary Units)"
			Label bottom, "\f01Time (s)"	
			Label lRATIO, "\f01Ratio"
			
			Textbox/C/N=text1/A=MT/B=1/E=1 annotation
			
			if (areThereCalciumData)
				
				Button ButtonSwitchTrace win=$graphName, pos={5,5}, size={100,20}, title="Show ratio", userData="CA", proc=LB_Main#ButtonSwitchTraceProc
				
				ModifyGraph axRGB(lRATIO)=(65535,65535,65535),tlblRGB(lRATIO)=(65535,65535,65535), alblRGB(lRATIO)=(65535,65535,65535)
				
				ModifyGraph axisEnab(lCALC)={0,0.475}, freePos(lCALC)={Ch0Timeval[0],bottom}, lblPos(lCALC)=60, fSize(lCALC)=10
				Label lCALC, "\f01[Ca\S2+\M]\Bi\M (uM)"
						
			endif
			
		endif
		
		if (treat)
			Treatment(Ch0Wave, graphName)
		endif
		
	endfor
End


Static Function Treatment(displayedWave, windowName)
// Synopsis: displays the details of the treatment(s) of a wave in the wave's graph. 
// Details: 
//          Draws rectangles on the top graph according to the displayed wave's treatments. 
//          It also puts a legend in the rectangle's top left corner with the name of the treatment. 
//          Only the named wave's treatments (each) will be displayed. 
//          If window name is specified the named window will be brought front first and the function will be 
//          executed on that window.
// Parameters: 
//             WAVE displayedWave: the wave of which treatment's is to be displayed. 
//             String windowName: 
// Return Value(s): -
// Side effects: 
//               See details. 
// 
	WAVE displayedWave
	String windowName
	
	Variable i, numOfTreat = str2num(StringByKey("NUMOFTREAT", note(displayedWave)))
	Variable  actTreat_start, actTreat_end, prevTreat_end = 0, fpatt = 4, yPercent = 0
	String actTreat_name
	
	if (numOfTreat == 0)
		return NaN
	endif
	
	SetDrawLayer/W=$windowName ProgBack
	SetDrawEnv/W=$windowName xcoord=bottom,fillfgc=(34816,34816,34816),fsize=7, fillpat=fpatt, linethick=0.00, textyjust=2, save
	
	for (i = 0; i < numOfTreat; i +=1)
		
		actTreat_name = StringByKey("TREAT" + num2str(i) + "_NAME", note(displayedWave))
		actTreat_start = str2num(StringByKey("TREAT" + num2str(i) + "_START", note(displayedWave)))
		actTreat_end = str2num(StringByKey("TREAT" + num2str(i) + "_END", note(displayedWave)))
		
		// For clearity, if there are overlapping treatments, the latter one's rectangle's height will be reduced
		// and it's color will be darkend. 
		if (actTreat_start < prevTreat_end)																					
			
			fpatt -= 1
			SetDrawEnv/W=$windowName fillpat = fpatt, save
			yPercent += 0.05
			
		endif
		
		DrawRect/W=$windowName actTreat_start, yPercent, actTreat_end, 1
		DrawText/W=$windowName actTreat_start, yPercent, actTreat_name
		
		prevTreat_end = actTreat_end
		
	endfor
	
	SetDrawLayer/W=$windowName UserFront
End


Static Function LoadPictures(oblName, fluoName)
// Synopsis: Opens two load picture dialog boxes - one after another - to load the example pictures from the experiment. 
// Details: 
//          The first image is the oblique illuminated and the second is the fluorescent one. 
// Parameters: -      
// Return Value(s): 
//                  0 if no pictures are successfully loaded. 
//                  1 if at leas one picture is successfully loades. 
// Side effects: See synopsis and details. 
// 
	String oblName, fluoName
	
	Variable l = 0
	
	LoadPICT/Q/O/M="Choose the oblique illuminated picture" , $oblName
	
	if (V_flag)
		l = 1
	endif
	
	LoadPICT/Q/O/M="Choose the fluorescent image" , $fluoName
	
	if (V_flag)
		l = 1
	endif
	
	return l
End


Static Function AssembleTheLabbook()
// Synopsis: Generates a formatted notebook of the experiment. 
// Details: 
//          In the first block ,the details of the experiment are listed. 
//          After that there are two images from the experiment loaded by the LoadPictures function. 
//          At the end there are images of the graphs in the experiment. 
// Parameters: -
// Return Value(s): -
// Side effects: see above. 
// 
	// Getting the necessary informations for the labbook form the various data folders. 
	DFREF MainPackage = $KS_F_MAIN
	DFREF ExpDetails = $KS_F_EXP_DETAILS
	DFREF ImpDetails = $KS_F_IMP_DETAILS
	
	NVAR BGDMode = MainPackage:gVarBGDMode
	NVAR ChanNum = MainPackage:gVarChanNum
	NVAR LB_Version = MainPackage:gVarLB_Version
	SVAR BGD0Name = MainPackage:gStrBGD0Name
	SVAR BGD1Name = MainPackage:gStrBGD1Name	
	SVAR Chan0List = MainPackage:gStrChan0List
	SVAR Chan1List = MainPackage:gStrChan1List	
	SVAR TimevalName = MainPackage:gStrTimevalName	
	SVAR Calib = MainPackage:gStrCalib
	SVAR Species = ExpDetails:gStrSpecies
	SVAR Sex = ExpDetails:gStrSex
	SVAR Strain = ExpDetails:gStrStrain
	SVAR Genotype = ExpDetails:gStrGenotype
	SVAR Prep_type = ExpDetails:gStrPrep_type
	SVAR Exp_temp = ExpDetails:gStrExp_temp
	SVAR Exp_code = ExpDetails:gStrExp_code
	SVAR Exp_note = ExpDetails:gStrExp_note
	SVAR Exp_site = ExpDetails:gStrExp_site
	SVAR Dye_name = ExpDetails:gStrDye_name
	SVAR Reg_num = ExpDetails:gStrReg_num
	SVAR Unique_num = ExpDetails:gStrUnique_num
	SVAR Cut_sol = ExpDetails:gStrCut_sol
	SVAR Exp_sol = ExpDetails:gStrExp_sol
	SVAR WaveNote = ExpDetails:gStrWaveNote
	NVAR NumOfTreat = ExpDetails:gVarNumOfTreat
	NVAR Age = ExpDetails:gVarAge
	SVAR FileName = ImpDetails:S_fileName
	NVAR TraceNum = ImpDetails:V_Flag
	SVAR Loading_proc = ExpDetails:gStrLoading_proc
	
	
	NVAR/Z Loading_cc = ExpDetails:gVarLoading_cc
	NVAR/Z Loading_time = ExpDetails:gVarLoading_time
	NVAR/Z Impulse_ampl = ExpDetails:gVarImpulse_amplitude
	NVAR/Z Impulse_count = ExpDetails:gVarImpulse_count
	NVAR/Z Impulse_dur = ExpDetails:gVarImpulse_duration
	NVAR/Z Pipette_resist = ExpDetails:gVarPipette_resist
	SVAR/Z Loading_cc_unit = ExpDetails:gStrLoadingCC_unit
	SVAR/Z Loading_temp = ExpDetails:gStrLoading_temp
	
	
	String nb = "Labbook_" + Exp_code					// If the notebook will be saved, the offered name of the file will be
																// the name, not the title of the notebook
	// Defining the labbook
	DoWindow/F $nb											//If it was alredy present, then kill it
	if (V_Flag != 0)
		DoWindow/K $nb
	endif
	
	NewNotebook/N=$nb/F=1/V=1/K=0/W=(363.75,107,960,494.75)	as "Labbook_" + Exp_code
	Notebook $nb defaultTab=36, statusWidth=252, writeprotect=1
	Notebook $nb showRuler=0, rulerUnits=2, updating={1, 60}
	
	// Defining the rulers
	Notebook $nb newRuler=Normal, justification=0, margins={56,56,468}, spacing={0,0,0}, tabs={}, rulerDefaults={"Calibri",12,0,(0,0,0)}
	Notebook $nb newRuler=Heading_0, justification=1, margins={0,0,468}, spacing={0,0,0}, tabs={}, rulerDefaults={"Arial",22,5,(0,0,0)}
	Notebook $nb newRuler=Heading_1, justification=0, margins={0,0,468}, spacing={0,0,0}, tabs={}, rulerDefaults={"Arial",14,5,(0,0,0)}
	Notebook $nb newRuler=Footnote, justification=0, margins={0,0,468}, spacing={0,0,0}, tabs={}, rulerDefaults={"Arial",12,2,(0,0,0)}
	// Writing the main title, the animak and experiment details. 
	String text
	sprintf text, "Labbook of experiment %s\r\r", Exp_code
	Notebook $nb ruler=Heading_0, text=text
	Notebook $nb ruler=Heading_1, text="Experiment Details:\r"
	Notebook $nb ruler=Normal, text ="\r"
	sprintf text, "%d days old %s %s \r", Age, Strain, Species; Notebook $nb, text=text
	sprintf text, "Sex: %s \r", Sex; Notebook $nb, text=text
	sprintf text, "Genotype: %s \r", Genotype; Notebook $nb, text=text
	sprintf text, "Preparation: %s \r", Prep_type; Notebook $nb, text=text
	sprintf text, "Cutting solution: %s \r", Cut_sol; Notebook $nb, text=text
	sprintf text, "Experiment solution: %s \r", Exp_sol; Notebook $nb, text=text
	sprintf text, "Experiment temperature: %s \r", Exp_temp; Notebook $nb, text=text
	sprintf text, "Experiment site: %s \r", Exp_site; Notebook $nb, text=text
	
	// Writing the dye loading details. 
	strswitch(Loading_proc)
		case "Bulk loading":
			sprintf text, "Dye loading: %s with %s, %d %s, %d min, %s \r", Loading_proc, Dye_name, Loading_cc, Loading_cc_unit, Loading_time, Loading_temp ; Notebook $nb, text=text
			break
		case "Continuous perfusion":
			sprintf text, "Dye loading: %s with %s, %d %s, %d min, %s \r", Loading_proc, Dye_name, Loading_cc, Loading_cc_unit, Loading_time, Loading_temp ; Notebook $nb, text=text
			break
		case "Electroporation":
			sprintf text, "Dye loading: %s with %s, %d %s, %d impulse(s) \r", Loading_proc, Dye_name, Loading_cc, Loading_cc_unit, Impulse_count ; Notebook $nb, text=text
			sprintf text, "Pipette resistance: %d MOhm, impulse amplitude: %d uA, impulse duration: %d ms \r", Pipette_resist, Impulse_ampl, Impulse_dur; Notebook $nb, text=text
			break
		case "Micropipette loading":
			sprintf text, "Dye loading: %s with %s, %d %s \r", Loading_proc, Dye_name, Loading_cc, Loading_cc_unit; Notebook $nb, text=text
			break
	endswitch
	
	// Writing the calcium calibration details. 
	if (StringMatch(Dye_name, "*Fura*") == 1)
		sprintf text, "Calcium calibration: \r"; Notebook $nb, text=text, margins={112,112,468}
		sprintf text, "Date: %s, Name: %s \r", StringByKey("DATE", Calib , "=", ",", 0), StringByKey("NAME", Calib , "=", ",", 0); Notebook $nb, text=text
		sprintf text, "Kd: %s, Rmin: %s, Rmax: %s, beta: %s. \r", StringByKey("KD", Calib , "=", ",", 0), StringByKey("RMIN", Calib , "=", ",", 0), StringByKey("RMAX", Calib , "=", ",", 0), StringByKey("BETA", Calib , "=", ",", 0); Notebook $nb, text=text
		Notebook $nb, margins={56,56,468}
	endif
	
	// Writing the treatments. 
	Notebook $nb, text="Treatments: \r"; Notebook $nb, margins={112,112,468}  
	variable i 
	String TreatName, StartName, EndName
	for (i = 0; i < NumOfTreat; i += 1)
		TreatName = "gStrTreat" + num2str(i) + "_name"
		StartName = "gVarTreat" + num2str(i) + "_start"
		EndName = "gVarTreat" + num2str(i) + "_end"
		SVAR pTreat = ExpDetails:$(TreatName); NVAR pStart = ExpDetails:$(StartName), pEnd = ExpDetails:$(EndName)
		sprintf text, "Treatment #%d: %s, %d s - %d s \r", i, pTreat, pStart, pEnd; Notebook $nb, text=text
	endfor
	
	// Writing the experiment note.
	Notebook $nb, margins={56,56,468}, text ="\r"
	Notebook $nb ruler=Heading_1, text="Experiment Note:\r"
	Notebook $nb ruler=Normal; Notebook $nb, text="\r" + Exp_note + "\r"
	
	// Writing the details about the imported file and traces.
	Notebook $nb, margins={56,56,468}, text ="\r"
	Notebook $nb ruler=Heading_1, text="Details of imported data:\r"
	Notebook $nb ruler=Normal, text ="\r"
	sprintf text, "Name of the imported file: %s \r", FileName; Notebook $nb, text=text
	sprintf text, "Number of imported traces: %d \r", TraceNum; Notebook $nb, text=text
	sprintf text, "Name of the Timeval trace: %s \r", TimevalName; Notebook $nb, text=text
		
	if (ChanNum == 1)
		sprintf text, "Names of the Data traces: %s \r", Chan0List; Notebook $nb, text=text
		sprintf text, "Name of the Background trace: %s \r", BGD0Name; Notebook $nb, text=text
	else
		sprintf text, "Names of the Data traces for channel 1: \r\t%s \r", Chan0List; Notebook $nb, text=text
		sprintf text, "Name of the Background trace for channel 1: %s \r", BGD0Name; Notebook $nb, text=text
		sprintf text, "Names of the Data traces for channel 2: \r\t%s \r", Chan1List; Notebook $nb, text=text
		sprintf text, "Name of the Background trace for channel 2: %s \r", BGD1Name; Notebook $nb, text=text
	endif
	
	String BGDModeStr
	if (BGDMode == 0)
		BGDModeStr = "Whole BGD trace "
	else
		BGDModeStr = "BGD constant "
	endif
	Notebook $nb ruler=Normal, text="BGD subtraction mode: " + BGDModeStr + "\r\r"
	
	Notebook $nb ruler=FootNote
	sprintf text, "This labbook was created with Labbook Maker v%.2f on %s. ", LB_Version, Secs2Date(DateTime,-2, "/"); Notebook $nb, text=text
	Notebook $nb specialChar={1, 0, ""}
	
	// Drawing the pictures exported form the experiment
	DFREF SaveDf = GetDataFolderDFR()
	
	// Somehow IGOR saves an S_info string if I use the PICTInfo operation, or the Notebook operation with the picture key. 
	//    I avoided that using a temporary free data folder. 
	SetDataFolder NewFreeDataFolder()
	String oblName = "OBL_" + Exp_code, fluoName = "FLUO_" + Exp_code
	if (LoadPictures(oblName, fluoName))
		Variable sf = 0
		Notebook $nb ruler=Heading_1, text="Pictures:\r"
		Notebook $nb ruler=Normal, text="Oblique illumination:\r"
		if (StringMatch(PICTList(oblName, ";", ""), "") == 0)											          // if the picture exists
			sf = LB_Util#ScalePic(oblName)																// getting the scale factor for the image
			Notebook $nb scaling={sf,sf}, picture={$oblName, 0, 1}, text="\r\r"
		endif
		Notebook $nb ruler=Normal, text="Fluorescent image:\r"
		if (StringMatch(PICTList(oblName, ";", ""), "") == 0)
			sf = LB_Util#ScalePic(fluoName)
			Notebook $nb scaling={sf,sf}, picture={$fluoName, 0, 1}, specialChar={1, 0, ""}
		endif
	endif
	
	KillPICTs/A/Z                                                                      // After saving the pictures into the notebook they are unnecessary. 
	                                                                                   // Also it avoids saving the S_info at every save command. 
	Notebook $nb selection={StartOfFile,EndOfFile}, convertToPNG=1
	Notebook $nb selection={EndOfFile,EndOfFile}		
	
	// Drawing the graphs of the individual traces
	Notebook $nb ruler=Heading_1, text="Individual Traces:\r"
		
	String objName
	
	Variable index = 0
	do 
		
		objName = "Graph" + num2str(index)
		
		DoWindow $objName
		
		if (!V_flag)
			break
		endif
		
		Variable x0 = 0, y0 = 0
		
		Notebook $nb picture={$objName(x0, y0, x0 + K_NB_GRAPH_WIDTH, y0 + K_NB_GRAPH_HEIGHT), 8, 1}
		Notebook $nb text="\r"

		index += 1
	while (1)
	
	SetDataFolder SaveDf
	
	Notebook $nb selection={StartOfFile,StartOfFile}    // Jumping to the top of the notebook. 
	
	KillStrings/Z root:S_info
	
	String tbExec = "MoveWindow/W=" + nb + " 0,0,0,0"
	Execute/Q/Z tbExec
End


Static Function ButtonSwitchTraceProc(B_Struct) : ButtonControl
// Synopsis: Action procedure for the switch trace button on the output graphs of ratiometric experiments (if the calcium traces are
//              also present). 
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
	STRUCT WMButtonAction &B_Struct
	
	switch(B_Struct.eventCode)
		case 1: // Mouse down
			
			String visibleTraces, allNormalTraces, hiddenTraces, toBeHiddenTraces, item
			
			visibleTraces = TraceNameList(B_Struct.win,";",1+4)
			allNormalTraces = TraceNameList(B_Struct.win,";",1)
			hiddenTraces = RemoveFromList(visibleTraces,allNormalTraces)
			toBeHiddenTraces = RemoveFromList("Channel0;Channel1;",visibleTraces)
			
			Variable i
			for (i = 0; i < ItemsInList(hiddenTraces); i += 1)
				item = StringFromList(i, hiddenTraces)
				ModifyGraph/W=$B_Struct.win HideTrace($item)= 0
			endfor
		
			for (i = 0; i < ItemsInList(toBeHiddenTraces); i += 1)
				item = StringFromList(i, toBeHiddenTraces)
				ModifyGraph/W=$B_Struct.win HideTrace($item)= 2
			endfor
			
			if (strlen(ListMatch(hiddenTraces, "*Ratio*")) != 0)
				
				ModifyGraph axisOnTop(lRATIO)=1,axRGB(lRATIO)=(0,0,0),tlblRGB(lRATIO)=(0,0,0), alblRGB(lRATIO)=(0,0,0)
				ModifyGraph axisOnTop(lCALC)=0,axRGB(lCALC)=(65535,65535,65535),tlblRGB(lCALC)=(65535,65535,65535), alblRGB(lCALC)=(65535,65535,65535)
				
				if (strlen(ListMatch(hiddenTraces, "*Peak*")) != 0)
					ModifyGraph axisOnTop(lRATIOPEAK)=1,axRGB(lRATIOPEAK)=(0,0,0),tlblRGB(lRATIOPEAK)=(0,0,0), alblRGB(lRATIOPEAK)=(0,0,0)
					ModifyGraph axisOnTop(lCALCPEAK)=0,axRGB(lCALCPEAK)=(65535,65535,65535),tlblRGB(lCALCPEAK)=(65535,65535,65535), alblRGB(lCALCPEAK)=(65535,65535,65535)
				endif
				
			else
				
				ModifyGraph axisOnTop(lCALC)=1,axRGB(lCALC)=(0,0,0),tlblRGB(lCALC)=(0,0,0), alblRGB(lCALC)=(0,0,0)
				ModifyGraph axisOnTop(lRATIO)=0,axRGB(lRATIO)=(65535,65535,65535),tlblRGB(lRATIO)=(65535,65535,65535), alblRGB(lRATIO)=(65535,65535,65535)
				
				if (strlen(ListMatch(hiddenTraces, "*Peak*")) != 0)
					ModifyGraph axisOnTop(lCALCPEAK)=1,axRGB(lCALCPEAK)=(0,0,0),tlblRGB(lCALCPEAK)=(0,0,0), alblRGB(lCALCPEAK)=(0,0,0)
					ModifyGraph axisOnTop(lRATIOPEAK)=0,axRGB(lRATIOPEAK)=(65535,65535,65535),tlblRGB(lRATIOPEAK)=(65535,65535,65535), alblRGB(lRATIOPEAK)=(65535,65535,65535)
				endif
				
			endif
			
			if (StringMatch(B_Struct.userData, "RATIO") == 1)
				Button ButtonSwitchTrace win=$B_Struct.win, title="Show ratio", userData="CA"
			else
				Button ButtonSwitchTrace win=$B_Struct.win, title="Show calcium", userData="RATIO"
			endif
			
			break
	endswitch
	
	return 0
End


Static Function GetCalibrationData(CalibWave)
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
	WAVE/T &CalibWave
	
	Variable f1, i
	String calfilePath = LB_Util#GetCalibFilePath()
	
	Open/R/Z f1 as calfilePath
	
	if (V_flag)                                 // If the file does not exist just create an empty document and return. 
		Open/A f1 as calfilePath
		Close f1
		return NaN
	endif
	
	String aLine, linesList = ""
	
	i = 0
	do
		FReadLine f1, aLine
		
		if (strlen(aLine) == 0)
			break
		endif
		
		if (i == 0)                   // Skip the first line, which contains the header. 
			i += 1
			continue
		endif
		
		linesList += aLine + ";"
		
		i += 1
	while (1)
	
	Close f1
	
	if (ItemsInList(linesList) != 0)
		Redimension/N=(ItemsInList(linesList), 6) CalibWave
	endif
	
	String item, year, month, day, name, kD, rMin, rMax, b
	
	String expr = "([[:digit:]]{4})/([[:digit:]]{2})/([[:digit:]]{2})\t(.*)\t([.[:digit:]]*)\t([.[:digit:]]*)\t([.[:digit:]]*)\t([.[:digit:]]*)"
			
	for (i = 0; i < ItemsInList(linesList); i += 1)
		
		item = StringFromList(i, linesList)
		
		SplitString/E=(expr) item, year, month, day, name, kD, rMin, rMax, b
		
		if (strlen(year) == 0 || strlen(month) == 0 || strlen(day) == 0 || strlen(kD) == 0 || strlen(rMin) == 0 || strlen(rMax) == 0 || strlen(b) == 0)
			// If there are missing data (except the name) in the textfile it is considered to be corrupted
			// In this case: 
			DeleteFile/Z calfilePath                      // Delete the file. 
			Open/A f1 as calfilePath               // Create a new blank file. 
			Close f1
			
			Redimension/N=(1, 6) CalibWave                // Redimension the CalibWave and reset its values to "". 
			CalibWave = ""
			
			DoAlert 0, "The fura_calibrations.txt file was corrupted, hence it was deleted. \rA new blank file was created instead. Please add new calibrations to work with! \rUse the Labbook-> Options-> Add a New Calcium Calibration menu item! "
			
			return NaN
		endif
		
		CalibWave[i][0] = year + "/" + month + "/" + day
		CalibWave[i][1] = name
		CalibWave[i][2] = kD
		CalibWave[i][3] = rMin
		CalibWave[i][4] = rMax
		CalibWave[i][5] = b
		
	endfor
End


Static Function AddCalibration()
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
	
	Variable kD, rMin, rMax, b
	String year, month, day, name
	String calfilePath = LB_Util#GetCalibFilePath()
	
	Prompt year, "Year: ", popup LB_Util#DateLists("Year", from = 2000, to = 2020)
	Prompt month, "Month: ", popup LB_Util#DateLists("Month")
	Prompt day, "Day: ", popup LB_Util#DateLists("Day")
	Prompt name, "Name: "
	Prompt kD, "Kd: "
	Prompt rMin, "Rmin: "
	Prompt rMax, "Rmax: "
	Prompt b, "beta: "
	DoPrompt "Please give the details of the calibration. ", year, month, day, name, kD, rMin, rMax, b
	
	if (V_Flag)
		return NaN
	endif
	
	DFREF MainPack = $KS_F_MAIN
	WAVE/T CalibWave = MainPack:CalibWave
	
	if (StringMatch(CalibWave[DimSize(CalibWave, 0)-1][0], "") != 1)
		Redimension/N=(DimSize(CalibWave, 0) + 1, 6) CalibWave 
	endif
	
	CalibWave[DimSize(CalibWave, 0)-1][0] = year + "/" + LB_Util#MonthStr2NumChar(month) + "/" + day
	CalibWave[DimSize(CalibWave, 0)-1][1] = LB_Util#CheckText(name)                           // CheckText is necessary, becouse name can contain any characters. 
	CalibWave[DimSize(CalibWave, 0)-1][2] = num2str(kD)
	CalibWave[DimSize(CalibWave, 0)-1][3] = num2str(rMin)
	CalibWave[DimSize(CalibWave, 0)-1][4] = num2str(rMax)
	CalibWave[DimSize(CalibWave, 0)-1][5] = num2str(b)
	
	Make/FREE/T/N=(DimSize(CalibWave, 0)) dWave, nWave, kDWave, maxWave, minWave, bWave
	
	dWave = CalibWave[p][0]                                              // For sorting, CalibWave's columns must be decomposed to separate waves. 
	nWave = CalibWave[p][1]
	kDWave = CalibWave[p][2]
	minWave = CalibWave[p][3]
	maxWave = CalibWave[p][4]
	bWave = CalibWave[p][5]
	
	Sort/A {dWave, nWave}, dWave, nWave, kDWave, minWave, maxWave, bWave // Sorting with date as a primary key and name as a secondary key. 
	
	CalibWave[][0] = dWave[p]                                            // Putting the sorted columns into CalibWaves. 
	CalibWave[][1] = nWave[p]
	CalibWave[][2] = kDWave[p]
	CalibWave[][3] = minWave[p]
	CalibWave[][4] = maxWave[p]
	CalibWave[][5] = bWave[p]
	
	DeleteFile/Z calfilePath                                  // Writing the new data into the textfile for saving. 
	
	Variable f1
	Open/A f1 as calfilePath
	
	fprintf f1,  "Date\tName\tKd\tRmin\tRmax\tbeta\r"
	wfprintf f1, "" dWave, nWave, kDWave, minWave, maxWave, bWave
	
	Close f1
End


Static Function DeleteCalibration()
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
	DFREF MainPack = $KS_F_MAIN
	WAVE/T CalibWave = MainPack:CalibWave
	
	String list = "", item
	String calfilePath = LB_Util#GetCalibFilePath()
	Variable i, choosenNo
	
	for (i = 0; i < DimSize(CalibWave, 0); i += 1)
		list += num2Str(i + 1) + ":   " + CalibWave[i][0] + "   " + CalibWave[i][1] + ";"
	endfor
	
	Prompt item, "Calibrations: ", popup, list
	DoPrompt "Select the calibration to use! ", item
	
	if (V_Flag)
		return 0
	endif
	
	String num = item[0, StrSearch(":", item, 0) + 1] // num is 1 based!
	choosenNo = str2num(num) - 1                      // choosenNo is now 0 based!
	
	DeletePoints choosenNo, 1, CalibWave
	
	Make/FREE/T/N=(DimSize(CalibWave, 0)) dWave, nWave, kDWave, maxWave, minWave, bWave
	
	dWave = CalibWave[p][0]                                             // For sorting, CalibWave's columns must be decomposed to separate waves. 
	nWave = CalibWave[p][1]
	kDWave = CalibWave[p][2]
	minWave = CalibWave[p][3]
	maxWave = CalibWave[p][4]
	bWave = CalibWave[p][5]
	
	Sort/A {dWave, nWave}, dWave, nWave, kDWave, minWave, maxWave, bWave // Sorting with date as a primary key and name as a secondary key. 
	
	CalibWave[][0] = dWave[p]                                            // Putting the sorted columns into CalibWaves.                                    
	CalibWave[][1] = nWave[p]
	CalibWave[][2] = kDWave[p]
	CalibWave[][3] = minWave[p]
	CalibWave[][4] = maxWave[p]
	CalibWave[][5] = bWave[p]
	
	DeleteFile/Z calfilePath                                  // Writing the new data into the textfile for saving. 
	
	Variable f1
	Open/A f1 as calfilePath
	
	fprintf f1,  "Date\tName\tKd\tRmin\tRmax\tbeta\r"
	wfprintf f1, "" dWave, nWave, kDWave, minWave, maxWave, bWave
	
	Close f1
End



Static Function LabbookPackageVersion()
// Synopsis: Returns the current version of the Labbook Package. 
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
	return 1.02
End


Static Function CheckLabbookPackageVersion()
// Synopsis: 
//           If the LabbookMaker is about to be opened in a formerly saved labbook experiment, it is necessary to check 
//           the version of the labbook maker with which the labbook was created. If the version is identical with the 
//           version of the current labbook pack it returns 1, otherwise it returns 0. 
// Parameters: -
// Return Value(s): 
//                  1 if the version of the current labbook is identical with the saved labbook. 
//                  0 otherwise. 
// Side effects: -
// Error message(s): -              
//
	if (DataFolderExists(KS_F_MAIN))
		
		DFREF MainPack = $KS_F_MAIN
						
		NVAR/Z LB_Version = MainPack:gVarLB_Version
		if (NVAR_Exists(LB_Version))
			
			if (LB_Version == LabbookPackageVersion())
				
				return 1
				
			else
				
				return 0
				
			endif
			
		else
			
			return 0
			
		endif
		
	endif
End


Static Function CheckIfSavedLabbook()
// Synopsis: Checkes if the the labbook maker is about to opened in a formerly saved labbook. 
// Details: It checkes if one of the directories of Labbook Maker exists. 
//          If so it returns 1
//          If not it returns 0
// Parameters: -
// Return Value(s): see above.  
// Side effects: -
// Error message(s): -              
//
	if (DataFolderExists(KS_F_MAIN) || DataFolderExists(KS_F_PEAK_CLIPPER_PACK) || DataFolderExists(KS_F_EXP_DETAILS) || DataFolderExists(KS_F_RAW))
		
		return 1
		
	elseif (DataFolderExists(KS_F_BGDCORR) || DataFolderExists(KS_F_CA) || DataFolderExists(KS_F_RATIO) || DataFolderExists(KS_F_PEAKS))
		
		return 1
		
	else
		
		return 0
		
	endif

End


Static Function/S GetTabPostfix(ctrlName)
// Synopsis: Returns a postfix code used in tab control names to identify the various controls belonging to
//               a particular tab page. 
// Details: All controls found in either pages of the "main" tab control have a postfix "_main" int their
//              name. For example all controls found in the 3rd page of the main tab control have the postfix
//              "_main2". (Numbering starts from 0 as usual.)
// Parameters: 
//             String ctrlName: the name of the particular tab control. 
// Return Value(s): A string containing the postfix for the particular tab control. 
// Side effects: -
//   
	String ctrlName
	
	if (strlen(ctrlName) == 0)
		return ""
	endif
	
	if (StringMatch(ctrlName, "main") == 1)
		return "_main"
	elseif (StringMatch(ctrlName, "treat_main3") == 1)
		return "_treat"
	endif	
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


Function UpdateLabbook ()
	AssembleTheLabbook()
End


Function TestDialog()
	BGDInputDialog()
end


Function testcopy ([name, waveNote])
	String name
	String waveNote
	DFREF target = root:Packages:LabbookControlPanel:work_BGDCorrTraces
	DFREF dest = root:BGDCorrectedData
	
	if (!ParamIsDefault(name) && ParamIsDefault(waveNote))
		CopyWaves(LB_Util#GetWaveRefsDFR(target, 1), dest, name = name)
	elseif (!ParamIsDefault(name) && !ParamIsDefault(waveNote))
		CopyWaves(LB_Util#GetWaveRefsDFR(target, 1), dest, name = name, waveNote = waveNote)
	else
		CopyWaves(LB_Util#GetWaveRefsDFR(target, 1), dest)
	endif
	
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                      OBSOLETE FUNCITONS                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Static Function DispOld(WRW, [name, hostName, treat])
//// Synopsis: Displays the waves passed by the wave reference wave (WRW).
//// Details: 
////          The waves in the WRW must be consistent. 
////          The sequence of the waves in the WRW must be: timeval wave, ywaves and so on. 
////          If the WRW is produced with the LB_Util#GetWaveRefsDFR() function, than the formers are guaranteed. 
////          The ywaves are displayed against the last timeval wave. 
////          Each wave is displayed in a different Graph. 
////          The details of the treatments are also displayed in the graph. 
////          If hostName is specified than all graphs are embedded in the specified host window. 
//// Parameters: 
////             WAVE/WAVE WRW: a wave reference wave containing the wave references of the waves 
////                            to be displayed. 
////             String name (OPTIONAL): the common name of the resulting graphs. After the common name there are
////                          numbers from 0 up to distinguish between the particular graphs. If it's not
////                          specified the default name is "Graph". 
////             String hostName (OPTIONAL): the name of a window into which the graph(s) are embedded. 
////             Variable treat (OPTIONAL): If 1 the treatment informations will be drafted on the wave's graph, 
////                                        if 0 they won't. The default is 1. 
//// Return Value(s): -
//// Side effects: 
////               Creates graphs for all the ywaves.
//// Error message(s):   
////                   If the input wave's type is not appropriate. 
////                   If the host window does not exist (if specified). 
////                   If wrong value is given to treat. 
//	WAVE/WAVE WRW
//	String name
//	String hostName
//	Variable treat
//	
//	if (WaveType(WRW, 1) != 4)
//		Abort "In Disp(WRW, ...): \rWrong wave type"
//	endif
//	
//	if (ParamIsDefault(name))
//		name = "Graph"
//	endif
//	
//	if (!ParamIsDefault(hostName))
//		DoWindow $hostName
//		if (V_Flag == 0)
//			Abort "In Disp(WRW, ...): \rHost window doesn't exist"
//		endif
//	endif
//	
//	if (ParamIsDefault(treat))
//		treat = 1
//	endif
//	
//	if (treat != 0 && treat != 1)
//		Abort "In Disp(WRW, ...): \rWrong value for treat"
//	endif
//	
//	
//	Variable i
//	for (i = 0 ; i < numpnts(WRW) - 1; i += 2) 
//		
//		WAVE WaveToDisplay = WRW[i]
//		WAVE Timeval = WRW[i + 1]
//
//		String graphName = name + num2str(i / 2)
//		
//		if (!ParamIsDefault(hostName))
//			Display/HOST=$hostName/N=$graphName WaveToDisplay vs Timeval
//		else
//			Display/N=$graphName WaveToDisplay vs Timeval
//		endif
//		
//		Label left, "\Z12ROI-BGD (Arbitrary Units)"
//		Label bottom, "\Z12Time (s)"
//		Textbox/C/N=text1/A=MT/B=1/E=1 StringByKey("EXP_CODE", note(WaveToDisplay)) + "_" + StringByKey("ROI_CODE", note(WaveToDisplay))
//		
//		if (treat)
//			Treatment(WaveToDisplay)
//		endif
//		
//	endfor
//End

//Static Function ToTable(WRW, [tableName]) 
//// Synopsis: Creates a table from the waves passed by the wave reference wave (WRW). 
//// Details: The sequence of the waves in the table is the sequence of the wave references in WRW. 
////          The name of the folder is controlled by the optional parameter tableName. The default 
////              name is the name of the first wave's parent data folder. 
//// Parameters: 
////             WAVE/WAVE WRW: a wave reference wave containing the wave references of the waves 
////                            to be displayed in the table. 
////             String tableName (OPTIONAL): a string containing the desired name fo the table. 
////                              The default is the parent data folder of the first wave in WRW. 
//// Return Value(s): -
//// Side effects: see above.
////               Minimizes the table's window.  
////
//	WAVE/WAVE WRW
//	String tableName
//	
//	if (WaveType(WRW, 1) != 4)
//		Abort "Wrong wave type"
//	endif
//	
//	if (ParamIsDefault(tableName))
//		tableName = GetDataFolder(0, GetWavesDataFolderDFR(WRW[0]))
//	endif
//	
//	DFREF saveDFR = GetDataFolderDFR()
//	
//	DoWindow/F $tableName
//	if (V_Flag != 0)
//		DoWindow/K $tableName
//	endif
//	
//	Edit/N=$tableName
//	
//	Variable i
//	for (i = 0 ; i < numpnts(WRW) ; i += 1) 
//		WAVE WaveToAppend = WRW[i]
//		AppendToTable/W=$tableName WaveToAppend
//	endfor
//	
//	String tbExec = "MoveWindow/W=" + tableName + " 0,0,0,0"
//	Execute/Q/Z tbExec
//	SetDataFolder saveDFR
//End