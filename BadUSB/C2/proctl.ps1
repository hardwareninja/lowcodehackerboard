Set-Variable sleeptime -option Constant -value 60
Set-Variable pidtaskfd -option Constant -value 1
Set-Variable pidconnfd -option Constant -value 4

$cmdline = $args[0]
$proc = $args[1]
$search = $args[2]
$timeout = $args[3]

if ($args.count -lt 3) {
	exit
}

while ($true) {
	$action = $true
	$found = ""

	tasklist | Select-String $proc | ForEach-Object {
		$task = $_.line.split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)
		$found = $task[$pidtaskfd]
		netstat -ano | Select-String $search | ForEach-Object {
			$conn = $_.line.split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)
			if ($conn[$pidconnfd] -eq $found) {
				$action = $false
			}
		}
	}

	if ($action -and $cmdline) {
		if ($found) {taskkill /F /PID $found}
		$program = $cmdline.split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)[0]
		$param = $cmdline.split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)[1]
		if ($param) {
			Start-Process $program -ArgumentList $param
		} else {
			Start-Process $program
		}
	}

	if (-not($timeout)) {$timeout = $sleeptime}
	Start-Sleep -s $timeout
}
