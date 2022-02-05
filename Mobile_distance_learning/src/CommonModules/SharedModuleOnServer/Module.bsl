Function GetSettings(Setting) Экспорт

	Query = New Query;
	Query.Text =
	"SELECT
	|	*
	|FROM
	|	InformationRegister.Settings КАК Settings
	|WHERE
	|	Settings.Setting = &Setting";

	Query.SetParameter("Setting", Setting);

	QueryResult = Query.Execute();

	SelectionDetailRecords = QueryResult.SELECT();
	If SelectionDetailRecords.Next() Then
		If Setting = Enums.GeneralSettings.CurrentLevel Тогда
			Return SelectionDetailRecords.Level;
		ElsIf Setting = Enums.GeneralSettings.CurrentMaster Тогда
			Return SelectionDetailRecords.Author;
		ElsIf Setting = Enums.GeneralSettings.NotRefreshLevel Тогда
			Return SelectionDetailRecords.BooleanValue;
		ElsIf Setting = Enums.GeneralSettings.CurrentExt Тогда
			Return SelectionDetailRecords.StringValue;
		EndIf;
	EndIf;

	Return Undefined;

EndFunction

Procedure SetSettings(Setting, Value) Export

	RecordManager = InformationRegisters.Settings.CreateRecordManager();
	RecordManager.Setting = Setting;

	If Setting = Enums.GeneralSettings.CurrentLevel Тогда
		RecordManager.Level = Value;
	ElsIf Setting = Enums.GeneralSettings.CurrentMaster Тогда
		RecordManager.Author = Value;
	ElsIf Setting = Enums.GeneralSettings.NotRefreshLevel Тогда
		RecordManager.BooleanValue = Value;
	ElsIf Setting = Enums.GeneralSettings.CurrentExt Тогда
		RecordManager.StringValue = Value;				
	EndIf;

	RecordManager.Write(True); 

EndProcedure

Function GetCurrentPassword(Master, Level) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	MasterStorage.Password
		|FROM
		|	InformationRegister.MasterStorage AS MasterStorage
		|WHERE
		|	MasterStorage.Master = &Master
		|	AND MasterStorage.Level = &Level";
	
	Query.SetParameter("Level", Level);
	Query.SetParameter("Master", Master);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	If SelectionDetailRecords.Next() Then
		Return SelectionDetailRecords.Password;	
	EndIf;
	
	Return Undefined;
	
EndFunction

Procedure SetCurrentPassword(Master, Level, Password) Export
	
	RecordManager = InformationRegisters.MasterStorage.CreateRecordManager();
	RecordManager.Master = Master;
	RecordManager.Level = Level;
	RecordManager.Password = Password;
	RecordManager.Write(True);	
	
EndProcedure

Function FindMainFile(MainFileCode) Export
	
		Query = New Query;
		Query.Text =
			"SELECT
			|	Files.Ref As File
			|FROM
			|	Catalog.Files AS Files
			|WHERE
			|	Files.MainFileCode = &MainFileCode
			|	AND Files.MainFile = Value(Catalog.Files.EmptyRef)
			|
			|ORDER BY
			|	Files.Code DESC";
		
		Query.SetParameter("MainFileCode", MainFileCode);
		QueryResult = Query.Execute();
		
		SelectionDetailRecords = QueryResult.Select();
		If SelectionDetailRecords.Next() Then
			Return SelectionDetailRecords.File;
		EndIf;
		
		Return Undefined;
		
EndFunction

Function SaveGetDialogueOpenFileFilter(CurrentExt = Undefined) Export
	
	ArrayExt = New Array;
	ArrayExt.Add("Picture jpg (*.jpg)|*.jpg");
	ArrayExt.Add("Picture gif (*.gif)|*.gif");
	ArrayExt.Add("Picture png (*.png)|*.png");
	
	If CurrentExt = Undefined Then
		NewExt = GetSettings(Enums.GeneralSettings.CurrentExt);
	Else
		NewExt = "Picture " + CurrentExt + " (*." + CurrentExt + ")|*." + CurrentExt;
	EndIf;

	If NOT CurrentExt = Undefined Then
		SetSettings(Enums.GeneralSettings.CurrentExt, NewExt);	
	EndIf;
	
	For Each ElementArrayExt In ArrayExt Do
		If NOT StrFind(NewExt,ElementArrayExt) = 0 Then
			Continue;	
		EndIf;
		If NewExt = Undefined Then
			NewExt = ElementArrayExt;
		Else
			NewExt = NewExt + "|" + ElementArrayExt;		
		EndIf;
	EndDo;
	
	Return NewExt;
		
EndFunction
