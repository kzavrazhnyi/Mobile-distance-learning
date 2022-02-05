
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If NOT ValueIsFilled(Constants.InfoBaseID.Get()) Then
		SystemInfo = New SystemInfo();
		Constants.InfoBaseID.Set(SystemInfo.ClientID);		
	EndIf;

	Level = SharedModuleOnServer.GetSettings(Enums.GeneralSettings.CurrentLevel);
	Master = SharedModuleOnServer.GetSettings(Enums.GeneralSettings.CurrentMaster);
	NotRefreshLevel = SharedModuleOnServer.GetSettings(Enums.GeneralSettings.NotRefreshLevel);
	
	CurrentPassword = SharedModuleOnServer.GetCurrentPassword(Master, Level);

	Items.GroupService.Visible = False;
	Items.CurrentPassword.Visible = False;
	Items.SearchString.Visible = False;
	Items.CommandsHTML.Visible = False;
	
	Items.TextHTML.ReadOnly = True;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	SectionOnChange(Undefined);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NotRefreshLevelOnChange(Item)
	
	NotRefreshLevelOnChangeAtServer(NotRefreshLevel);
	
EndProcedure

&AtServerNoContext
Procedure NotRefreshLevelOnChangeAtServer(NotRefreshMasterAndLevel)
	
	SharedModuleOnServer.SetSettings(Enums.GeneralSettings.NotRefreshLevel, NotRefreshMasterAndLevel);
	
EndProcedure

&AtClient
Procedure SectionOnChange(Item)

	If Не Item = Undefined Then
		CurrentStage = Undefined;
	EndIf;

	FrontPicture = "";
	Items.FrontPicture.Обновить();
	TextHTML = "";
	
	SectionOnChangeOnServer();
	CurrentFileOnChange(Undefined);
	
	OpenButtonsStageTitle = NStr("en = 'Select stage'; ru = 'Выберите этап'");
	Items.OpenButtonsStage.Title = OpenButtonsStageTitle + ?(ValueIsFilled(CurrentStage), " (" + String(CurrentStage) + ")", "");

	Items.GroupStages.Visible = True;
	Items.OpenButtonsAdd.Visible = True;
	Items.GoToLink.Title = NStr("en = 'Link';ru = 'Перейти'");
	If Level.IsEmpty() Then
		Items.GroupStages.Visible = False;
		Items.OpenButtonsAdd.Visible = False;
		Items.GoToLink.Title = NStr("en = 'About the master...'; ru = 'Об учителе...'");
		Items.OpenButtonsStage.Title = OpenButtonsStageTitle;
	EndIf;
	
	GroupDataVisible();
		
EndProcedure

&AtClient
Procedure TextHTMLOnClick(Item, EventData, StandardProcessing)
	
	StandardProcessing = False;
	
	If Items.TextHTML.ReadOnly Then
		FrontPictureClick(Item, StandardProcessing);	
	EndIf;
	
EndProcedure

&AtClient
Procedure FrontPictureClick(Item, StandardProcessing)

	StandardProcessing = False;

	If NOT ValueIsFilled(CurrentFile) Then
		Return;
	EndIf;

	FoundCurrentElement = False;
	If ValueIsFilled(CurrentSlaveFile) Then
		For Each ChoiceListElement In Items.CurrentSlaveFile.ChoiceList Do
			If FoundCurrentElement Then
				Break;	
			EndIf;
			If CurrentSlaveFile = ChoiceListElement.Value Then
				FoundCurrentElement = True;	
			EndIf;	
		EndDo;
		If CurrentSlaveFile = ChoiceListElement.Value Then
			CurrentSlaveFile = Undefined;
		Else
			CurrentSlaveFile = ChoiceListElement.Value;
		EndIf;
	ElsIf NOT Items.CurrentSlaveFile.ChoiceList.Count() = 0 Then
		CurrentSlaveFile = Items.CurrentSlaveFile.ChoiceList[0].Value;	
	Else
		CurrentSlaveFile = Undefined;	
	EndIf;

	If NOT ValueIsFilled(CurrentSlaveFile) Then
		//@skip-warning
		FrontPictureStructure = GetAddressFile(CurrentFile, False);
		FrontPicture = FrontPictureStructure.Storage;
		TextHTML = GetFromTempStorage(FrontPictureStructure.TextHTML);
		CurrentPicture = CurrentFile;
	Else
		//@skip-warning
		FrontPictureStructure = GetAddressFile(CurrentSlaveFile, False);
		FrontPicture = FrontPictureStructure.Storage;
		TextHTML = GetFromTempStorage(FrontPictureStructure.TextHTML);
		CurrentPicture = CurrentSlaveFile;
	EndIf;

	GroupDataVisible();

EndProcedure

&AtClient
Procedure CurrentFileSlaveOnChange(Item)
	
	ShowFacePicture();
	
EndProcedure

&AtClient
Procedure SearchStringOnChange(Item)

	SectionOnChange(Undefined);

EndProcedure

&AtClient
Procedure CurrentFileOnChange(Item)
	
	CurrentSlaveFile = Undefined;
	Items.CurrentSlaveFile.ChoiceList.LoadValues(GetSectionOnServer(,, True));
	For Each ItemChoiceList In Items.CurrentSlaveFile.ChoiceList Do
		ItemChoiceList.Presentation = ItemChoiceList.Value;
	EndDo;	
	ShowFacePicture();
	
EndProcedure

&AtClient
Procedure CurrentPasswordOnChange(Item)
	CurrentPasswordOnChangeAsServer(Master, Level, CurrentPassword);
	Message("Password changed!");	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure NextCurrentFile(Command)
	
	If Items.CurrentFile.ChoiceList.Count() = 0 Then
		Return;	
	EndIf;
	
	CurrentNewFile = Items.CurrentFile.ChoiceList[0].Value;
	Counter = 0;
	If ValueIsFilled(CurrentFile) Then
		For Each ItemChoiceList In Items.CurrentFile.ChoiceList Do
			Counter = Counter + 1;
			If ItemChoiceList.Value = CurrentFile 
				AND Counter < Items.CurrentFile.ChoiceList.Count() Then
					CurrentNewFile = Items.CurrentFile.ChoiceList[Counter].Value;
					Break;	
			EndIf;
		EndDo;	
	EndIf;
	CurrentFile = CurrentNewFile;
	
	CurrentFileOnChange(Undefined);
	
EndProcedure

&AtClient
Procedure ChangeFont(Command)
	
	FontChooseDialog = New FontChooseDialog;
	NotifyDescription = New NotifyDescription("FinishChangeFont", ThisObject);
	FontChooseDialog.Show(NotifyDescription);
	
EndProcedure

&AtClient
Procedure BoldFont(Command)
	
	ExecuteHTMLCommand("Bold");
	
EndProcedure

&AtClient
Procedure AlignCenter(Command)

	ExecuteHTMLCommand("justifyCenter");
		
EndProcedure

&AtClient
Procedure NextCurrentSlaveFile(Command)
	
	StandardProcessing = False;
	TextHTMLOnClick(Items.TextHTML, Undefined, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ShowSearchString(Command)
	
	Items.SearchString.Visible = NOT Items.SearchString.Visible;
	
EndProcedure

&AtClient
Procedure SaveTextHTML(Command)
	
	FoundErrors = False;
	
	If NOT ValueIsFilled(Master) Then
		Message("Select Master!");
		FoundErrors = True;	
	EndIf;
	If NOT ValueIsFilled(Level) Then
		Message("Select Level!");
		FoundErrors = True;	
	EndIf;	
	If NOT ValueIsFilled(UpdateFile)
		AND NOT ValueIsFilled(MainFile)
		AND NOT ValueIsFilled(FileDescription) Then
			Message("Fill in the description!");
			FoundErrors = True;	
	EndIf;	
	
	If FoundErrors Then
		Return;
	EndIf;
	
	HTMLDocument = Items.TextHTML.Document;
	innerHTML = HTMLDocument.body.innerHTML;
	
	If NOT innerHTML = "" Then
		innerHTML = "<html><body>" + innerHTML + "</body></html>";	
	EndIf;
	
	NewFile = AddFileStorage(FileDescription, , PutToTempStorage(innerHTML));
	
	If NOT NewFile = Undefined Then
		
		CurrentStage = Undefined;
		LoadValuesCurrentSlaveFile(NewFile);
		ShowFacePicture();
		
		Modified = False;
		
	EndIf;
		
EndProcedure

&AtClient
Procedure OpenService(Command)
	
	If NOT Command = Undefined Then
		Items.CurrentPassword.Visible = NOT Items.CurrentPassword.Visible;
	EndIf;

	#If ThinClient Then
		
		If NOT Command = Undefined Then
			Items.GroupService.Visible = NOT Items.GroupService.Visible;	
		EndIf;	
		Items.CommandsHTML.Visible = Items.GroupService.Visible;
		
		Items.TextHTML.ReadOnly = NOT Items.GroupService.Visible;
		If Items.GroupService.Visible Then
			If TextHTML = "" Then
				TextHTML = "<html><body></body></html>";	
			EndIf;
			EnableHTMLEditModeAtServer();
			//FrontPicture = "";
			StringHyperlink = "";
			FileDescription = "";
			UpdateFile = Undefined;
			MainFile = CurrentFile;
			GroupDataVisible();
		Else
			ShowFacePicture();	
		EndIf;
		
	#EndIf	
	
EndProcedure

&AtClient
Procedure SelectUpdateFile(Command)
	
	UpdateFile = CurrentSlaveFile;
	
EndProcedure

&AtClient
Procedure ClearTextHTML(Command)
	
	TextHTML = "<html><body></body></html>";	
	EnableHTMLEditModeAtServer();
				
EndProcedure


&AtClient
Procedure Pronunciation(Command)
      
	If ValueIsFilled(StringHyperlink) Then
		GotoURL(StringHyperlink);
	EndIf;

EndProcedure

&AtClient
Procedure UnloadToXML(Command)

	#If ThinClient Then
		
		If NOT ValueIsFilled(Master) Then
			Message("Select Master!");
			Return;	
		EndIf;
		If NOT ValueIsFilled(Level) Then
			Message("Select Level!");
			Return;	
		EndIf;
		
		PackageForUnloading = UnloadToXMLAtServer();
		BeginGetFileFromServer(PackageForUnloading, "My_next_level_" 
			+ StrReplace(StringLatin(String(Master)),".","_") + "_" 
			+ StrReplace(StringLatin(String(Level)),".","_") 
			+ ?(ValueIsFilled(CurrentPassword),"_pwd","") + ".xml");
		
	#EndIf
	
EndProcedure

&AtClient
Procedure DownloadSection(Command)

	Items.GroupDownloadSection.Visible = NOT Items.GroupDownloadSection.Visible;

EndProcedure

&AtClient
Procedure DownloadXML(Command)

	If NOT ValueIsFilled(URLString) Then
		Message("Required URL!");
		Return;
	EndIf;

	HTTPS = False; 

	If NOT StrFind(URLString,"http://") = 0 Then
		MyURLString = StrReplace(URLString,"http://","");
	ElsIf NOT StrFind(URLString,"https://") = 0 Then
		MyURLString = StrReplace(URLString,"https://","");
		HTTPS = True;
	Else		
		Message("Required http:// or https:// string URL!");
		Return;			
	EndIf;

	FirstStrFind = StrFind(MyURLString,"/");
	If FirstStrFind = 0 Then
		Message("Required correct URL!");
		Return;
	EndIf;
	
	ServerURL = Left(MyURLString, FirstStrFind - 1);
	MyURLString = Right(MyURLString,StrLen(MyURLString) - FirstStrFind + 1);
	
	If HTTPS Then
		ssl = New OpenSSLSecureConnection();  
		MyHTTPConnection = New HTTPConnection(ServerURL,,,,,,ssl);
	Else
		MyHTTPConnection = New HTTPConnection(ServerURL);				
	EndIf;
	
	Message("Server connection: "+ServerURL);
	MyHTTPRequest = New HTTPRequest(MyURLString);
	HTTPResponse = MyHTTPConnection.Get(MyHTTPRequest);
	BodyString = HTTPResponse.GetBodyAsString();

	Message("Received: "+MyURLString);
	Message("Loading data ...");

	#If NOT WebClient Then
	BodyStringXMLCharacter = FindDisallowedXMLCharacters(BodyString);
	If NOT BodyStringXMLCharacter = 0 Then
		Message("Error XML Characters: "+Mid(BodyString,BodyStringXMLCharacter,1));
	EndIf;
	#EndIf
	
	DisplayError = False;
	#If ThinClient Then
		DisplayError = True;
	#EndIf		
	LoadXMLAtServer(BodyString, DisplayError);

	Items.GroupDownloadSection.Visible = False;
	Items.CurrentPassword.Visible = False;
	
	NewPicture(Command);

EndProcedure

&AtClient
Procedure AddFile(Command)

	If Не ValueIsFilled(Master) Then
		Сообщить("Select Master!");
		Return;
	EndIf;

	#If ThinClient Then
		
	DialogueOpenFile = New FileDialog(FileDialogMode.Open);
	DialogueOpenFile.FullFileName = "";
	DialogueOpenFile.Filter = SharedModuleOnServer.SaveGetDialogueOpenFileFilter();
	DialogueOpenFile.Multiselect = False;
	DialogueOpenFile.Title = "Select File";

	Notify = New NotifyDescription("UploadPictureCompletion", ThisObject);
    //@skip-warning
	BeginPutFile(Notify, , DialogueOpenFile, True, UUID);

	#EndIf

EndProcedure

&AtClient
Procedure Today(Command)

	If AddMode Then
		AddServerLearningStage(PredefinedValue("Enum.LearningSteps.Today"));
	Else
		CurrentStage = PredefinedValue("Enum.LearningSteps.Today");		
	EndIf;
	
	CloseButtonsStage(Command);

EndProcedure

&AtClient
Procedure Tomorrow(Command)

	If AddMode Then
		AddServerLearningStage(PredefinedValue("Enum.LearningSteps.Tomorrow"));
	Else
		CurrentStage = PredefinedValue("Enum.LearningSteps.Tomorrow");		
	EndIf;

	CloseButtonsStage(Command);

EndProcedure

&AtClient
Procedure Week(Command)

	If AddMode Then
		AddServerLearningStage(PredefinedValue("Enum.LearningSteps.Week"));
	Else
		CurrentStage = PredefinedValue("Enum.LearningSteps.Week");		
	EndIf;
	
	CloseButtonsStage(Command);

EndProcedure

&AtClient
Procedure SelectedMonth(Command)

	If AddMode Then
		AddServerLearningStage(PredefinedValue("Enum.LearningSteps.Month"));
	Else
		CurrentStage = PredefinedValue("Enum.LearningSteps.Month");		
	EndIf;

	CloseButtonsStage(Command);

EndProcedure

&AtClient
Procedure Repetition(Command)

	If AddMode Then
		AddServerLearningStage(PredefinedValue("Enum.LearningSteps.Repeat"));
	Else
		CurrentStage = PredefinedValue("Enum.LearningSteps.Repeat");		
	EndIf;
	
	CloseButtonsStage(Command);

EndProcedure

&AtClient
Procedure NewPicture(Command)

	CurrentStage = Undefined;
	SectionOnChange(Undefined);

EndProcedure

&AtClient
Procedure OpenButtonsAdd(Command)

	AddMode = True;

	OpenButtonsStage(Command);

EndProcedure

&AtClient
Procedure CloseButtonsAdd(Command)

	SectionOnChange(Undefined);

	Items.GroupBottomButtons.Visible = False;
	Items.GroupPictures.Visible = True;

EndProcedure

&AtClient
Procedure OpenButtonsStage(Command)

	FillCountsStages();

	Items.GroupPictures.Visible = False;
	Items.GroupStages.Visible = False;
	Items.GroupNext.Visible = False;
	
	Items.GroupUpperButtons.Visible = True;
	

EndProcedure

&AtClient
Procedure CloseButtonsStage(Command)

	AddMode = False;
	
	SectionOnChange(Undefined);
	
	Items.GroupUpperButtons.Visible = False;
	
	Items.GroupPictures.Visible = True;
	Items.GroupStages.Visible = True;
	Items.GroupNext.Visible = True;

EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function GetPropertyOnServer(Object, Property)

	Return Object[Property];

EndFunction

&AtClient
Function StringLatin(StringValue)
	
	StringUkRu = "абвгдеёж зиїйклмнопрстуфх ц ч ш щ   ъыьэю я ";
	StringLatn = "abvgdeezhziiyklmnoprstufkhtschshshch y eyuya";
	NewStringValue = "";

	For Count = 1 To StrLen(StringValue) Do
		StringValueSymbol = Mid(StringValue,Count,1);
		If StringValueSymbol = " " Then
			StringValueSymbol = "_";
		Else
			IsUpper = False;
			CharPosition = StrFind(StringUkRu,StringValueSymbol);	
			If CharPosition = 0 Then
				CharPosition = StrFind(StringUkRu,Lower(StringValueSymbol));
				IsUpper = True;
			EndIf;
			If NOT CharPosition = 0 Then
				For CountStringRu = 1 To StrLen(StringUkRu) - CharPosition + 1 Do
					If NOT Mid(StringUkRu,CharPosition + CountStringRu,1) = " " Then
						StringValueSymbol = Mid(StringLatn,CharPosition,CountStringRu);
						If StringValueSymbol = " " Then
							StringValueSymbol = "";
						ElsIf IsUpper Then
							StringValueSymbol = Upper(StringValueSymbol);	
						EndIf;
						Break;
					EndIf;						
				EndDo;
			EndIf;					
		EndIf;
		NewStringValue = NewStringValue + StringValueSymbol;
	EndDo;	
	
	Return NewStringValue;
	
EndFunction

&AtServer
Function UnloadToXMLAtServer()
	
	TempFileName = GetTempFileName();
	
	PackageForUnloading = New XMLWriter;
	PackageForUnloading.OpenFile(TempFileName);
	PackageForUnloading.WriteXMLDeclaration();
	
	PackageForUnloading.WriteStartElement("Catalogs");
	WriteXML(PackageForUnloading, Master.GetObject());
	
	If Level.Parent.IsEmpty() Then
		WriteXML(PackageForUnloading,"");
	Else
		WriteXML(PackageForUnloading, Level.Parent.GetObject());
	EndIf;
	
	WriteXML(PackageForUnloading, Level.GetObject());

	ArrayFileAuthor = GetSectionOnServer(True, True);
	CurrentPasswordEncryption = SharedModuleOnServer.GetCurrentPassword(Master, Catalogs.Levels.EmptyRef());
	FileStorageAuthor = GetAddressFile(ArrayFileAuthor,,CurrentPasswordEncryption);
	ArrayFile = GetSectionOnServer(True);
	FileStorage = GetAddressFile(ArrayFile);
	
	For Each ElementArrayFileAuthor In ArrayFileAuthor Do
		ArrayFile.Add(ElementArrayFileAuthor);
	EndDo;
	For Each ElementFileStorageAuthor In FileStorageAuthor Do
		FileStorage.Add(ElementFileStorageAuthor);
	EndDo;
	
	For Each ElementArrayFile In ArrayFile Do
		WriteXML(PackageForUnloading, ElementArrayFile.GetObject());
		For Each ElementFileStorage In FileStorage Do
			If ElementFileStorage.File = ElementArrayFile Then
				If ValueIsFilled(ElementFileStorage.Storage) Then
					WriteXML(PackageForUnloading, GetFromTempStorage(ElementFileStorage.Storage));
				Else
					WriteXML(PackageForUnloading,"");		
				EndIf;
				WriteXML(PackageForUnloading,GetFromTempStorage(ElementFileStorage.TextHTML));
				Break;	
			EndIf;	
		EndDo;
	EndDo;

	PackageForUnloading.WriteEndElement();
	PackageForUnloading.Close();
	
	TempStorage = PutToTempStorage(New BinaryData(TempFileName));
	DeleteFiles(TempFileName);
	
	Return TempStorage;
	
EndFunction

&AtServer
Procedure LoadXMLAtServer(XMLData, DisplayError = False)
	
	Try
	
		Counter = 0;
			
		MyXMLReader = New XMLReader;
		MyXMLReader.SetString(XMLData);
		MyXMLReader.Read();
		MyXMLReader.Read();
		
		NewMasterXML = ReadXML(MyXMLReader);
		If NotRefreshLevel Then
			NewMaster = Catalogs.Masters.FindByDescription(NewMasterXML.Description);
			If NewMaster.IsEmpty() Then
				NewMaster = Catalogs.Masters.CreateItem();
				NewMaster.Description = NewMasterXML.Description;
				NewMaster.Write();
				Message("Save master: "+NewMaster.Description);
			Else
				Message("Found master: "+NewMaster.Description);		
			EndIf;
		Else
			NewMaster = NewMasterXML;
			NewMaster.Write();
			Message("Save master: "+NewMaster.Description);
		EndIf;

		NewLevelParentXML = ReadXML(MyXMLReader);
		If NOT TypeOf(NewLevelParentXML) = Type("String") Then
			If NotRefreshLevel Then
				NewLevelParent = Catalogs.Levels.FindByDescription(NewLevelParentXML.Description);
				If NewLevelParent.IsEmpty() Then
					NewLevelParent = Catalogs.Levels.CreateFolder();
					NewLevelParent.Description = NewLevelParentXML.Description;
					NewLevelParent.Write();
					Message("Save level parent: "+NewLevelParent.Description);
				Else
					Message("Found level parent: "+NewLevelParent.Description);	
				EndIf;
			Else
				NewLevelParent = NewLevelParentXML;
				NewLevelParent.Write();
				Message("Save level parent: "+NewLevelParent.Description);
			EndIf;
		EndIf;
		
		NewLevelXML = ReadXML(MyXMLReader);
		If NotRefreshLevel Then
			NewLevel = Catalogs.Levels.CreateItem();
			NewLevel.Parent = NewLevelParent;	
			NewLevel.Description = NewLevelXML.Description;
		Else
			NewLevel = NewLevelXML;
		EndIf;
		NewLevel.Write();		
		Message("Save Level: "+NewLevel.Description);
		
		Message("Loading data objects ...");
		While True Do
			
			NewFileXML = ReadXML(MyXMLReader);
			If NotRefreshLevel 
				AND ValueIsFilled(NewFileXML.Section) Then
					NewFile = Catalogs.Files.CreateItem();	
					NewFile.Description = NewFileXML.Description;
					NewFile.Master = NewMaster.Ref;
					NewFile.Level = NewLevel.Ref;
					NewFile.Number = NewFileXML.Number;
					NewFile.MainFileCode = NewFileXML.MainFileCode;
					NewFile.StringHyperlink = NewFileXML.StringHyperlink;
					If ValueIsFilled(NewFileXML.MainFile) Then
						NewFile.MainFile = SharedModuleOnServer.FindMainFile(NewFileXML.MainFileCode);
					EndIf;
			Else	
				NewFile = NewFileXML;
			EndIf;
			NewFile.Write();
			
			Counter = Counter + 1;
			
			If MyXMLReader.Name = "Catalogs"
				AND MyXMLReader.NodeType = XMLNodeType.EndElement Then
					Break;
			EndIf;	
						
			FileStorage = ReadXML(MyXMLReader);
			If NOT TypeOf(FileStorage) = Type("String") Then
				FileStorage.Write();
				Continue;	
			EndIf;				

			NewTextHTML = ReadXML(MyXMLReader);
			
			RecordManager = InformationRegisters.FileStorage.CreateRecordManager();
			RecordManager.File = NewFile.Ref;
			
			If ValueIsFilled(FileStorage) Then
				RecordManager.Storage = New ValueStorage(FileStorage);	
			EndIf;
			
			RecordManager.TextHTML = NewTextHTML;
			RecordManager.Write(True);
				
			If MyXMLReader.Name = "Catalogs"
				AND MyXMLReader.NodeType = XMLNodeType.EndElement Then
					Break;
			EndIf;	
					
			If Counter >= 1000 Then
				Message("Loading limit of 1000 data objects!");
				Break;
			EndIf;		
		EndDo;
	
		MyXMLReader.Close();
		Message("Download "+Counter+" data objects!")
			
	Except
		Message("Read error XML data objects number: "+Counter);
		If DisplayError Then
			Message(ErrorDescription());	
		EndIf;
	EndTry;
	
EndProcedure

&AtClient
Procedure UploadPictureCompletion(Result, Address, SelectedFileName, AdditionalParameters) Export

	If NOT Result Then
		Return;
	EndIf;

	NewFile = CheckAddFile(Address, SelectedFileName);
	If NOT NewFile = Undefined Then
		
		CurrentStage = Undefined;
		LoadValuesCurrentSlaveFile(NewFile);
		ShowFacePicture();
		
		Modified = False;
		
	EndIf;

EndProcedure

&AtClient
Procedure LoadValuesCurrentSlaveFile(NewFile)

	Items.CurrentSlaveFile.ChoiceList.LoadValues(GetSectionOnServer(,, True));
	For Each ItemChoiceList In Items.CurrentSlaveFile.ChoiceList Do
		ItemChoiceList.Presentation = ItemChoiceList.Value;
	EndDo;	
	CurrentSlaveFile = NewFile;	
			
EndProcedure

&AtServer
Function CheckAddFile(Address, SelectedFileName)

	CurrentFileName = SelectedFileName;
	NumberSubstrings = StrFind(CurrentFileName, "\", SearchDirection.FromEnd);

	If NumberSubstrings = 0 Then
		Message("File upload error " + CurrentFileName);
		Return Undefined;
	EndIf;

	CurrentFileName = Right(CurrentFileName, StrLen(CurrentFileName) - NumberSubstrings);
	CurrentExt = Right(CurrentFileName,3);
	CurrentFileName = StrReplace(CurrentFileName, "." + CurrentExt, "");
	
	SharedModuleOnServer.SaveGetDialogueOpenFileFilter(CurrentExt);

	Return AddFileStorage(CurrentFileName, Address);

EndFunction

&AtServer
Function AddFileStorage(Description, AddressStorage = Undefined, TextHTMLStorage = Undefined)

	If ValueIsFilled(UpdateFile) Then
		NewFile = UpdateFile.GetObject();
	Else
			
		NewFile = Catalogs.Files.CreateItem();
		
		If ValueIsFilled(Description) Then
			NewFile.Description = Description;
		ElsIf ValueIsFilled(MainFile) Then
			NewFile.Description = MainFile.Description;
		Else
			NewFile.Description = "Udefined";
		EndIf;
		
		NewFile.Level = Level;
		NewFile.MainFile = MainFile;
		NewFile.Master = Master;
		NewFile.StringHyperlink = StringHyperlink;
	
		If NOT ValueIsFilled(MainFile) Then
			NewFile.Number = GetNewNumber();
		EndIf;
	
		NewFile.Write();
		If NOT ValueIsFilled(Description) Then
			NewFile.Description = NewFile.Description + " " + NewFile.Code;
			NewFile.Write();	
		EndIf;
		If NOT ValueIsFilled(MainFile) Then
			NewFile.MainFileCode = NewFile.Code;
			NewFile.Write();
		EndIf;
			
	EndIf;

	RecordManager = InformationRegisters.FileStorage.CreateRecordManager();
	RecordManager.File = NewFile.Ref;
	
	If NOT AddressStorage = Undefined Then
		TempStorage = GetFromTempStorage(AddressStorage);
		RecordManager.Storage = New ValueStorage(TempStorage);
	EndIf;
	If NOT TextHTMLStorage = Undefined Then
		TempStorage = GetFromTempStorage(TextHTMLStorage);
		RecordManager.TextHTML = TempStorage;
	EndIf;
	
	RecordManager.Write(True);

	Return NewFile.Ref;
	
EndFunction

&AtServer
Function GetNewNumber()

	Query = New Query;
	Query.Text =
	"SELECT
	|	Files.Number AS Number
	|FROM
	|	Catalog.Files AS Files
	|WHERE
	|	Files.Level = &Level
	|	AND Files.MainFile = Value(Catalog.Files.EmptyRef)
	|Order BY
	|	Files.Number DESC";

	Query.SetParameter("Level", Level);

	QueryResult = Query.Execute();

	Number = 1;

	SelectionDetailRecords = QueryResult.SELECT();
	If SelectionDetailRecords.Next() Then
		Number = SelectionDetailRecords.Number + 1;
	EndIf;

	Return Number;

EndFunction

&AtClient
Procedure ShowFacePicture()

	FrontPicture = "";
	
	If ValueIsFilled(CurrentSlaveFile) Then
		CurrentFileChange = CurrentSlaveFile;		
	Else	
		CurrentFileChange = CurrentFile;
	EndIf;
	
	If ValueIsFilled(CurrentFileChange) Then
		StringHyperlink = GetPropertyOnServer(CurrentFileChange, "StringHyperlink");
		//@skip-warning
		FrontPictureStructure = GetAddressFile(CurrentFileChange, False);
		FrontPicture = FrontPictureStructure.Storage;	
		TextHTML = GetFromTempStorage(FrontPictureStructure.TextHTML);
		CurrentPicture = CurrentFileChange;	
	EndIf;

	GroupDataVisible();

EndProcedure

&AtServer
Function GetAddressFile(FileQuery, Encrypt = True, CurrentPasswordEncryption = Undefined) Экспорт

	InfoBaseID = String(Constants.InfoBaseID.Get());
	ArrayStructure = New Array();

	Query = New Query;
	Query.Text =
	"SELECT
	|	FileStorage.File,
	|	FileStorage.Storage,
	|	FileStorage.TextHTML
	|FROM
	|	InformationRegister.FileStorage AS FileStorage
	|WHERE
	|	FileStorage.File IN (&File)";

	Query.SetParameter("File", FileQuery);

	QueryResult = Query.Execute();

	IsFileQueryArray = TypeOf(FileQuery) = Type("Array");
	
	SelectionDetailRecords = QueryResult.SELECT();
	While SelectionDetailRecords.Next() Do
		
		FileStorage = SelectionDetailRecords.Storage.Get();
		IsFileStorageString = TypeOf(FileStorage) = Type("String");
		TextHTMLString = SelectionDetailRecords.TextHTML;
		
		If IsFileQueryArray 
			AND NOT IsFileStorageString Then
				FileStorage = Base64String(FileStorage);
		EndIf;

		If CurrentPasswordEncryption = Undefined Then
			CurrentPasswordEncryption = CurrentPassword;	
		EndIf;

		If ValueIsFilled(CurrentPasswordEncryption) Then
			If ValueIsFilled(FileStorage) Then
				If (Encrypt AND NOT IsFileStorageString)
					OR (NOT Encrypt AND IsFileStorageString) Then
						LeftFileStorage = Left(FileStorage, StrLen(CurrentPasswordEncryption));
						CyrrentEncryptString = EncryptDecryptString(Encrypt, FileStorage, CurrentPasswordEncryption, StrLen(CurrentPasswordEncryption));
						FileStorage = StrReplace(FileStorage,LeftFileStorage, CyrrentEncryptString);
				EndIf;
			ElsIf ValueIsFilled(TextHTMLString) Then
				If Left(TextHTMLString, StrLen(TextHTMLString)) = InfoBaseID Then
					TextHTMLString = StrReplace(TextHTMLString,InfoBaseID, "");
					TextHTMLString = EncryptDecryptString(Encrypt, TextHTMLString, CurrentPasswordEncryption, StrLen(TextHTMLString));
				ElsIf IsFileQueryArray Then
					TextHTMLString = EncryptDecryptString(Encrypt, TextHTMLString, CurrentPasswordEncryption, StrLen(TextHTMLString));
				EndIf;
			EndIf;
		EndIf;
		
		If NOT ValueIsFilled(FileStorage) Then
			TempStorage = "";	
		ElsIf NOT IsFileQueryArray
			AND IsFileStorageString Then
				TempStorage = PutToTempStorage(Base64Value(FileStorage));
		Else	
			TempStorage = PutToTempStorage(FileStorage);
		EndIf; 
	
		TextHTMLStorage = PutToTempStorage(TextHTMLString);
		NewStructure = New Structure("File, Storage, TextHTML", SelectionDetailRecords.File, TempStorage, TextHTMLStorage);
		
		If NOT IsFileQueryArray Then
			Return NewStructure;
		EndIf;
		
		ArrayStructure.Add(NewStructure);
		
	EndDo;
	
	If ArrayStructure.Count() = 0 Then
		NewStructure = New Structure("File, Storage, TextHTML", FileQuery, "", PutToTempStorage(""));
		If IsFileQueryArray Then
			ArrayStructure.Add(NewStructure);	
		Else
			Return NewStructure;
		EndIf;
	EndIf;
	
	Return ArrayStructure;

EndFunction

&AtServer
Procedure SectionOnChangeOnServer()

	CurrentFile = Undefined;
	CurrentSlaveFile = Undefined;
	StringHyperlink = "";

	CurrentPassword = SharedModuleOnServer.GetCurrentPassword(Master, Level);
	
	ArrayFile = GetSectionOnServer();
	
	Items.CurrentFile.ChoiceList.LoadValues(ArrayFile);
	For Each ItemChoiceList In Items.CurrentFile.ChoiceList Do
		ItemChoiceList.Presentation = ItemChoiceList.Value;
	EndDo;

	If NOT Items.CurrentFile.ChoiceList.Count() = 0 Then
		
   		CurrentFile = Items.CurrentFile.ChoiceList[0].Value;
		CurrentPicture = CurrentFile;
		
	EndIf;	
	
	SharedModuleOnServer.SetSettings(Enums.GeneralSettings.CurrentLevel, Level);
	SharedModuleOnServer.SetSettings(Enums.GeneralSettings.CurrentMaster, Master);

EndProcedure

&AtServer
Function GetSectionOnServer(IgnoreCurrentStage = False, Authors = False, SlaveFile = False)

	Query = New Query;

	if IgnoreCurrentStage Then
		Query.Text =
		"SELECT
		|	Files.Ref As File
		|FROM
		|	Catalog.Files AS Files
		|WHERE
		|	Files.Master = &Master
		|	AND NOT Files.DeletionMark
		|	AND "+?(Authors,"Files.Level = Value(Catalog.Levels.EmptyRef)","Files.Level = &Level")+" 
		|ORDER BY
		|	Files.MainFile,
		|	Files.Number";

	ElsIf SlaveFile
		AND ValueIsFilled(CurrentFile) Then	
		
		Query.Text =
		"SELECT
		|	Files.Ref As File
		|FROM
		|	Catalog.Files AS Files
		|WHERE
		|	Files.Master = &Master
		|	AND Files.Level = &Level
		|	AND NOT Files.DeletionMark
		|	AND Files.MainFile = &MainFile
		|
		|ORDER BY
		|	Files.Code";
		Query.SetParameter("MainFile", CurrentFile);
		
	ElsIf ValueIsFilled(CurrentStage) Then
		Query.Text =
		"SELECT
		|	Education.File As File
		|FROM
		|	InformationRegister.Education As Education
		|WHERE
		|	Education.StageOfLearning = &StageOfLearning
		|	AND Education.File.Level = &Level
		|	AND Education.File.Master = &Master
		|	AND NOT Education.File.DeletionMark";
		Query.SetParameter("StageOfLearning", CurrentStage);
		
	Else
		Query.Text =
		"SELECT
		|	Files.Ref As File,
		|	Education.StageOfLearning As StageOfLearning
		|INTO General
		|FROM
		|	InformationRegister.Education As Education
		|		FULL JOIN Catalog.Files As Files
		|		ON Education.File = Files.Ref
		|WHERE
		|	Files.Level = &Level
		|	AND NOT Files.DeletionMark
		|	AND Files.Master = &Master
		|	AND Files.MainFile = Value(Catalog.Files.EmptyRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Education.File As File
		|FROM
		|	General As Education
		|WHERE
		|	Education.StageOfLearning IS NULL
		|
		|ORDER BY
		|	Education.File.Number";
		Items.CurrentFile.Title = "New";
	EndIf;

	If ValueIsFilled(SearchString) Then
		Query.Text = Query.Text + " AND Education.File.Description Like &Description";
		Query.SetParameter("Description", "%" + SearchString + "%");
	EndIf;

	Query.SetParameter("Level", Level);
	Query.SetParameter("Master", Master);
	
	Return Query.Execute().Unload().UnloadColumn("File");
	
EndFunction

&AtServer
Procedure AddServerLearningStage(StageLearning)

	RecordManager = InformationRegisters.Education.CreateRecordManager();
	RecordManager.File = CurrentFile;
	RecordManager.StageOfLearning = StageLearning;
	RecordManager.Write(True);

EndProcedure

&AtClient
Procedure FillCountsStages()

	Items.Today.Title = NStr("en = 'Today';ru = 'Сегодня'");
	Items.Tomorrow.Title = NStr("en = 'Tomorrow';ru = 'Завтра'");
	Items.Week.Title = NStr("en = 'Week';ru = 'Неделя'");
	Items.Month.Title = NStr("en = 'Month';ru = 'Месяц'");
	Items.Repeat.Title = NStr("en = 'Repeat';ru = 'Повторять'");

	CountsStages = GetCountsStages(Level, Master);
	For Each ElementCountsStages In CountsStages Do
		Items[ElementCountsStages.Title].Title = Items[ElementCountsStages.Title].Title + " (" + ElementCountsStages.StageOfLearningCount + ")";
	EndDo;
	
EndProcedure

&AtServerNoContext
Function GetCountsStages(Section, Author)
	
	CountsStages = New Array();
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	Education.StageOfLearning,
		|	COUNT(Education.StageOfLearning) AS StageOfLearningCount,
		|	Education.StageOfLearning.Order AS Order
		|FROM
		|	InformationRegister.Education AS Education
		|WHERE
		|	Education.File.Master = &Master
		|	AND Education.File.Level = &Level
		|GROUP BY
		|	Education.StageOfLearning,
		|	Education.StageOfLearning.Order";
	
	Query.SetParameter("Master", Author);
	Query.SetParameter("Level", Section);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	While SelectionDetailRecords.Next() Do
		NewStructure = New Structure("StageOfLearning, StageOfLearningCount,Title", 
			SelectionDetailRecords.StageOfLearning, 
			SelectionDetailRecords.StageOfLearningCount, 
			Metadata.Enums.LearningSteps.EnumValues[SelectionDetailRecords.Order].Name);
		CountsStages.Add(NewStructure);		
	EndDo;
	
	Return CountsStages;
	
EndFunction

&AtServer
Function GetMaxCodeCharacterStrings(CurrentString, Offset = 0)
	
	CurrentStringLen 	= StrLen(CurrentString);
	MaxCodeCharacter = 0;
	
	If NOT Offset = 0 Then
		CurrentStringLen = Offset;
	EndIf;
		
	For Counter = 1 To CurrentStringLen Do
		CodeCharacter = CharCode(CurrentString, Counter);
		If CharCode(CurrentString, Counter) > MaxCodeCharacter Then
			MaxCodeCharacter = CodeCharacter;
		EndIf;
	EndDo;
	
	Return MaxCodeCharacter;
		
EndFunction

&AtServer
Function GetCryptionKey(CurrentPassword, CurrentStringLen)
	
	CurrentPasswordLen 	= StrLen(CurrentPassword);
	MaxCodeCharacter = GetMaxCodeCharacterStrings(CurrentPassword);
	NumberToInitialize = MaxCodeCharacter + CurrentStringLen;
	CryptionKey	= "";
	
	MyRandomNumberGenerator = New RandomNumberGenerator(NumberToInitialize);
	
	CounterPassword = 1;
	
	For Counter = 1 To CurrentStringLen Do
		
		If CounterPassword > CurrentPasswordLen Then
			CounterPassword = 1;	
		EndIf;
		
		RandomNumberOffset = MyRandomNumberGenerator.RandomNumber(1, NumberToInitialize);
		CryptionKey = CryptionKey + Char(CharCode(Mid(CurrentPassword, CounterPassword, 1)) + RandomNumberOffset);
		CounterPassword = CounterPassword + 1;

	EndDo;
		
	Return CryptionKey;
		
EndFunction

&AtServer
Function EncryptDecryptString(Encrypt, CurrentString, CurrentPassword, Offset = 0)

	CurrentStringLen = StrLen(CurrentString);
	
	If NOT Offset = 0 Then
		CurrentStringLen = Offset;
	EndIf;
	
	CryptionKey = GetCryptionKey(CurrentPassword, CurrentStringLen);
	
	MaxCodeCharacter = GetMaxCodeCharacterStrings(CryptionKey, Offset);
	NumberToInitialize = MaxCodeCharacter + CurrentStringLen;
	CryptionStirng = "";
	
	MyRandomNumberGenerator = New RandomNumberGenerator(NumberToInitialize);
	
	For Counter = 1 To CurrentStringLen Do
		
		RandomNumberOffset = MyRandomNumberGenerator.RandomNumber(1, NumberToInitialize);
		
		CharCodeCurrentString 	= CharCode(CurrentString, Counter);
		CharCodeCryptionKey 	= CharCode(CryptionKey, Counter);		
		
		If Encrypt Then
			CryptionCharCode = (CharCodeCurrentString + CharCodeCryptionKey + RandomNumberOffset) % 65536;
		Else
			CryptionCharCode = (CharCodeCurrentString - CharCodeCryptionKey - RandomNumberOffset) % 65536;
			CryptionCharCode = ?(CryptionCharCode < 0, 65536 + CryptionCharCode, CryptionCharCode);		
		EndIf;
		
		CryptionStirng = CryptionStirng + Char(CryptionCharCode);		

	EndDo;
		
	Return CryptionStirng;
	
EndFunction

&AtServer
Procedure CurrentPasswordOnChangeAsServer(Master, Level, CurrentPassword)
	
	SharedModuleOnServer.SetCurrentPassword(Master, Level, CurrentPassword);	
	
EndProcedure

&AtServer
Procedure EnableHTMLEditModeAtServer()

	If StrFind(TextHTML, "<body contentEditable") = 0 
		AND StrFind(TextHTML, "<BODY contentEditable") = 0 Then
			If NOT StrFind(TextHTML, "<body") = 0 
				OR NOT StrFind(TextHTML, "<body") = 0 Then
					TextHTML = StrReplace(TextHTML, "<body", "<body contentEditable=true");
					TextHTML = StrReplace(TextHTML, "<<BODY", "<BODY contentEditable=true");
			Else
				TextHTML = StrReplace(TextHTML, "<html>", "<html><body contentEditable=true>");
				TextHTML = StrReplace(TextHTML, "</html>", "</body></html>");
				
				TextHTML = StrReplace(TextHTML, "<HTML>", "<HTML><BODY contentEditable=true>");
				TextHTML = StrReplace(TextHTML, "</HTML>", "</BODY></HTML>");
			EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure GroupDataVisible()
	
	Items.FrontPicture.Visible = ValueIsFilled(FrontPicture);
	Items.TextHTML.Visible = ValueIsFilled(TextHTML);
	Items.CommandsHTML.Visible = False;
	
	#If ThinClient Then
		
		If Items.GroupService.Visible 
			AND Items.TextHTML.Visible Then
				Items.CommandsHTML.Visible = True;
				EnableHTMLEditModeAtServer();	
		EndIf;
		
	#EndIf
	
EndProcedure

&AtClient
Procedure FinishChangeFont(Font, Parameters) Export
	
	If Font = Undefined Then
		Return;	
	EndIf;
	
	If NOT IsBlankString(Font.Name) Then
		
		HTMLDocument = Items.TextHTML.Document; 
		HTMLDocument.execCommand("fontName", False, Font.Name);
		Modified = True;
			
	EndIf;

	If Font.Size <> -1 Then
		
		FontSize = 1;
		If Font.Size <= 8 Then
			FontSize = 1;
		ElsIf Font.Size <= 10 Then
			FontSize = 2;	
		ElsIf Font.Size <= 12 Then
			FontSize = 3;	
		ElsIf Font.Size <= 14 Then
			FontSize = 4;	
		ElsIf Font.Size <= 16 Then
			FontSize = 5;	
		ElsIf Font.Size <= 18 Then
			FontSize = 6;	
		Else
			FontSize = 7	
		EndIf;	
			
	EndIf;	
	
	ExecuteHTMLCommand("fontSize", False, FontSize);
			
EndProcedure

&AtClient
Procedure ExecuteHTMLCommand(Parameters1, Parameters2 = Undefined, Parameters3 = Undefined)
	
	HTMLDocument = Items.TextHTML.Document; 
	
	If NOT Parameters3 = Undefined Then
		HTMLDocument.execCommand(Parameters1, Parameters2, Parameters3);
	ElsIf NOT Parameters2 = Undefined Then
		HTMLDocument.execCommand(Parameters1, Parameters2);		
	Else
		HTMLDocument.execCommand(Parameters1);		
	EndIf;
	
	Modified = True;
	
EndProcedure

#EndRegion


