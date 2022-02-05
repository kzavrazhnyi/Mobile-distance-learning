

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;	
	EndIf;
	
	If ValueIsFilled(MainFile) Then
		MainFileCode = MainFile.Code;
	EndIf;
	
EndProcedure
