#function to read jvm argumets
function readJvmProps($propFilePath)  {
    $jvmArgs = "";
    if ([System.IO.File]::Exists($propFilePath)) {
        foreach($line in (Get-Content $propFilePath)){
        $line = $line.trim()
            if (!$line.StartsWith("#")) {
                $jvmArgs += " "
                $jvmArgs += $line
            }
        }
    } 
    return $jvmArgs
}
#function to run a program
function runCommand($arg0, $arg1) {
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $arg0
    $startInfo.Arguments = $arg1
    $startInfo.RedirectStandardOutput = $true
    $startInfo.UseShellExecute = $false
    #$startInfo.CreateNoWindow = $false

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    $process.Start() | Out-Null
    $result = $process.StandardOutput.ReadToEnd()
    $process.WaitForExit()
    return $result
}

# getWindowPIDByTitle
# Find a process's PID by its windows title
# input:
#   $wintitle   requried string with the full windows title name
# output:
#   $script:winpid The found window's PID or $null if not found
#
function getWindowPIDByTitle ( [string]$wintitle ) {
    $script:winpid=$null

    $_wind=$(Get-Process | Where-Object { $_.MainWindowTitle -like "${wintitle}" } )
    if ( $_wind -ne $null ) {
        $script:winpid=$_wind.id
    }
}


# Get environment attributes:
$dbg=""
$javahome=""
$tmpdir=""
$pasoepid=""
$pasoehome=""
$pasoebase=""
$beanInfo=""
$resultOnly=""
$queriesArg=""
$resultOnlyArg=""
$jacksoncore=""
$jacksondatabind=""
$jacksonannotations=""
$oejmx=""
$qResults=""
$queryFile=""
$queryJSON=""
$wintitle=""


$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
if ($dbg -ne "")  {
	write-output "scriptPath:  $scriptPath"
}

$tmppidfile = ls "${env:CATALINA_BASE}\logs\catalina-*.pid" -ErrorAction SilentlyContinue
#check if pid file exists
if ( $null -eq $tmppidfile ) {
    write-error "Error! Cannot find pid file $tmppidfile. Server must be running to execute oejmx script."
    exit 1
}

$javahome=$env:JAVA_HOME
$tmpdir="$env:CATALINA_BASE\temp"
$pasoehome=$env:CATALINA_HOME
$pasoebase=$env:CATALINA_BASE

$pasoepid, $wintitle = $(get-content $tmppidfile).split("|")

#check if server is running
if ( $pasoepid -ne "0" ) {
    $error.clear()
    $_tmp=get-process -id $pasoepid -erroraction:silentlycontinue
    if ( $_tmp -eq $null ) {
        write-error "Error! Cannot find process running with pid $pasoepid. Server must be running to execute oejmx script."
        exit 1
    }
} else {
    # using the window title see if the process exists
    getWindowPIDByTitle "$wintitle"
    if ( $winpid -ne $null ) {
        $pasoepid=$script:winpid
    } else {
        write-error "Error! Cannot find process running with title $wintitle. Server must be running to execute oejmx script."
        exit 1
    }
}

if ($dbg -ne "")  {
    write-output "javahome: $javahome" "tmpdir: $tmpdir" "pasoepid: $pasoepid" "pasoehome: $pasoehome" "pasoebase: $pasoebase"
}

#check if server is running using lifecycle file
$lifecycle="$tmpdir\*.lifecycle";
if ( !(test-path $lifecycle)) {
    write-error "Error! Cannot find lifecycle file in $tmpdir. Server must be running to execute oejmx script."
    exit 1
}

#Get Arguments
if ($dbg -ne "")  {
    write-output "arguments: $args"
}

$qResults=$tmpdir
$queriesArg=""
$parg=""
$arg=""
$known=""

$argNum = 0;
while ($argNum -lt $args.length)
{
  $key = $args[$argNum]
  if($key -eq "-R") {
	$resultOnlyArg = "-R"
    $arg = $key
    $known = "1"
  }
  if($key -eq "-C") {
	$beanInfo = "-C"
    $arg = $key
    $known = "1"
  }
  if($key -eq "-Q") {
    $arg = $key
    $known = "1"
  }
  if($key -eq "-O") {
    $arg = $key
    $known = "1"
    $qResults = "@"
  }
  if($arg -eq "") {
    if ($parg -eq "-O") {
        $qResults = $key
        $known="1"
    }
    if ($parg -eq "-Q") {
        $queriesArg = $key
        $known="1"
    }
  }
  if ($known -eq "" ) {
     write-error "Unknown parameter: $key"
     exit 1
  }
  $parg=$arg
  $arg=""
  $known=""
  $argNum++;  
}

if ($dbg -ne "")  {
    write-output "resultOnlyArg: $resultOnlyArg" "beanInfo: $beanInfo" "queriesArg: $queriesArg" "qResults: $qResults"
}



	
#Find and check jars
$commonLib = "$pasoehome\common\lib"
$jacksonjars = "$commonLib\jackson*.jar"

$jacksonCoreNoVersion = "jackson-core-"
$jacksonDatabindNoVersion = "jackson-databind-"
$jacksonAnnotationsNoVersion="jackson-annotations-"
 

[string]$jacksonjarsArr = gci  $jacksonjars -name

if($jacksonjarsArr -ne "" -and $jacksonjarsArr -ne $null) { 
	$jacksonjarsArr.split(" ") | foreach {
	   $nn = $_
	   $re = $nn -replace "[0-9\.]*\.jar" 
	   if ($re -eq $jacksonCoreNoVersion) {
		  $jacksoncore = "$commonLib\$nn"
	   } else {if ($re -eq $jacksonDatabindNoVersion) {
		  $jacksondatabind = "$commonLib\$nn"
	   } else {if ($re -eq $jacksonAnnotationsNoVersion) {
		  $jacksonannotations = "$commonLib\$nn"
	   }}}
	}
}

if($jacksoncore -eq "") {
   write-error "Error! Cannot find  $jacksonCoreNoVersion*.jar"
   exit 1
}
if($jacksondatabind -eq "") {
   write-error "Error! Cannot find  $jacksonDatabindNoVersion*.jar"
   exit 1
}
if($jacksonannotations -eq "") {
   write-error "Error! Cannot find  $jacksonAnnotationsNoVersion*.jar"
   exit 1
}

$binDir = "$pasoehome\bin"
$oejmxjar =  "$binDir\oejmx*jar"

$oejmxNoVersion = "oejmx"
[string]$oejmxjarArr = gci $oejmxjar -name

if($oejmxjarArr -ne $null -and $oejmxjarArr -ne "") { 
	$oejmxjarArr.split(" ") | foreach {	   
	   $dd = $_
	   $re = $dd -replace "-[0-9\.]*\.jar" 
	   if ($re -eq $oejmxNoVersion) {
		  $oejmx = "$binDir\$dd"
	   }
	}
}
if($oejmx -eq "") {
   write-error "Error! Cannot find  $binDir\$oejmxNoVersion*.jar"
   exit 1
}
# Set and check queries file if not -C
if($beanInfo -eq "") {
	if($queriesArg -eq "") {
		$queryFile = "$scriptPath\jmxqueries\default.qry"
	} else {
        if($queriesArg.Substring(0,1) -eq  "{") {
            $queryJSON =  $queriesArg   
        } else {       
            $queryFile = $queriesArg
        }
	}
	if( $queryFile -ne "" -and ![System.IO.File]::Exists("$queryFile")){
		 write-error "Error! Cannot find query file  ""$queries"""
		 exit 1 
	}
	$resultOnly=$resultOnlyArg
}

# Compose java command  
$pasoeJmxCall = "$javahome\bin\java.exe" 
$pasoeJmxCallCp = "-cp ""$jacksoncore"";""$jacksondatabind"";""$jacksonannotations"";""$oejmx"""
$jvmArgs = readJvmProps "$pasoebase\conf\localJvm.properties"

if ($dbg -ne "")  {
	write-output "Command: $pasoeJmxCall $jvmArgs -cp ""$oejmx"";""$jacksondatabind"";""$jacksonannotations"";""$jacksoncore""  $pasoeJmxCallClass $pasoepid $queryFile $qResults $resultOnly $beanInfo"
}
# Run jmx request
if ($queryJSON -ne "") {
    $pasoeJmxCallClass = "com.progress.appserv.util.jmx.JmxQuery"     
    $queryJSON = $queryJSON.Replace('"','"""')
    $queryJSON = $queryJSON.Replace('\"""','\\"""')     
    $arguments = "$jvmArgs -cp ""$oejmx"";""$jacksondatabind"";""$jacksonannotations"";""$jacksoncore"" $pasoeJmxCallClass $pasoepid $queryJSON"
    #$result = & $pasoeJmxCall  -cp """$oejmx"";""$jacksondatabind"";""$jacksonannotations"";""$jacksoncore""" $pasoeJmxCallClass $pasoepid $queryJSON 2>&1 | Out-String
    $result = runCommand $pasoeJmxCall $arguments
    write-output $result
} else {
    $pasoeJmxCallClass = "com.progress.appserv.util.jmx.PASOEWatch" 
    $arguments = "$jvmArgs -cp ""$oejmx"";""$jacksondatabind"";""$jacksonannotations"";""$jacksoncore"" $pasoeJmxCallClass $pasoepid $queryFile $qResults $resultOnly $beanInfo"
    runCommand $pasoeJmxCall $arguments
    
  

}
# SIG # Begin signature block
# MIIwIAYJKoZIhvcNAQcCoIIwETCCMA0CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD6RMEEoOZ7hG55
# klgZk9bIkUoen9XzKi1fXKDE/A15f6CCFAswggVyMIIDWqADAgECAhB2U/6sdUZI
# k/Xl10pIOk74MA0GCSqGSIb3DQEBDAUAMFMxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMSkwJwYDVQQDEyBHbG9iYWxTaWduIENvZGUgU2ln
# bmluZyBSb290IFI0NTAeFw0yMDAzMTgwMDAwMDBaFw00NTAzMTgwMDAwMDBaMFMx
# CzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMSkwJwYDVQQD
# EyBHbG9iYWxTaWduIENvZGUgU2lnbmluZyBSb290IFI0NTCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBALYtxTDdeuirkD0DcrA6S5kWYbLl/6VnHTcc5X7s
# k4OqhPWjQ5uYRYq4Y1ddmwCIBCXp+GiSS4LYS8lKA/Oof2qPimEnvaFE0P31PyLC
# o0+RjbMFsiiCkV37WYgFC5cGwpj4LKczJO5QOkHM8KCwex1N0qhYOJbp3/kbkbuL
# ECzSx0Mdogl0oYCve+YzCgxZa4689Ktal3t/rlX7hPCA/oRM1+K6vcR1oW+9YRB0
# RLKYB+J0q/9o3GwmPukf5eAEh60w0wyNA3xVuBZwXCR4ICXrZ2eIq7pONJhrcBHe
# OMrUvqHAnOHfHgIB2DvhZ0OEts/8dLcvhKO/ugk3PWdssUVcGWGrQYP1rB3rdw1G
# R3POv72Vle2dK4gQ/vpY6KdX4bPPqFrpByWbEsSegHI9k9yMlN87ROYmgPzSwwPw
# jAzSRdYu54+YnuYE7kJuZ35CFnFi5wT5YMZkobacgSFOK8ZtaJSGxpl0c2cxepHy
# 1Ix5bnymu35Gb03FhRIrz5oiRAiohTfOB2FXBhcSJMDEMXOhmDVXR34QOkXZLaRR
# kJipoAc3xGUaqhxrFnf3p5fsPxkwmW8x++pAsufSxPrJ0PBQdnRZ+o1tFzK++Ol+
# A/Tnh3Wa1EqRLIUDEwIrQoDyiWo2z8hMoM6e+MuNrRan097VmxinxpI68YJj8S4O
# JGTfAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0G
# A1UdDgQWBBQfAL9GgAr8eDm3pbRD2VZQu86WOzANBgkqhkiG9w0BAQwFAAOCAgEA
# Xiu6dJc0RF92SChAhJPuAW7pobPWgCXme+S8CZE9D/x2rdfUMCC7j2DQkdYc8pzv
# eBorlDICwSSWUlIC0PPR/PKbOW6Z4R+OQ0F9mh5byV2ahPwm5ofzdHImraQb2T07
# alKgPAkeLx57szO0Rcf3rLGvk2Ctdq64shV464Nq6//bRqsk5e4C+pAfWcAvXda3
# XaRcELdyU/hBTsz6eBolSsr+hWJDYcO0N6qB0vTWOg+9jVl+MEfeK2vnIVAzX9Rn
# m9S4Z588J5kD/4VDjnMSyiDN6GHVsWbcF9Y5bQ/bzyM3oYKJThxrP9agzaoHnT5C
# JqrXDO76R78aUn7RdYHTyYpiF21PiKAhoCY+r23ZYjAf6Zgorm6N1Y5McmaTgI0q
# 41XHYGeQQlZcIlEPs9xOOe5N3dkdeBBUO27Ql28DtR6yI3PGErKaZND8lYUkqP/f
# obDckUCu3wkzq7ndkrfxzJF0O2nrZ5cbkL/nx6BvcbtXv7ePWu16QGoWzYCELS/h
# AtQklEOzFfwMKxv9cW/8y7x1Fzpeg9LJsy8b1ZyNf1T+fn7kVqOHp53hWVKUQY9t
# W76GlZr/GnbdQNJRSnC0HzNjI3c/7CceWeQIh+00gkoPP/6gHcH1Z3NFhnj0qinp
# J4fGGdvGExTDOUmHTaCX4GUT9Z13Vunas1jHOvLAzYIwggboMIIE0KADAgECAhB3
# vQ4Ft1kLth1HYVMeP3XtMA0GCSqGSIb3DQEBCwUAMFMxCzAJBgNVBAYTAkJFMRkw
# FwYDVQQKExBHbG9iYWxTaWduIG52LXNhMSkwJwYDVQQDEyBHbG9iYWxTaWduIENv
# ZGUgU2lnbmluZyBSb290IFI0NTAeFw0yMDA3MjgwMDAwMDBaFw0zMDA3MjgwMDAw
# MDBaMFwxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMTIw
# MAYDVQQDEylHbG9iYWxTaWduIEdDQyBSNDUgRVYgQ29kZVNpZ25pbmcgQ0EgMjAy
# MDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMsg75ceuQEyQ6BbqYoj
# /SBerjgSi8os1P9B2BpV1BlTt/2jF+d6OVzA984Ro/ml7QH6tbqT76+T3PjisxlM
# g7BKRFAEeIQQaqTWlpCOgfh8qy+1o1cz0lh7lA5tD6WRJiqzg09ysYp7ZJLQ8LRV
# X5YLEeWatSyyEc8lG31RK5gfSaNf+BOeNbgDAtqkEy+FSu/EL3AOwdTMMxLsvUCV
# 0xHK5s2zBZzIU+tS13hMUQGSgt4T8weOdLqEgJ/SpBUO6K/r94n233Hw0b6nskEz
# IHXMsdXtHQcZxOsmd/KrbReTSam35sOQnMa47MzJe5pexcUkk2NvfhCLYc+YVaMk
# oog28vmfvpMusgafJsAMAVYS4bKKnw4e3JiLLs/a4ok0ph8moKiueG3soYgVPMLq
# 7rfYrWGlr3A2onmO3A1zwPHkLKuU7FgGOTZI1jta6CLOdA6vLPEV2tG0leis1Ult
# 5a/dm2tjIF2OfjuyQ9hiOpTlzbSYszcZJBJyc6sEsAnchebUIgTvQCodLm3HadNu
# twFsDeCXpxbmJouI9wNEhl9iZ0y1pzeoVdwDNoxuz202JvEOj7A9ccDhMqeC5LYy
# AjIwfLWTyCH9PIjmaWP47nXJi8Kr77o6/elev7YR8b7wPcoyPm593g9+m5XEEofn
# GrhO7izB36Fl6CSDySrC/blTAgMBAAGjggGtMIIBqTAOBgNVHQ8BAf8EBAMCAYYw
# EwYDVR0lBAwwCgYIKwYBBQUHAwMwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4E
# FgQUJZ3Q/FkJhmPF7POxEztXHAOSNhEwHwYDVR0jBBgwFoAUHwC/RoAK/Hg5t6W0
# Q9lWULvOljswgZMGCCsGAQUFBwEBBIGGMIGDMDkGCCsGAQUFBzABhi1odHRwOi8v
# b2NzcC5nbG9iYWxzaWduLmNvbS9jb2Rlc2lnbmluZ3Jvb3RyNDUwRgYIKwYBBQUH
# MAKGOmh0dHA6Ly9zZWN1cmUuZ2xvYmFsc2lnbi5jb20vY2FjZXJ0L2NvZGVzaWdu
# aW5ncm9vdHI0NS5jcnQwQQYDVR0fBDowODA2oDSgMoYwaHR0cDovL2NybC5nbG9i
# YWxzaWduLmNvbS9jb2Rlc2lnbmluZ3Jvb3RyNDUuY3JsMFUGA1UdIAROMEwwQQYJ
# KwYBBAGgMgECMDQwMgYIKwYBBQUHAgEWJmh0dHBzOi8vd3d3Lmdsb2JhbHNpZ24u
# Y29tL3JlcG9zaXRvcnkvMAcGBWeBDAEDMA0GCSqGSIb3DQEBCwUAA4ICAQAldaAJ
# yTm6t6E5iS8Yn6vW6x1L6JR8DQdomxyd73G2F2prAk+zP4ZFh8xlm0zjWAYCImbV
# YQLFY4/UovG2XiULd5bpzXFAM4gp7O7zom28TbU+BkvJczPKCBQtPUzosLp1pnQt
# pFg6bBNJ+KUVChSWhbFqaDQlQq+WVvQQ+iR98StywRbha+vmqZjHPlr00Bid/XSX
# hndGKj0jfShziq7vKxuav2xTpxSePIdxwF6OyPvTKpIz6ldNXgdeysEYrIEtGiH6
# bs+XYXvfcXo6ymP31TBENzL+u0OF3Lr8psozGSt3bdvLBfB+X3Uuora/Nao2Y8nO
# ZNm9/Lws80lWAMgSK8YnuzevV+/Ezx4pxPTiLc4qYc9X7fUKQOL1GNYe6ZAvytOH
# X5OKSBoRHeU3hZ8uZmKaXoFOlaxVV0PcU4slfjxhD4oLuvU/pteO9wRWXiG7n9dq
# cYC/lt5yA9jYIivzJxZPOOhRQAyuku++PX33gMZMNleElaeEFUgwDlInCI2Oor0i
# xxnJpsoOqHo222q6YV8RJJWk4o5o7hmpSZle0LQ0vdb5QMcQlzFSOTUpEYck08T7
# qWPLd0jV+mL8JOAEek7Q5G7ezp44UCb0IXFl1wkl1MkHAHq4x/N36MXU4lXQ0x72
# f1LiSY25EXIMiEQmM2YBRN/kMw4h3mKJSAfa9TCCB6UwggWNoAMCAQICDAlVfkW9
# x62ANl5SfzANBgkqhkiG9w0BAQsFADBcMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQ
# R2xvYmFsU2lnbiBudi1zYTEyMDAGA1UEAxMpR2xvYmFsU2lnbiBHQ0MgUjQ1IEVW
# IENvZGVTaWduaW5nIENBIDIwMjAwHhcNMjMxMDI3MTQ0NTA0WhcNMjQxMDI3MTQ0
# NTA0WjCCAQkxHTAbBgNVBA8MFFByaXZhdGUgT3JnYW5pemF0aW9uMRAwDgYDVQQF
# Ewc1NzQzNTgyMRMwEQYLKwYBBAGCNzwCAQMTAlVTMRkwFwYLKwYBBAGCNzwCAQIT
# CERlbGF3YXJlMQswCQYDVQQGEwJVUzEWMBQGA1UECBMNTWFzc2FjaHVzZXR0czET
# MBEGA1UEBxMKQnVybGluZ3RvbjEcMBoGA1UECRMTMTUgV2F5c2lkZSBSZCBTdGUg
# NDEmMCQGA1UEChMdUHJvZ3Jlc3MgU29mdHdhcmUgQ29ycG9yYXRpb24xJjAkBgNV
# BAMTHVByb2dyZXNzIFNvZnR3YXJlIENvcnBvcmF0aW9uMIICIjANBgkqhkiG9w0B
# AQEFAAOCAg8AMIICCgKCAgEAti//DwNMRD5jZiIBY2iSzvG4R8lBIJv/wB/ZSZQR
# VCCdpGP3/yIivfTv0r0ETxfp7chg8v0Dfy9R+XzK/iy151/CvMKoRTSnc1isAoet
# 4KGQvKoLUZyEItguTTinQtGPVvVUzRPiLuirYcoCA+IFr/NzYhb8gW16emLttgUr
# a+fYPgDXJJf30/MsT52OFFcOhQgOPonUD5FMAqIqLzTUkLRQ2eVZ+sXMNm3GjcrG
# RyeilBeZHYNPip6b/Aql/FvwjFFTZglyMmBPbIzuQs/CcMNJuYqYfwY5Eu2sQaS8
# kbCvzPmYwN+Q0k++zQEBjF+V+PZeohCuAg0Hx+1SSDa3v9yp8lNWcggAb84d3LyT
# brNdNqG3EL9ZYRidFCWBe+/gPVf5uqDG1gLheLvBIvDCNb/8FqoKmwvePYItFMjF
# /sjsOSmDVIdadSMzMuUV2+mNGaD7p1oxdX5wjjhl1j9foYFSGf4Q+Tev1w12p2nT
# EUp5WHPg8ssAnDXZU1OWgjKtPJRWE1T9+kQ6rsPSEosrlKYal1OByTetbXgWO+ug
# JtpSdUmZJYfr4x02ISrBNXiiSv5knkugW/DOWYsfEK89nO7/buboCAOawTCKR4L+
# AM/T/C6rlU8qgNMbOR8bqb9lNexUihiSJgr1Qv5L5onDFam4+6KBHm1l8GGvbOFE
# 46MCAwEAAaOCAbYwggGyMA4GA1UdDwEB/wQEAwIHgDCBnwYIKwYBBQUHAQEEgZIw
# gY8wTAYIKwYBBQUHMAKGQGh0dHA6Ly9zZWN1cmUuZ2xvYmFsc2lnbi5jb20vY2Fj
# ZXJ0L2dzZ2NjcjQ1ZXZjb2Rlc2lnbmNhMjAyMC5jcnQwPwYIKwYBBQUHMAGGM2h0
# dHA6Ly9vY3NwLmdsb2JhbHNpZ24uY29tL2dzZ2NjcjQ1ZXZjb2Rlc2lnbmNhMjAy
# MDBVBgNVHSAETjBMMEEGCSsGAQQBoDIBAjA0MDIGCCsGAQUFBwIBFiZodHRwczov
# L3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5LzAHBgVngQwBAzAJBgNVHRME
# AjAAMEcGA1UdHwRAMD4wPKA6oDiGNmh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5jb20v
# Z3NnY2NyNDVldmNvZGVzaWduY2EyMDIwLmNybDATBgNVHSUEDDAKBggrBgEFBQcD
# AzAfBgNVHSMEGDAWgBQlndD8WQmGY8Xs87ETO1ccA5I2ETAdBgNVHQ4EFgQU7p0c
# BhDts35gdtky7W7Q98ahMdMwDQYJKoZIhvcNAQELBQADggIBAFhaPMCi/R/Waf0/
# th1H3b4pDSyZrd+kVwuejUBjVxyKOWLk9/7BG3mQHbo4WKxrorS57I4VZCWHWvZb
# iM3N4NzoB18WwCcSz9US9uU9LG2rP96tRPJkSU506p9dm3BKar6fqVFhIXnV39Ya
# JeKtmSVuzLxzUXQsfFUBkIoSdhfXHWsZ4yds9JLnK5JRJhS2IiiKpyBPdMvQruzd
# iYLIvLlmyr64yrpAPL+P1BsYhYobtuAsikatNQ/qV42td5bfifPOayZd+yjBK+Xa
# 4MF29YVfQp5MdIxHaKtpmj9BkbQR4068E3ks7HaDJvY4rdMBmx6isb0ZAXg8QFC1
# 73F5z116oSW9VjnSatJMlIF0kz3yKoZCyvqe5hAm3kCKNdbHXKn0NLO2rr3YAQ+0
# HAdSYe/YmAi/wNMyYZJ4KqSvoNbQFOc0cPmo16PlaoZei8VVZ8alGtv63T7VLHP+
# QUUkUDj89riHFFxhh6nwqLZ+lcPI5CqkhvjaJl+2hUQGIFKfPrnHhrokj6vih9y/
# DQGSHvzX+7x5+GNJ19ZnBYkic+E1oqJdFQklvdtzvbe2JC/OKSovMIGdMyPKiKy4
# BYGurmTMTCevRFH8XqQhhbjbfSkOkH65kxxMg98NqYmOn6HZgDRNU+b9Qy5C8giu
# 0dbH+yz3rM8uf8q7SIbR4iPpCe9OMYIbazCCG2cCAQEwbDBcMQswCQYDVQQGEwJC
# RTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEyMDAGA1UEAxMpR2xvYmFsU2ln
# biBHQ0MgUjQ1IEVWIENvZGVTaWduaW5nIENBIDIwMjACDAlVfkW9x62ANl5SfzAN
# BglghkgBZQMEAgEFAKCBvDAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg2L0ZTQzT
# 37jV3IL66ey1pYc61z0SBMl0hf7JGklb5iIwUAYKKwYBBAGCNwIBDDFCMECgJIAi
# AFAAcgBvAGcAcgBlAHMAcwAgAFMAbwBmAHQAdwBhAHIAZaEYgBZodHRwczovL3By
# b2dyZXNzLmNvbS8gMA0GCSqGSIb3DQEBAQUABIICAHamJU4chIkiV87A522/VwOd
# 1qhQjuZ9ujTK/2nhL+Wd6c6ve9qKRV25tKlFq1fRqIOkBCowBei3nxveGFFVYBAe
# YFklg7rKzlyh6REpGmMsYoLhXJ0E88tYP1SM+IYDanCQwS7zC6XR4rHPma+bSUlg
# 5HWTxNpRCiCpj40jYSiP7ahFRUzMv2iVSGqwwcpLpukEUJBAFnzJkgZNRsDOkDdP
# 76l1xRpGA43t9zsQIo5xqaK9KsXiKgyv48cnNbDbiUQAwDWS/zv41WtvBzqeTgKl
# upWJLFfnVMh+cxOkXLiVk2p5UJ283Fu81yHufvnBQxtr78eHxCWznsCdguUDZ310
# 8ZKiG09WlpYcd8MyRvQfvvsf4EktqLe5Khpii0FULEUXinACLIGWcsBshR6qJk5V
# qOuRB40yrgCW0mCSGHP1OV0FX6VFUqNVy3WSYSYoW7GJUyJWpmmBTqnipvVUqoSp
# vwCVDHUK5fFo5zaHP15hpZPryVLUztc4n5jCX2Q+fSkSXEXVQZD/6tF9LXdJRTJ8
# Salb9EKByBVFqH72qtDqEuLucWQECYHylJeInYKipcbW6hIJcvaaGAzQocUeYCRV
# Mu4+ZxXr5c5Fd/0TlvI6cBGIruQyOOOf4O/LfmgfKJxrd5u8AD5hINam9S5ZOfA3
# Kp6UocAm2yrGqUoi1bKioYIYETCCGA0GCisGAQQBgjcDAwExghf9MIIX+QYJKoZI
# hvcNAQcCoIIX6jCCF+YCAQMxDzANBglghkgBZQMEAgEFADCCAWIGCyqGSIb3DQEJ
# EAEEoIIBUQSCAU0wggFJAgEBBgorBgEEAYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAE
# IBC1zrNayl9zF+ErhXUHnC/Qzhh6Qowyf5vBDyl6xesXAgZmw0/9XC4YEzIwMjQw
# ODIzMTQyODIyLjkyNFowBIACAfSggeGkgd4wgdsxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9w
# ZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo3RDAwLTA1RTAtRDk0
# NzE1MDMGA1UEAxMsTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZSBTdGFtcGluZyBB
# dXRob3JpdHmggg8hMIIHgjCCBWqgAwIBAgITMwAAAAXlzw//Zi7JhwAAAAAABTAN
# BgkqhkiG9w0BAQwFADB3MQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMUgwRgYDVQQDEz9NaWNyb3NvZnQgSWRlbnRpdHkgVmVyaWZp
# Y2F0aW9uIFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMjAwHhcNMjAxMTE5
# MjAzMjMxWhcNMzUxMTE5MjA0MjMxWjBhMQswCQYDVQQGEwJVUzEeMBwGA1UEChMV
# TWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUHVibGlj
# IFJTQSBUaW1lc3RhbXBpbmcgQ0EgMjAyMDCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAJ5851Jj/eDFnwV9Y7UGIqMcHtfnlzPREwW9ZUZHd5HBXXBvf7Kr
# Q5cMSqFSHGqg2/qJhYqOQxwuEQXG8kB41wsDJP5d0zmLYKAY8Zxv3lYkuLDsfMuI
# EqvGYOPURAH+Ybl4SJEESnt0MbPEoKdNihwM5xGv0rGofJ1qOYSTNcc55EbBT7uq
# 3wx3mXhtVmtcCEr5ZKTkKKE1CxZvNPWdGWJUPC6e4uRfWHIhZcgCsJ+sozf5EeH5
# KrlFnxpjKKTavwfFP6XaGZGWUG8TZaiTogRoAlqcevbiqioUz1Yt4FRK53P6ovnU
# fANjIgM9JDdJ4e0qiDRm5sOTiEQtBLGd9Vhd1MadxoGcHrRCsS5rO9yhv2fjJHrm
# lQ0EIXmp4DhDBieKUGR+eZ4CNE3ctW4uvSDQVeSp9h1SaPV8UWEfyTxgGjOsRpee
# xIveR1MPTVf7gt8hY64XNPO6iyUGsEgt8c2PxF87E+CO7A28TpjNq5eLiiunhKbq
# 0XbjkNoU5JhtYUrlmAbpxRjb9tSreDdtACpm3rkpxp7AQndnI0Shu/fk1/rE3oWs
# DqMX3jjv40e8KN5YsJBnczyWB4JyeeFMW3JBfdeAKhzohFe8U5w9WuvcP1E8cIxL
# oKSDzCCBOu0hWdjzKNu8Y5SwB1lt5dQhABYyzR3dxEO/T1K/BVF3rV69AgMBAAGj
# ggIbMIICFzAOBgNVHQ8BAf8EBAMCAYYwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0O
# BBYEFGtpKDo1L0hjQM972K9J6T7ZPdshMFQGA1UdIARNMEswSQYEVR0gADBBMD8G
# CCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3Mv
# UmVwb3NpdG9yeS5odG0wEwYDVR0lBAwwCgYIKwYBBQUHAwgwGQYJKwYBBAGCNxQC
# BAweCgBTAHUAYgBDAEEwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTIftJq
# hSobyhmYBAcnz1AQT2ioojCBhAYDVR0fBH0wezB5oHegdYZzaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSWRlbnRpdHklMjBW
# ZXJpZmljYXRpb24lMjBSb290JTIwQ2VydGlmaWNhdGUlMjBBdXRob3JpdHklMjAy
# MDIwLmNybDCBlAYIKwYBBQUHAQEEgYcwgYQwgYEGCCsGAQUFBzAChnVodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElkZW50
# aXR5JTIwVmVyaWZpY2F0aW9uJTIwUm9vdCUyMENlcnRpZmljYXRlJTIwQXV0aG9y
# aXR5JTIwMjAyMC5jcnQwDQYJKoZIhvcNAQEMBQADggIBAF+Idsd+bbVaFXXnTHho
# +k7h2ESZJRWluLE0Oa/pO+4ge/XEizXvhs0Y7+KVYyb4nHlugBesnFqBGEdC2IWm
# tKMyS1OWIviwpnK3aL5JedwzbeBF7POyg6IGG/XhhJ3UqWeWTO+Czb1c2NP5zyEh
# 89F72u9UIw+IfvM9lzDmc2O2END7MPnrcjWdQnrLn1Ntday7JSyrDvBdmgbNnCKN
# ZPmhzoa8PccOiQljjTW6GePe5sGFuRHzdFt8y+bN2neF7Zu8hTO1I64XNGqst8S+
# w+RUdie8fXC1jKu3m9KGIqF4aldrYBamyh3g4nJPj/LR2CBaLyD+2BuGZCVmoNR/
# dSpRCxlot0i79dKOChmoONqbMI8m04uLaEHAv4qwKHQ1vBzbV/nG89LDKbRSSvij
# mwJwxRxLLpMQ/u4xXxFfR4f/gksSkbJp7oqLwliDm/h+w0aJ/U5ccnYhYb7vPKNM
# N+SZDWycU5ODIRfyoGl59BsXR/HpRGtiJquOYGmvA/pk5vC1lcnbeMrcWD/26oze
# PQ/TWfNXKBOmkFpvPE8CH+EeGGWzqTCjdAsno2jzTeNSxlx3glDGJgcdz5D/AAxw
# 9Sdgq/+rY7jjgs7X6fqPTXPmaCAJKVHAP19oEjJIBwD1LyHbaEgBxFCogYSOiUIr
# 0Xqcr1nJfiWG2GwYe6ZoAF1bMIIHlzCCBX+gAwIBAgITMwAAADUJBbWy54TvDAAA
# AAAANTANBgkqhkiG9w0BAQwFADBhMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUHVibGljIFJT
# QSBUaW1lc3RhbXBpbmcgQ0EgMjAyMDAeFw0yNDAyMTUyMDM1NTJaFw0yNTAyMTUy
# MDM1NTJaMIHbMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUw
# IwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5u
# U2hpZWxkIFRTUyBFU046N0QwMC0wNUUwLUQ5NDcxNTAzBgNVBAMTLE1pY3Jvc29m
# dCBQdWJsaWMgUlNBIFRpbWUgU3RhbXBpbmcgQXV0aG9yaXR5MIICIjANBgkqhkiG
# 9w0BAQEFAAOCAg8AMIICCgKCAgEAsdenpxmSRkO4GjCU4Y6F3P8sk0v+NcLzPg2U
# T70SutUcfMK4qpd42vg5q8ekUhBELPYo6IJ4jZH48gSy+x3QmxWfK1crmuiUGaLz
# vosF0ugUvjrwR0oh+OWXvPNCP82otkzQ0BmhYFa4PcPlO1e5e5V6MnavNo6mTUDd
# byMnwBGrhXToVLfM0EKhWFjgIDPbYprx2acAuu8q91Ph9Rgrp95791RPT+b0mdWR
# mXE/m1Rd9a/VOYRTTIVUCkJk8lu3ACdz2NOHkwpf/88DHyOQtGbFn7QdrP/rEi3o
# awxixqzJQG/4JrKT4g6LmxccMoWU8PqPtbSNgy5aBtIrt48O2ojQVKP/8kJz3Mce
# ytK9soscSAEuhxUPiiBJ0FwaCjpHnwBQ3wunLL+A4LK2fCdHR3/uSlnpDqTwa/AY
# bUX0DmXLZyo7OnurSozbpAgxAyCUH2qdRHGjvF6fw9NxetGZEd7Yv41GpctGASM0
# lZdz9Tv1LAE3jzqWmiAhheuG3nDN2IXUFornmQkQdXspx8onsRzyArTnRmJrwW0s
# IBrU545AQwWZmEZgWUO6DvR6WOrgM6npeL/8djPYcXUefAsbUeu1mtfRuzCFx641
# jlvT/0vS1h8Qpr/KwWB/1yeoDtCzBtcu0VTX1Wu+LE5BXcN612DqiIACtz/0QFbJ
# fpyZFDkCAwEAAaOCAcswggHHMB0GA1UdDgQWBBQtDB8IozpYMRixWJ1H/9SrxSE8
# KzAfBgNVHSMEGDAWgBRraSg6NS9IY0DPe9ivSek+2T3bITBsBgNVHR8EZTBjMGGg
# X6BdhltodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNyb3Nv
# ZnQlMjBQdWJsaWMlMjBSU0ElMjBUaW1lc3RhbXBpbmclMjBDQSUyMDIwMjAuY3Js
# MHkGCCsGAQUFBwEBBG0wazBpBggrBgEFBQcwAoZdaHR0cDovL3d3dy5taWNyb3Nv
# ZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBQdWJsaWMlMjBSU0ElMjBU
# aW1lc3RhbXBpbmclMjBDQSUyMDIwMjAuY3J0MAwGA1UdEwEB/wQCMAAwFgYDVR0l
# AQH/BAwwCgYIKwYBBQUHAwgwDgYDVR0PAQH/BAQDAgeAMGYGA1UdIARfMF0wUQYM
# KwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTAIBgZngQwBBAIwDQYJKoZI
# hvcNAQEMBQADggIBACQy8BuRCDedg5cjvt1JrGfNEEuZD+HFluQ4LgxvhNfs0z/W
# CZvsza3hCxoujcMv8EVEsVy9QTdyBUO2mHNYgDtKGhLZke1h6t4wZCC8egZ5UNQY
# Vx3znEl6LSUAB1jtzNKd61VeMqlS38fkFj1CgkUF74XStlHTyop/ZgS5YZb0i7TK
# Rlh8k4TEZUsNSx9iFTRsFfweyGDz2kPDjJIctefyK55yqTOu5Y6SVHdCAulte0F5
# 5uNwEqqdq+PVROnFmeZO7aAS6fuyYW8QbnYXsHfM2YdLmaDmGalMPF/7XrsbNu7O
# DWuGOtjd+6NvRJRPmLkkBxC6M/r3gZJugK0qdjiNgVovfr5qxUYLIu8kEkyRSSgD
# iOf2vw5OILdi55RZ0zAgqFMMET6ccl3uYo5hpzCxy7tAuJTnUYIfJhMX53GTLLDF
# 0n4Zn957RxlqGOl7OBtYUpcDLHX8fzuKTo+UiiwAkytRVtnBAXpWAMJIufd/AZ0e
# CFI1xvI1/GdHwBKD2DkEkQ3mBitM+iAT5giK3wn5PLpczd23bq2tssDzlDke/Ugj
# 0IQQxbL1ELGYaGXBBkI5Av+AL7AqhyaQzqf5vEsnVk8545eOws3SYN/6H7CgzM82
# DpuzvV8fC0OggpmIzRvmo0cgOH5u8ckurTDBpCLOM1mIBcc188THq9CXQv+iMYIH
# QzCCBz8CAQEweDBhMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1lc3Rh
# bXBpbmcgQ0EgMjAyMAITMwAAADUJBbWy54TvDAAAAAAANTANBglghkgBZQMEAgEF
# AKCCBJwwEQYLKoZIhvcNAQkQAg8xAgUAMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0B
# CRABBDAcBgkqhkiG9w0BCQUxDxcNMjQwODIzMTQyODIyWjAvBgkqhkiG9w0BCQQx
# IgQgYE5my8TtlxLdIHDLBr/i1P6h4L3lR5PQ3EQBZ68SnOswgbkGCyqGSIb3DQEJ
# EAIvMYGpMIGmMIGjMIGgBCB8UwBhJlqEwjzOn3ivLXEG6BiHCFJd8/pbYw4mdVfq
# gDB8MGWkYzBhMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1lc3RhbXBp
# bmcgQ0EgMjAyMAITMwAAADUJBbWy54TvDAAAAAAANTCCA14GCyqGSIb3DQEJEAIS
# MYIDTTCCA0mhggNFMIIDQTCCAikCAQEwggEJoYHhpIHeMIHbMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046N0QwMC0w
# NUUwLUQ5NDcxNTAzBgNVBAMTLE1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWUgU3Rh
# bXBpbmcgQXV0aG9yaXR5oiMKAQEwBwYFKw4DAhoDFQAv7LuGkggat7WW6IqjoOcX
# AMti2aBnMGWkYzBhMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1lc3Rh
# bXBpbmcgQ0EgMjAyMDANBgkqhkiG9w0BAQsFAAIFAOpzFIMwIhgPMjAyNDA4MjMx
# NDAwMzVaGA8yMDI0MDgyNDE0MDAzNVowdDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA
# 6nMUgwIBADAHAgEAAgIpTjAHAgEAAgITozAKAgUA6nRmAwIBADA2BgorBgEEAYRZ
# CgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0G
# CSqGSIb3DQEBCwUAA4IBAQCi1iRGN6TET3D7CdU5ox7FBU9d5p0Pkrw3EYjyDj1W
# 6psW7NDTykXYRcQ08hYy3r9NVvpX49N26iZ8Cv+V79L7O99u1HovUnZcIirolEho
# /DiralAA3v3R86616le+82axQUpzhYiyKcKWvYN83tRD8VQTkkKSeDAukuc1eZ5c
# lK25LRNamoz2Vj8CWMeEaVJR3KBwoebfQGyizX0tblkowhFkZrHyn2+gFaOcPZ/o
# Eh6wAM6CLSRVLqrRGpsgOAfzciuVsOugfCNk+nceinuzlsWv2i5JuztO9YQWDOjg
# j62aZtzZX7FqNb6YNXvMSwgsscz8IbDMPvMsimZWo/uPMA0GCSqGSIb3DQEBAQUA
# BIICAAOk6FUbHublTgnfmuTczwv6qD+SizbfVtd45V+7N7cFsi/QzYDGoK1w9gi5
# BhKaQIaozAfrlVOoyC0lFjAenV6BEQrPdaS/u0eL1Bp5KDKGMYMmZHnmc2DjDrL0
# 1Gp7400ptNU65V8RRjHoNcbVVVzUXdhWsDh5a9Fm0a1h/o3MIDMYjL2TetctvRLg
# 1u/QAnPyY2i75Q5ywrRQa+EY5npFOlwwngt4Nagdwc3UpvpHs1Dgy+5YJUQGe3xb
# PiG7aIUcnrR1so0f7DVgUc4AGj3U8ZYxxQalRiCoSXqFlRV1iO6ttHwx8GuP5OWG
# mJipetM0OkLR6m5fJmS9gkDzw3Z5OjJbhqy1LRp/s8r7EGvfnsDs1ljsWPDj2Mhh
# QEDTrC7o8OM22Eu05K2GyqsE71vefY6onhi3IMrKjaX4gysPLEB4bEvCE2oGtifN
# Sf5enBap1j9sIdpiLiID64GWFIelBejF+bse2Nkmk0c0qiFjT2wYUlRuBpznDnvG
# I0MmoTwPawj8CE9fOTQ70vs27K+JPvpR0WqExqw1EgGMQoEJN5R7hIS2liYYgnyd
# lNzSGCX/rmvpnn3qnLS3g+fVIs0Dd6sFchPJuTKAU2BtW6HVSqLr3yeeTv1og4fP
# Jaaxw/GbEwLq+93diWWhbHmmp63zGGmwinfPnqHn8TxsfPhn
# SIG # End signature block
