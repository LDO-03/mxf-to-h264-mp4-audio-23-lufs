property scriptPath : ""
on open theFiles
	set sh to (POSIX path of (path to me)) & "Contents/Resources/mxf_conforme.sh"
	set n to count of theFiles
	set report to ""
	set progress total steps to n
	set progress description to "Conversione in corso…"
	repeat with i from 1 to n
		set f to POSIX path of (item i of theFiles)
		set progress completed steps to i - 1
		set progress additional description to "File " & i & " di " & n
		try
			set r to do shell script "/bin/bash " & quoted form of sh & " " & quoted form of f
			set report to report & r & return & return
		on error errMsg
			set report to report & "✗ " & errMsg & return & return
		end try
	end repeat
	display dialog report with title "MXF Conforme" buttons {"OK"} default button 1
end open
on run
	display dialog "Trascina uno o più file MXF sull'icona di questa app." with title "MXF Conforme" buttons {"OK"} default button 1
end run
