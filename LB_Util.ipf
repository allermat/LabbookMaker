#pragma rtGlobals = 3			   // Use modern global access method and strict wave access.
#pragma IgorVersion = 6.30      // The above pragma is valid from IGOR 6.30
#pragma version = 1.00
#pragma ModuleName = LB_Util    // I used a Regular Module named Labbook to avoid name conflicts




//********************************************************************************************************************************************************************
//********************************************************************************************************************************************************************
//
// Labbook Maker Utility Functions
// Code for WaveMetrics Igor Pro
// 
// by Máté Aller (allermat@gmail.com)
//
// First Release: 
// Last Modified: 
//
//********************************************************************************************************************************************************************
//********************************************************************************************************************************************************************




// CONSTANTS: 
// Naming conventions: see in LB_Main.ipf
//

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

Static StrConstant KS_MAIN_PANEL_NAME = "LabbookControlPanel"
Static StrConstant KS_PEAK_CLIPPER_NAME = "PeakClipper"
Static StrConstant KS_TIMEVAL_ENDING = "_tv"
Static StrConstant KS_CALFILE_PATH = "\\Igor Procedures\\Labbook\\fura_calibrations.txt"


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                       UTILITY FUNCITONS                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


Static Function/S RemoveExt(fileName)
// Synopsis: Returns the part of fileName string front of the first period (".") character.
// Details: 
//          It usually removes the file's extension (including the period), but if there are additional 
//              periods in the fileName string then the part of the name after the first period will be 
//              also removed! It is suggested to avoid periods in name part separation (eg. instead of 
//              this.is.a.file.csv use this_is_a_file.csv).
//          If there are no periods in the fileName, then the original fileName will be returned. 
//          If the first character of the string is a period, then the original fileName will be returned.
// Parameters: 
//             String fileName: the name of the file to be modified. 
// Return Value(s): 
//                  The fileName string modified according to the above (synopsis and details) description.
// Side effects: -
//
	String fileName
	
	Variable pos = strsearch(fileName, ".", 0)
	
	if (pos == -1 || pos == 0)
		return fileName
	else
		return fileName[0,pos-1]
	endif	
End


Static Function BatchMove(list, type, dest)
// Synopsis: Moves objects in the current data folder specified by the list and type argument to a 
//           destination data folder specified by the dest argument.
// Details: 
//           Only global variables, global strings and waves can be used.
//           All elements in the list argument must refer to the same type of object (eg. global variables OR global strings OR waves)
// Parameters: 
//              String list: A semicolon separated list of objects in the current data folder. The list can be produced 
//                           by the VariableList, StringList, WaveList operations, or manually. 
//              Variable type: Specifies the type of the elements in the list. E.g. 1 for global variables, 2 for global
//                             strings and 3 for waves.
//              DFREF dest: A data folder reference to the destination data folder. 
// Return Value(s): NaN
// Side effects: Moves the specified objects to the specified destination folder. 
//
	String list
	Variable type
	DFREF dest
	
	String objName
	Variable index = 0
	
	if (DataFolderRefStatus(dest) != 0)
		
		do 
			objName = StringFromList(index, list)
			
			if (strlen(objName) == 0)
				break
			endif
			
			switch(type)
				case 1:
					MoveVariable $objName, dest
					break
				case 2:
					MoveString $objName, dest
					break
				case 3:
					MoveWave $objName, dest
					break
			endswitch
			
			index += 1 
		while(1)
		
	endif
End


Static Function/S CheckText(text, [mode])
// Synopsis: Checks and -if necessary- replaces characters in the text argument, which are conflicting with the 
//           KEY:Value; list syntax. (e.g. ":", ";"). 
// Details: 
//          It searches for possible occurrences of ":" and ";" characters and swaps them for "_". 
//          It replaces two consecutive spaces to one. 
// Parameters: 
//             String text: the string to be checked and corrected. 
//             Variable mode (OPTIONAL): if 1 the separator strings of the KEY=Value, list syntax are also replaced. (e.g. "=", ",").
// Return Value(s): 
//                  The argument string modified according to the before mentioned rules. 
// Side effect(s): -
// 
	String text
	Variable mode
	
	if (ParamIsDefault(mode))
		mode = 0
	endif
	
	if (mode != 0 && mode != 1)
		Abort "Error in CheckText(text, [mode]): \rInvalid value for mode!"
	endif
	
	text = ReplaceString(":", text, " ")
	text = ReplaceString(";", text, " ")
	text = ReplaceString("  ", text, " ")
	
	if (mode == 1)
		text = ReplaceString(",", text, " ")
		text = ReplaceString("=", text, " ")
	endif
	
	return text
End


Static Function ScalePic(picName, [finalWidth])
// Synopsis: Returns a scale factor (in %) for the named picture to match the predefined width. 
// Details: If the picture is scaled with this factor (horizontally or both horizontally and vertically) 
//              its width will be equal to the predefined value (finalWidht)
// Parameters: 
//              String picName: The name of a picture in the picture gallery. 
//              Variable finalWidth (OPTIONAL): The desired final width (in pixels) to wich the picture is to be scaled. 
//                                   Its default value is 520 (the desired width in the labbook of the experiment). 
// Return Value(s): 
//                  Variable scaleFactor in % (see details)
//
	String picName
	Variable finalWidth
	
	if (ParamIsDefault(finalWidth))
		finalWidth = 520
	endif
	
	DFREF SaveDf = GetDataFolderDFR()
	
	// Somehow IGOR saves an S_info string if I use the PICTInfo operation, or the Notebook operation with the picture key. 
	//    I avoided that using a temporary free data folder. 
	SetDataFolder NewFreeDataFolder()
	Variable scaleFactor = (finalWidth / str2num(StringByKey("WIDTH", PICTInfo(picName)))) * 100
	SetDataFolder SaveDf
	
	return scaleFactor	
End


Static Function/WAVE GetWaveRefsDFR(targetDFR, mode [, match])
// Synopsis: Returns a wave reference wave (WRW) containing wave references from all waves found in the 
//           specified data folder. 
// Details: 
//          mode = 0 This is the "Plain mode": 
//              No prerequisites, just collects wave references of the waves in the specified folder. 
//              The sequence of the waves in the wave reference wave is the same as in the data folder. 
//          mode = 1 This is the "Consistent waves mode". 
//              The waves in the data folder will be checked for consistency (see: CheckWaveConsistency(listOfWaves))
//              The sequence of the wave references in the WRW is determined by the alphanumeric sequence of the wave names. 
//              Every wave is followed by its timeval wave. 
//          Subfolders in the specified folder will NOT be included.            
//          The created WRW will be a FREE wave, e.g. will not be part of any data folder hierarchy. Name conflict issues are 
//              avoided this way. See the Free Waves section of IGOR manual for further informations. 
// Parameters: 
//             DFREF targetDFR: the target data folder's data folder reference.
//             Variable mode: if 0: "Plain mode"
//                            if 1: "Consistent waves mode" (see above)
//             String match OPTIONAL: a string which can be used as a match criterion to include waves in the folder. 
//                                    Wildcard characters can be used, see the documentation for StringMatch function in 
//                                    the IGOR Manual for further details.  
// Return Value(s): 
//                  A WRW containing all the wave's references in the data folder
// Side effects: - 
// Error message(s): 
//                   If targetDFR doesn't exist. 
//                   If the value of mode is invalid. 
//                   If there are no waves in the target data folder. 
//                   If the waves in the target data folder aren't consistent (if mode 1 is specified). 
//               
	DFREF targetDFR
	Variable mode
	String match
	
	if (DataFolderRefStatus(targetDFR) == 0)
		Abort "Error in GetWaveRefsDFR(targetDFR, mode): \rNon existent data folder!"
	endif
	
	if (mode != 0 && mode != 1)
		Abort "Error in GetWaveRefsDFR(targetDFR, mode): \rInvalid value for mode!"
	endif
	
	if (ParamIsDefault(match))
		match = "*"
	endif
	
	DFREF saveDFR = GetDataFolderDFR()
	
	SetDataFolder targetDFR
	String listOfWaves = WaveList(match,";","")
	SetDataFolder saveDFR
	
	if (ItemsInList(listOfWaves) == 0)
		Abort "Error in GetWaveRefsDFR(targetDFR, mode): \rNo waves found in the specified data folder!"
	endif
	
	if (mode == 1)
		
		if (CheckWaveConsistency(listOfWaves))
			Abort "Error in GetWaveRefsDFR(targetDFR, mode): \rThere is (at least) one missing timeval wave!"
		endif 
		
		listOfWaves = SortList(listOfWaves, ";", 16)   // Setting the names in the list in ascending alphanumeric order.
		                                               // It guarantees, the desired sequence of waves (the timeval first).
	endif
	                                               
	Make/FREE/WAVE/N=(ItemsInList(listOfWaves)) WRW
	
	SetDataFolder targetDFR
	
	String aWaveName
	Variable i = 0
	do

		aWaveName = StringFromList(i, listOfWaves) 
		
		if (strlen(aWaveName) == 0)
			break
		endif
		
		WAVE aWave = $aWaveName
		WRW[i] = aWave
		
		i += 1
	while (1)
	
	SetDataFolder saveDFR
	
	return WRW
End


Static Function/WAVE GetWaveRefsList(targetDFR, list)
// Synopsis: Returns a wave reference wave (WRW) containing references of waves in the target data folder corresponding with the wave names 
//           specified in the list argument.  
// Details: 
//          The sequence of wave references will be the same fo the sequence of wave names in the list argument. 
//          Subfolders in the specified folder will NOT be included.            
//          The created WRW will be a FREE wave, e.g. will not be part of any data folder hierarchy. Name conflict issues are 
//              avoided this way. See the Free Waves section of IGOR manual for further informations. 
// Parameters: 
//             DFREF targetDFR: the target data folder's data folder reference.
//             String list: a semicolon delimited list of wave names. See more about lists in the IGOR Manual. 
// Return Value(s): 
//                  A WRW containing the references of the specified waves in the data folder. 
// Side effects: - 
// Error message(s): 
//                   If targetDFR doesn't exist. 
//                   If there are no items in the list argument. 
//                   If any waves specified in the list argument do not exist.  
//               
	DFREF targetDFR
	String list
	
	if (DataFolderRefStatus(targetDFR) == 0)
		Abort "Error in GetWaveRefsList(targetDFR, list): \rNon existent data folder!"
	endif
	
	if (ItemsInList(list) == 0)
		Abort "Error in GetWaveRefsList(targetDFR, list): \rNo items found in the specified list!"
	endif
	
	DFREF saveDFR = GetDataFolderDFR()
	
	Make/FREE/WAVE/N=(ItemsInList(list)) WRW
	
	SetDataFolder targetDFR
	
	String aWaveName
	Variable i = 0
	do

		aWaveName = StringFromList(i, list) 
		
		if (strlen(aWaveName) == 0)
			break
		endif
		
		WAVE aWave = $aWaveName
		
		if (!WaveExists(aWave))
			Abort "Error in GetWaveRefsList(targetDFR, list): \rNon existent wave in the list!"
		endif
		
		WRW[i] = aWave
		
		i += 1
	while (1)
	
	SetDataFolder saveDFR
	
	return WRW
End


Static Function CheckWaveConsistency(listOfWaves)
// Synopsis: Checks a list of waves for consistency.  
// Details: A set of waves is said to be consistent if for all the y-waves in the set there is a corresponding timeval wave (x-wave)
//              in the set. The function determines the consistency by examining the names of the waves. The timeval wave has a 
//              distinctive postfix after the experiment code. More on this in the help pages.   
// Parameters: 
//              String listOfWaves: a semicolon serparated list of waves. 
// Return Value(s): 
//                  Returns 0 if the waves in the list are found to be consistent. 
//                  Returns 1 if at least one instance of inconsistence is found. (The function returns at the first instance.)
//                  Returns -1 if listOfWaves is empty.
// Side effects: -
//               
	String listOfWaves
	
	if (stringmatch(listOfWaves,""))
		return -1
	endif
	
	String aTimevalName, item
	String yWaveList = ListMatch(listOfWaves, "!*" + KS_TIMEVAL_ENDING)
	String timevalWaveList = ListMatch(listOfWaves, "*" + KS_TIMEVAL_ENDING)
	
	Variable i = 0, l = 0
	
	do
		item = StringFromList(i, yWaveList)
		
		if (stringmatch(item,""))
			break
		endif
		
		aTimevalName = item + KS_TIMEVAL_ENDING
		
		if (WhichListItem(aTimevalName, timevalWaveList, ";", 0, 0) == -1)
			l = 1
			break
		endif

		i += 1
	while (1)
	
	if (l)	
		return 1
	else
		return 0
	endif
End


Static Function DeleteWindows(windowTypes, tagString, [exclude])
// Synopsis: Deletes all windows in the experiment that match the specifications. 
// Parameters: 
//             Variable windowTypes: specifies which types of windows are to be considered for deletion. 
//                 windowTypes is one of:
//                    1:      Graphs
//                    2:      Tables
//                    4:      Layouts
//                   16:      Notebooks
//                   64:      Panels
//                  128:      Procedure windows
//                  512:      Help windows
//                  4096:     XOP target windows (e.g., Gizmo 3D plots)
//                  or a bitwise combination of the above for more than one type of inclusion. See Setting Bit Parameters on 
//                  page IV-12 of IGOR manual for details about bit settings. 
//             String tagString: all windows of selected type(s) having this string in their names (anywhere) will be included in the 
//                 to be deleted list, and eventually will be deleted. The evaluation is not case sensitive. If a zero length string ("") 
//                 is specified than all windows of the selected type(s) are included in the to be deleted list, regardless of their names. 
//                 (Use this if you want to delete all windows of one or more types.)
//             Variable exclude (OPTIONAL): if specified and its value is 1 then all windows of selected type(s) having this 
//                 tagString in their names will be EXCLUDED from the to be deleted list, and eventually all other selected windows
//                 will be deleted BUT these. 
// Examples: 
//           DeleteWindows(1, "final_"): this will delete all graphs whose names contains the "final_" string. 
//           DeleteWindows(1, "final_", exclude = 1): this will delete all graphs in the experiment except those which have the 
//                                                       "final_" string in their name.
//           DeleteWindows(1, ""): this will delete all graphs in the experiment. 
//           DeleteWindows(1, "", exclude = 1): this won't do anything, do not use this.  
// Return Value(s): -
// Side effects: see above. 
// 
	Variable windowTypes
	String tagString
	Variable exclude
		
	Variable index = 0
	String windowsList 
	String actualWin
	String winTypeStr = "WIN:" + num2str(windowTypes)
	
	if (ParamIsDefault(exclude))
		exclude = 0
	endif
	
	if (exclude != 0 && exclude != 1)
		return NaN
	endif
	
	if (exclude == 1)
		windowsList = WinList("!*" + tagString + "*",";",winTypeStr)
	else
		windowsList = WinList("*" + tagString + "*",";",winTypeStr)
	endif
	
	do
		actualWin = StringFromList(index, windowsList)
		
		if (strlen(actualWin) == 0)
			break
		endif
		
		DoWindow $actualWin                                 // Sets the value of variable V_flag: 1 if the named window exists, 0 if not. 
		
		if (V_flag)
			DoWindow/K $actualWin
		endif
		
		index += 1	
	while (1)
End


Static Function ZapDataInFolderTree(path)
// Synopsis: Kills the contents of a data folder and the contents of its children without 
//           killing any data folders and without attempting to kill any waves that may be in use.
// Parameters: 
//              String path: contains the full path of the data folder to be ereased. 
// Return Value(s): -
// Side effects: see syopsis. 
// 
	String path
	
	String savDF= GetDataFolder(1)
	SetDataFolder path
	
	KillWaves/A/Z
	KillVariables/A/Z
	KillStrings/A/Z
	
	Variable i
	Variable numDataFolders = CountObjects(":", 4)
	for(i=0; i<numDataFolders; i+=1)
		String nextPath = GetIndexedObjName(":", 4, i)
		ZapDataInFolderTree(nextPath)
	endfor
	
	SetDataFolder savDF
End


Static Function IsDataFolderEmpty(target)
// Synopsis: Checks if the specified target datafolder is empty. 
// Details: It takes waves, global variables, global strings and subfolders into account. 
// Parameters: 
//             DFREF target: A data folder reference to the target data folder. 
// Return Value(s): 
//                   1 if the target data folder is empty. 
//                   0 if the target data folder is NOT empty. 
//                  -1 if the target data folder reference is not valid. 
// Side effects: - 
//
	DFREF target
	
	if (DataFolderRefStatus(target) == 0)
		return -1
	endif
	
	Variable i, count = 0
	
	for (i = 1; i <= 4; i += 1)
		count = CountObjectsDFR(target, i)
		if (count > 0)
			return 0
		endif
	endfor
	
	return 1
End


Static Function FindClosestValue(value, targWave)
// Synopsis: Finds the location of a point in targWave, which value is the nearest to the specified value. 
// Details: The algorithm uses the FindValue operation to find the value on the wave. It starts with an arbitrarily
//          choosen tolerance limit, and iteratively raises it till a matching value is found. 
//          The starting tolerance limit is the smallest step between any neighbouring points in the targ wave divided
//              by 1000. 
//          If the tolerance limit exceedes the range of targWave and still no point is found NaN is returned. 
//          CAUTION: it is tested only with one dimensional, strictly monotonic waves so far. 
// Parameters: 
//              Variable value: the value we seek. 
//              WAVE targWave: the wave in wich we seek the value. 
// Return Value(s): 
//                  The location (in point number) of a point in targWave, which value is the nearest to the specified value. 
//                  NaN if the tolerance limit exceedes the range of targWave. 
// Side effects: - 
// Error message(s): -
//	
	Variable value
	WAVE targWave
	
	Variable step = FindSmallestStep(targWave) / 1000
	Variable tol = step
	Variable pos = NaN
	
	do 
		
		if (tol > (WaveMax(targWave) - WaveMin(targWave)))
			return NaN
		endif
		
		FindValue/T=(tol)/V=(value) targWave
		
		pos = V_value
		
		if (V_value != -1)
			break
		endif
		
		tol += step
		
	while(1)
	
	return pos
End


Static Function FindSmallestStep(targWave)
// Synopsis: Finds the smallest step between any two neighbouring points in targWave. 
// Details: -
// Parameters: 
//              WAVE targWave: the wave of interest. 
// Return Value(s): 
//                  The minimum of the absoulute differences between the values of any two neighbouting points 
//                  in the wave. 
// Side effects: -
// Error message(s): - 
//
	WAVE targWave
	
	Variable i, val, minimum
	minimum = abs(targWave[1] - targWave[0])
	
	for(i = 1; i < DimSize(targWave, 0) - 1; i += 1)
		
		val = abs(targWave[i + 1] - targWave[i])
		
		if (val < minimum)
			minimum = val
		endif
	
	endfor
	
	return minimum
End


Static Function CmpLists(list1, list2)
// Synopsis: Compares two list and returns the truth about is there any identical elements in the lists. 
// Details: 
//           The separator string of the lists must be ";" 
// Parameters: 
//              String list1, list2: the two list to be compared. 
// Return Value(s): 
//                  0 if there is no identical element. 
//                  1 if there is at leas one identical element. 
//                  -1 if any of the two list is empty ("")
// Side effects: -
// Error message(s): -
//
	String list1, list2
	
	if (StringMatch(list1, "") == 1 || StringMatch(list2, "") == 1)
		return -1
	endif
	
	Variable i, l = 0
	
	for (i = 0; i < ItemsInList(list1); i += 1)
		if (StringMatch(ListMatch(list2, StringFromList(i, list1)), "") == 0)
			l = 1
		endif
	endfor
	
	return l
End


Static Function KillGlobalList(TargFolder, list, mode)
// Synopsis: 
// Description/Details: 
// Parameters: 
//              
// Return Value(s): NaN
//                  
// Side effects: 
//               
// Error message(s):
//                   
//
	DFREF TargFolder
	String list
	Variable mode
	
	String item; Variable i = 0
	
	do
		item = StringFromList(i, list)
		
		if (strlen(item) == 0)
			break
		endif
		
		if (mode == 0)
			
			NVAR gVItem = TargFolder:$(item)
			KillVariables/Z gVItem
		
		elseif (mode == 1)
			
			SVAR gSItem = TargFolder:$(item)
			KillStrings/Z gSItem
		
		endif
		
		i += 1
	while (1)
End


Static Function GetScreenDimsPix(width, height)
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
	Variable &width, &height
	
	String screenInfo = StringByKey("SCREEN1", IgorInfo(0))
	
	String expr = "DEPTH=([[:digit:]]*),RECT=([[:digit:]]*),([[:digit:]]*),([[:digit:]]*),([[:digit:]]*)"
	
	String depth, left, top, right, bottom
	
	SplitString/E=(expr) screenInfo, depth, left, top, right, bottom
	
	width = str2num(right)
	height = str2num(bottom)
End


Static Function GetWaveIndexWRW(WRW, name)
// Synopsis: Returns the serial number of a wave in a wave reference wave (WRW). Returns -1 is the wave is not
//              found in the WRW. 
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
	WAVE/WAVE WRW
	String name
	
	if (WaveType(WRW, 1) != 4)
		Abort "In GetWaveIndexWRW(WRW, name): \rWrong wave type!"
	endif
	
	if (StringMatch(name, "") == 1)
		Abort "In GetWaveIndexWRW(WRW, name): \rEmpty string for name!"
	endif
	
	Variable i
	for (i = 0; i < numpnts(WRW); i += 1)
		if (StringMatch(NameOfWave(WRW[i]), name) == 1)
			return i
		endif 
	endfor
	
	return -1
End


Static Function/S DateLists(mode, [from, to])
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
	String mode
	Variable from, to
	
	String list = ""
	Variable i
	
	if (StringMatch(mode, "Day") == 1)
		
		for (i = 1; i <= 31; i += 1)
			
			if (i < 10)
				list += "0" + num2str(i) + ";"
			else
				list += num2str(i) + ";"
			endif
		endfor 
		
	elseif (StringMatch(mode, "Month") == 1)
		
		list = "January;February;March;April;May;June;July;August;September;October;November;December;"
		
	elseif (StringMatch(mode, "Year") == 1)
		
		if (ParamIsDefault(from) || ParamIsDefault(to))
			Abort "In DateLists(mode, ...): \rMissing parameters: from, to. "
		endif
		
		if (to < from)
			Variable temp = from
			from = to
			to = temp
		endif
		
		for (i = from; i <= to; i += 1)
			
			list += num2str(i) + ";"
			
		endfor
		
	endif
	
	return list
End


Static Function/S OneCharMonth(monthStr)
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
	String monthStr
	
	if (strlen(monthStr) != 2)
		Abort "Error in OneCharMonth(monthStr): \rWrong imput parameter!"
	endif
	
	
	if (StringMatch(monthStr[0], "0") == 1)
		
		return monthStr[1]
	
	else
		
		if (StringMatch(monthStr, "10") == 1)
			return "o"
		elseif (StringMatch(monthStr, "11") == 1)
			return "n"
		elseif (StringMatch(monthStr, "12") == 1)
			return "d"
		else
			Abort "Error in OneCharMonth(monthStr): \rWrong imput parameter!"
		endif
	
	endif
End



Static Function/S MonthStr2NumChar(month, [mode])
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
	String month
	Variable mode
	
	if (ParamIsDefault(mode))
			mode = 0
	endif
	
	if (mode != 0 && mode != 1)
		Abort "MonthStr2NumChar(month, ...): \rInvalid value for mode! "
	endif
	
	strswitch (month)
		case "January":
			
			if (mode == 0)
				return "01"
			else
				return "1"
			endif
			
			break
		case "February":	
			
			if (mode == 0)
				return "02"
			else
				return "2"
			endif
			
			break
		case "March":
			
			if (mode == 0)
				return "03"
			else
				return "3"
			endif
			
			break
		case "April":
			
			if (mode == 0)
				return "04"
			else
				return "4"
			endif
			
			break
		case "May":
			
			if (mode == 0)
				return "05"
			else
				return "5"
			endif
			
			break
		case "June":
			
			if (mode == 0)
				return "06"
			else
				return "6"
			endif
			
			break
		case "July":
			
			if (mode == 0)
				return "07"
			else
				return "7"
			endif
			
			break
		case "August":
			
			if (mode == 0)
				return "08"
			else
				return "8"
			endif
			
			break
		case "September":
			
			if (mode == 0)
				return "09"
			else
				return "9"
			endif
			
			break
		case "October":
			
			if (mode == 0)
				return "10"
			else
				return "o"
			endif
			
			break
		case "November":
			
			if (mode == 0)
				return "11"
			else
				return "n"
			endif
			
			break
		case "December":
			
			if (mode == 0)
				return "12"
			else
				return "d"
			endif
			
			break
	endswitch
	
	return ""
End


Static Function/WAVE GetFoldersDFRWave()
// Synopsis: 
// Description/Details: 
// Parameters: 
//              
// Return Value(s): 
//                  
// Side effects: 
//               
// Error message(s):
//                   
//
	
	String dfList = KS_F_BGDCORR + ";" + KS_F_CA + ";" + KS_F_PEAKS_BGD + ";" + KS_F_PEAKS_DFPERFO + ";" + KS_F_PEAKS_RATIO + ";" + KS_F_PEAKS_CA + ";"
	dfList += KS_F_RATIO + ";" + KS_F_WORK_PEAKS + ";" + KS_F_WORK_RATIO + ";" + KS_F_WORK_BGDCORR + ";" + KS_F_WORK_FO 
	
	Make/DF/FREE/N=(ItemsInList(dfList)) DfWave

	Variable i
	for (i = 0; i < ItemsInList(dfList); i += 1)
		
		DFREF actDFR = $StringFromList(i, dfList)
		
		DfWave[i] = actDFR
		
	endfor
	
	return DfWave
End


// **********
// Sample API
// **********
// Synopsis: 
// Description/Details: 
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

Function TestDelete ()
	DeleteWindows(1, "graph")
End


Function testRef(folder, mode)
	String folder
	Variable mode
	DFREF folderDFR = $folder 
	SetDataFolder root:
	ListWaves(GetWaveRefsDFR(folderDFR, mode))
End


Function ListWaves(WRW)
	WAVE/WAVE WRW
	Variable i
	for (i = 0; i < numpnts(WRW); i += 1)
		Wave actual = WRW[i]
		Print NameOfWave(actual) + "\r"
	endfor
End


Function testcons(folder)
	String folder
	DFREF folderDFR = $folder
	SetDataFolder folder
	String listOfWaves = WaveList("*",";","")
	print CheckWaveConsistency(listOfWaves)
End


Function Testempty()
	DFREF target = root:something
	print IsDataFolderEmpty(target)
End


Function TestCmp()
	Print CmpLists("", "rtz;uioppou;567;asd;")
	Print CmpLists("asd;ert;joo;123;", "")
	Print CmpLists("	asd;ert;joo;123;", "rtz;uioppou;567;")
	Print CmpLists(	"asd;ert;joo;123;", "rtz;uioppou;567;asd;")
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                      OBSOLETE FUNCITONS                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


Static Function/S CollectExpIDs(listOfWaves)
// Synopsis: Extracts the unique experiment IDs from a list of wave names which are named according to
//               the wave naming conventions. 
// Details: The wave's ExpID is the part of the name ahead of the last "_" character. 
//          The wave naming conventions can be found in the general considerations section of the help. 
// Parameters: 
//             String listOfWaves: a semicolon separated list of wave names. 
// Return Value(s): 
//                  A semicolon separated string list containing the unique experiment IDs from the list 
//                      of wave names. 
//                  Returns empty string ("") if listOfWaves is empty and if idLength < 1. 
// Side effects: -
//               
	String listOfWaves
	Variable idLength
	
	if (stringmatch(listOfWaves,""))
		return ""
	endif
	
	String listOfExpIDs = "", item, expID
	Variable i
	
	listOfWaves = SortList(listOfWaves, ";", 16)           // setting the names in the list in ascending alphanumeric order
	
	i = 0
	do 
		item = StringFromList(i, listOfWaves)
		
		if (stringmatch(item,""))
			break
		endif

		expID = item[0,strsearch(item, "_", Inf, 1) - 1]    // Extract the ExpID from the wave's name (the part ahead the last
		                                                    //     "_"character in the name of the wave. 
		do 
			i += 1
			item = StringFromList(i, listOfWaves)            // iterate through elements witch have the same expID
			
			if (!stringmatch(item, expID + "*"))
				break
			endif
			
		while(1)
		
		listOfExpIDs += expID + ";"                         // add the current expID to the list of experiments
	while(1)
	
	return listOfExpIDs
End