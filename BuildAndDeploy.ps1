############################################################################################################################################################
# PreRequisite : Java 1.8 version should be installed on the server (set java path in env variable, if not added by the installer)                         #
#              : SVN commandline should be installed on the server (set svn commandline in env variable, if not added by the installer)                    #
#              : Talend Commandline should be installed on the server and license should be set, by launching the commandline for the first time manually  #
############################################################################################################################################################

<#
.SYNOPSIS
    Script automates the build and deploy process of Talend jobs

.DESCRIPTION
    This script takes three type of input arguments with prefix TS, TBS, TDS. Argument with prefix TS should always be passed to the script,
    argument with prefix TBS should be passed when the script is running in Build Mode, argument with prefix TDS should be passed when the 
    script is running in Deploy Mode, argument with prefix TBS and TDS should be passed when the scipt is running in BuildAndDeploy mode

.PARAMETER 
    -TS_LoggingOn [<SwitchParameter>]
            Writes the console output to a log file
            Value     : $true,$false
            Default   : $true
            Mandatory : True

    -TS_Mode <String>
            launches the script to build, deploy or build and deploy talend jobs
            Value     : Build, Deploy, BuildAndDeploy
            Mandatory : True
            
    -TBS_Env <String>
            specify the environment which should be used to build the talend job
            Mandatory : True
            Example   : Dev, Klif, ACC, REC, PROD
            Note      : the env name must be present in EnvConfig file

    -TBS_UserName <String>
            Specify the TAC username that will be used by the script to login to TAC and build the job
            Example   : talend.user@soprasteria.com
            Mandatory : True
            Note      : This talend user name should exist in TAC env passed to TDS_Env
                      : if -TBS_Env:"DEV" -TBS_UserName:"talend.user@soprasteria.com" is passed to the script then user talend.user@soprasteria.com should exist in DEV TAC

    -TBS_Password <String>
            specify the TAC password for the TAC user name passed in argument TBS_UserName
            Example   : talendpassword
            Mandatory : True

    -TBS_ProjectName <String>
            specify the Talend project name in which the talend job exist
            Example   : EAI_ADINFRA
            Mandatory : True

    -TBS_Branch <String>
            specify the svn branch that should be used to build the job
            Example   : trunk, tags/jobname_r56
            Mandatory : True

    -TBS_JobName <String>
            specify the Talend jobname
            Example   : phonesystem
            Mandatory : True

    -TDS_Env <String>
            specify the environment where the build should be deployed
            Example   : Dev, Klif, ACC, REC, PROD
            Note      : the env name must be present in EnvConfig file

    -TDS_UserName <String>
            Specify the TAC username that will be used by the script to login to TAC and deploy the job
            Example   : talend.user@soprasteria.com
            Mandatory : True

    -TDS_Password <String>
            specify the TAC password for the TAC user name passed in argument TDS_UserName
            Example   : talendpassword
            Mandatory : True

    -TOS_JobNameWithRevision <String>
            specify the job zip file name that is to be deployed
            Example   : Jobname_r53
            Mandatory : False

    -TDS_JobTACLabel <String>
            specify the Label name for the task that will be craeted in TAC for the above Job
            Example   : Interface PhoneSystem
            Mandatory : True

.Optional Parameter

    -TOS_JobNameWithRevision
            this parameter is not required when running the job in BuildAndDeploy mode

    -TOS_JobExportPath
            when build export path is passed to the script, it will override the export path mentioned in config file

    -Verbose
            when the script is run with this parameter in addition to the above parameters, this will show the execution logs

.Example
    Deploy
        .\BuildAndDeploy.ps1 -TS_Mode:"Deploy"  -TDS_Env:"Klif" -TDS_JobTACLabel:"TestScript" -TDS_Password:"klifindia64" -TDS_UserName:"saket.mishra@soprasteria.com" -TOS_JobNameWithRevision:"PH_SYStoHUB_Phone_Numbers_r306" -VERBOSE -TS_LoggingOn

    Build
        .\BuildAndDeploy.ps1 -TS_Mode:"Build" -TBS_Branch:"trunk" -TBS_Env:"Dev" -TBS_JobName:"PH_SYStoHUB_Phone_Numbers" -TBS_Password:"indiadev64" -TBS_ProjectName:"EAI_ADINFRA" -TBS_UserName:"saket.mishra@soprasteria.com" -TOS_JobExportPath:"\\india.poc.tlddi.corp.sopra\d$\Talend" -VERBOSE -TS_LoggingOn

    BuildAndDeploy
        .\BuildAndDeploy.ps1 -TS_Mode:"BuildAndDeploy" -TBS_Branch:"trunk" -TBS_Env:"Dev" -TBS_JobName:"PH_SYStoHUB_Phone_Numbers" -TBS_Password:"indiadev64" -TBS_ProjectName:"EAI_ADINFRA" -TBS_UserName:"saket.mishra@soprasteria.com" -TOS_JobExportPath:"\\india.poc.tlddi.corp.sopra\d$\Talend" -TDS_Env:"Klif" -TDS_JobTACLabel:"TestScript" -TDS_Password:"klifindia64" -TDS_UserName:"saket.mishra@soprasteria.com" -VERBOSE -TS_LoggingOn

#>

[CmdletBinding() ]
Param(
    [Switch]$TS_LoggingOn,
    [String]$TS_Mode,

    [String]$TBS_Env,
    [String]$TBS_UserName,
    [String]$TBS_Password,
    [String]$TBS_ProjectName,
    [String]$TBS_Branch,
    [String]$TBS_JobName,

    [String]$TDS_Env,
    [String]$TDS_UserName,
    [String]$TDS_Password,
    [String]$TDS_JobTACLabel,

    [String]$TOS_JobNameWithRevision,
    [String]$TOS_JobExportPath
)

          
Function ExitWithError{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [psobject]$_FP_ErrMessage
    )
    if(-Not [string]::IsNullOrEmpty($_FP_ErrMessage)){ Write-Error $_FP_ErrMessage}
    Write-Error "Exiting Shell Execution"
    Exit;

}
Function GetVarList{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_VarToSearch
    )   
    write-Output (Get-Variable -Scope "Script" -Include "$_FP_VarToSearch*")
}

Function IsVarNullOrEmpty{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [psobject]$_FP_VarToCheck
    )
    if([string]::IsNullOrEmpty($_FP_VarToCheck."Value")){Write-Output $_FP_VarToCheck."Name"}
}


Function ValidateVarForNull{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_VarToValidate
    )
    $_FP_VarToValidate | GetVarList | ForEach-Object{
        $_ | IsVarNullOrEmpty | ForEach-Object{  
            write-Output "$_ is null or empty, Run script with switch -$_"
        }
    }
}

Function SearchValueInList{
    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [String]$_FP_KeyToSearch,
        [ValidateNotNullOrEmpty()]
        [array]$_FP_KeyList
    )

    if($_FP_KeyToSearch -notin $_FP_KeyList){Write-Output "$_FP_KeyToSearch is not a valid value, valid values are $_FP_KeyList"}
}

function ValidateScriptInput{

    "TS" | ValidateVarForNull | ForEach-Object{$_ | ExitWithError}
    SearchValueInList -_FP_KeyToSearch $TS_Mode -_FP_KeyList $_TSCV_PredefinedValueList[0] | ForEach-Object{"-TS_MODE:$_" | ExitWithError}

    if($TS_Mode -in @($_TSCV_PredefinedValueList[0][0],$_TSCV_PredefinedValueList[0][2])){
        "TBS" | ValidateVarForNull | ForEach-Object{$_ | ExitWithError}
        SearchValueInList -_FP_KeyToSearch $TBS_Env -_FP_KeyList $_TSECV_EnvList | ForEach-Object{"-TBS_Env:$_" | ExitWithError}
    }

    if($TS_Mode -in @($_TSCV_PredefinedValueList[0][1],$_TSCV_PredefinedValueList[0][2])){
        "TDS" | ValidateVarForNull | ForEach-Object{$_ | ExitWithError}
        SearchValueInList -_FP_KeyToSearch $TDS_Env -_FP_KeyList $_TSECV_EnvList | ForEach-Object{"-TDS_Env:$_" | ExitWithError}
    }
    if($TS_Mode -in @($_TSCV_PredefinedValueList[0][1])){
        "TOS_JobNameWithRevision" | ValidateVarForNull | ForEach-Object{$_ | ExitWithError}
    }

}

Function FormatMessage{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_Message
    )

    $_FUV_DateTime=Get-Date -Format '[yyyy.MM.dd HH.mm.ss] : ';

    $_FP_Message.Split("`n") | ForEach-Object{
        if($null -eq $_FUV_Counter){
            Write-Output $_FUV_DateTime$_
            $_FUV_Counter = $_FUV_Counter + 1;
        }else{
            Write-Output $_.PadLeft($_FUV_DateTime.Length+$_.Length)
        }
    }

}

Function PrintMessage{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_Message
    )

    Write-verbose $_FP_Message
}

Function WriteLog{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_Message
    )

    if(-Not (Test-Path -Path $_TSCV_FullLogFileName)){
        New-Item -Path $_TSCV_FullLogFileName -Force | Out-Null
    }
    $_FP_Message | Add-Content -Path $_TSCV_FullLogFileName

}

Function TestPath{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_PSOb
    )
    if(Test-Path -Path "$_FP_PSOb".Replace('\\','\')){write-output $true}
    else{Write-Output $false}
}
Function ProcessMessage{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_Message,
        [Switch]$_FP_Log=$TS_LoggingOn
    )

    $_FP_Message | FormatMessage | ForEach-Object{
        if($_FP_Log){$_ | WriteLog}
        $_ | PrintMessage

    }

}

Function ExecuteSvnCommand{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_PSOb,
        [String]$_FP_SvnArgument
    )

    $_FUV_Command=[string]::Concat('svn --non-interactive --username ',$_FP_PSOb.'_FP_SVNUser',' --password ',$_FP_PSOb.'_FP_SVNPass',' ',$_FP_SvnArgument)

    $_FUV_Result=Invoke-Expression "$_FUV_Command 2>&1"

    if($_FUV_Result -like '*:*'){ "$_FUV_Result" | ProcessMessage -_FP_Log:$TS_LoggingOn | ExitWithError}
    Write-Output $_FUV_Result    
}

Function SearchJobInSvnRepo{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_PSOb
    )
    $_FUV_SVNArg=[string]::Concat('list -R --search ',$_FP_PSOb.'_FP_JobName',' ',$_FP_PSOb.'_FP_SVNURL')
 

    $_FP_PSOb | ExecuteSvnCommand -_FP_SvnArgument:"$_FUV_SVNArg" | ForEach-Object{

        if(-Not [String]::IsNullOrEmpty($_) -and $_.Split("/")[-1] -match [String]::Concat('^',$_FP_PSOb.'_FP_JobName','_[0-9].*.item')){
            $_
        }
    } | Measure-Object -Maximum | ForEach-Object{
        if($_."Count" -eq 0){[string]::Concat($_FP_PSOb.'_FP_JobName',' doesn','t exist in SVN ',$_FP_PSOb.'_FP_SVNURL') | ProcessMessage -_FP_Log:$TS_LoggingOn | ExitWithError}
        else{
            $_FP_PSOb.'_FP_Result'=$_."Maximum"
			$_FP_PSOb.'_FP_JobVersion'=($_."Maximum").Replace('.item','').Split("_")[-1]
            write-output $_FP_PSOb
        }
    }
 
}

Function GetRevision{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_PSOb
    )
    $_FUV_SVNArg=[string]::Concat("info --show-item 'last-changed-revision' ",$_FP_PSOb.'_FP_SVNURL','/',$_FP_PSOb.'_FP_Result')

    $_FP_PSOb | ExecuteSvnCommand -_FP_SvnArgument:"$_FUV_SVNArg" | ForEach-Object{
        $_FP_PSOb.'_FP_Result'=$_
        Write-Output $_FP_PSOb
    }
}

Function ConvertToBase64{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_String
    )

    [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$_FP_String")) | ForEach-Object{
        Write-Output $_
    }

}

function InvokeRestWebAPI {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_RestAPIWebURL
    )
    Invoke-RestMethod -Uri $_FP_RestAPIWebURL -Method Get | ForEach-Object{
        Write-Output $_
    }
}

Function CreateSvnTag{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_PSOb
    )
    $_FUV_JSONToCreateTag=[String]::Concat('{
        "actionName": "createTag",
        "authPass": "',$_FP_PSOb.'_FP_Password','",
        "authUser": "',$_FP_PSOb.'_FP_UserName','",
        "projectName":"',$_FP_PSOb.'_FP_Project','",
        "source": "trunk",
        "target": "',$_FP_PSOb.'_FP_Branch','"
    }')

    "$_FUV_JSONToCreateTag" | ConvertToBase64 | ForEach-Object{
        [String]::Concat($_FP_PSOb.'_FP_TACURL','/metaServlet?',$_) | InvokeRestWebAPI | ForEach-Object{
            if($_."ReturnCode" -notin $_TSCV_ReturnCodeList){"$_" | ProcessMessage | ExitWithError}
            "$_" | ProcessMessage
        }
    }
    [string]::Concat('Setting Tag value with label ',$_FP_PSOb.'_FP_Branch') | ProcessMessage
}

Function GetTagName{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_PSOb
    )
    $_FP_PSOb | SearchJobInSvnRepo | GetRevision | ForEach-Object{
        if($_FP_PSOb.'_FP_Branch' -eq "trunk"){
            $_FP_PSOb.'_FP_Branch' =[String]::Concat('tags/',$_FP_PSOb.'_FP_JobName','_r',$_FP_PSOb.'_FP_Result')
            $_FP_PSOb.'_FP_Result' =[String]::Concat($_FP_PSOb.'_FP_JobName','_r',$_FP_PSOb.'_FP_Result')
            $_FP_PSOb | CreateSvnTag
        }
        else{
            $_FP_PSOb.'_FP_Result' =[String]::Concat($_FP_PSOb.'_FP_JobName','_r',$_FP_PSOb.'_FP_Result')
        }
    }

    Write-Output $_FP_PSOb
}

Function CreateCLScriptFile{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_PSOb
    )
    $_FUV_BuildScriptContent=[String]::Concat('initRemote ',$_FP_PSOb.'_FP_TACURL',' -ul ',$_FP_PSOb.'_FP_UserName',' -up ',$_FP_PSOb.'_FP_Password',"`r`n",
                                              'logonProject -pn ',$_FP_PSOb.'_FP_Project',' -ul ',$_FP_PSOb.'_FP_UserName',' -up ',$_FP_PSOb.'_FP_Password',' -br ',$_FP_PSOb.'_FP_Branch',' -ro',"`r`n",
                                              'buildJob ',$_FP_PSOb.'_FP_JobName',' -dd ',$_FP_PSOb.'_FP_ExportPath',' -af ',$_FP_PSOb.'_FP_Result',' -jc Default -jv ',$_FP_PSOb.'_FP_JobVersion',"`r`n",
                                              'logoffProject' )

    $_FUV_ScriptFilePath=[String]::Concat($_FP_PSOb.'_FP_CLPath','\\CL_BuildScript_',($_FP_PSOb.'_FP_UserName').Split("@")[0].Split(".")[0])
    $_FUV_BuildScriptContent | Set-Content $_FUV_ScriptFilePath

    "Creating commandline script with parameter $_FUV_BuildScriptContent" | ProcessMessage

    Write-Output $_FUV_ScriptFilePath


}

Function VerifyBuild{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_PSOb
    )

    $_FUV_Workspace=-Join('Workspace_',($_FP_PSOb.'_FP_UserName').Split("@")[0].Split(".")[0])
    $_FUV_CLLogPath=[String]::Concat($_FP_PSOb.'_FP_CLPath','\\',$_FUV_Workspace,'\\status.log')
    $_FUV_ExportPath=[string]::Concat($_FP_PSOb.'_FP_ExportPath','\\',$_FP_PSOb.'_FP_Result','.zip')

    $_FUV_CLLogPath | TestPath | ForEach-Object{
        If(-Not $_){"Build not Successfull" | ProcessMessage; "Status.log not found at $_FUV_CLLogPath" | ProcessMessage | ExitWithError}
        else{"Fetching Build Status Log..." | ProcessMessage}
    }
    Get-Content -Path $_FUV_CLLogPath | ForEach-Object{
        $_ | ProcessMessage
        if($_ -like "*Failed*"){"Build not Successfull" | ProcessMessage; "Check status log at $_FUV_CLLogPath" | ProcessMessage | ExitWithError}
    }

    $_FUV_ExportPath | TestPath | ForEach-Object{
        if(-NOT $_){"Build not Successfull" | ProcessMessage; "Exported Zip not found at $_FUV_ExportPath" | ProcessMessage | ExitWithError}
    }
    "Build is successfully exported to $_FUV_ExportPath" | ProcessMessage
}

Function RunBuild{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_PSOb
    )
    $_FP_PSOb | CreateCLScriptFile | ForEach-Object{
        $_FUV_CLScriptPath=$_
    }
    
    [String]::Concat('Building job ',$_FP_PSOb.'_FP_JobName',' from tag ',$_FP_PSOb.'_FP_Branch')

    $_FUV_CLArg=[String]::Concat('-nosplash -application org.talend.commandline.CommandLine -consoleLog -data ',$_FP_PSOb.'_FP_CLPath','\\Workspace_',($_FP_PSOb.'_FP_UserName').Split("@")[0].Split(".")[0],' scriptFile ',$_FUV_CLScriptPath)
    $_FUV_CLEXE=[String]::Concat($_FP_PSOb.'_FP_CLPath','\\Talend-Studio-win-x86_64')

    "Launching CommandLine with Parameters $_FUV_CLArg" | ProcessMessage

    $_FUV_ProcObj= Start-Process -FilePath $_FUV_CLEXE -ArgumentList $_FUV_CLArg -PassThru
    
    while(!$_FUV_ProcObj.HasExited){
        Start-Sleep 5
    }
    if($_FUV_ProcObj.ExitCode -eq 0){$_FP_PSOb | VerifyBuild}
    else{ "Error : Commandline closed with exit code $_FUV_ProcObj.ExitCode" | ProcessMessage | ExitWithError}

    Write-Output $_FP_PSOb
}

Function GetTaskID{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_PSOb
    )
    $_FUV_JSON=[String]::Concat('{
        ""actionName"": ""getTaskIdByName"",
        ""authPass"": ""',$_FP_PSOb.'_FP_Password','"",
        ""authUser"": ""',$_FP_PSOb.'_FP_UserName','"",
        ""taskName"": ""',$_FP_PSOb.'_FP_TACLabel','""
      }')

    "$_FUV_JSON" | ConvertToBase64 | ForEach-Object{
        [String]::Concat($_FP_PSOb.'_FP_TACURL','/metaServlet?',$_) | InvokeRestWebAPI | ForEach-Object{
            if($_."ReturnCode" -notin $_TSCV_ReturnCodeList){"$_" | ProcessMessage | ExitWithError}
            $_FP_PSOb.'_FP_Result'=$_."taskID"
            "$_" | ProcessMessage
        }
    }
    Write-Output $_FP_PSOb

}

Function CreateTask{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_PSOb
    )
    [String]::Concat('Creating Job ',$_FP_PSOb.'_FP_JobName',' with Task Label : ',$_FP_PSOb.'_FP_TACLabel') | ProcessMessage

    $_FUV_JSON=[String]::Concat('{
        "actionName" : "associatePreGeneratedJob",
        "active"     : "true",
        "authPass"   : "',$_FP_PSOb.'_FP_Password','",
        "authUser"   : "',$_FP_PSOb.'_FP_UserName','",
        "contextName": "Default",
        "description": "created using script at ',$_FP_PSOb.'_FP_TimeStamp','",
        "executionServerName" : "Job Server",
        "filePath" : "',$_FP_PSOb.'_FP_JobName','",
        "importType" : "File",
        "logLevel" : "Info",
        "onUnknownStateJob" : "WAIT",
        "pauseOnError" : "false",
        "taskName" : "',$_FP_PSOb.'_FP_TACLabel','",
        "taskType":"Normal",
        "timeout": 3600
    }')

        "$_FUV_JSON" | ConvertToBase64 | ForEach-Object{
            [String]::Concat($_FP_PSOb.'_FP_TACURL','/metaServlet?',$_) | InvokeRestWebAPI | ForEach-Object{
                if($_."ReturnCode" -notin $_TSCV_ReturnCodeList){"$_" | ProcessMessage | ExitWithError}
                "$_" | ProcessMessage
            }
        }
        Write-Output $_FP_PSOb
}

Function UpdateTask{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_PSOb
    )
    [String]::Concat('Updating Job ',$_FP_PSOb.'_FP_JobName',' with Task ID : ',$_FP_PSOb.'_FP_Result',' and TAC Label : ',$_FP_PSOb.'_FP_TACLabel') | ProcessMessage

    $_FUV_JSON=[String]::Concat('{
        "actionName" : "updateTask",
        "active"     : "true",
        "applyContextToChildren" : "false",
        "authPass"   : "',$_FP_PSOb.'_FP_Password','",
        "authUser"   : "',$_FP_PSOb.'_FP_UserName','",
        "contextName": "Default",
        "description": "updated using script at ',$_FP_PSOb.'_FP_TimeStamp','",
        "filePath"   : "',$_FP_PSOb.'_FP_JobName','",
        "logLevel"   : "Info",
        "onUnknownStateJob" : "WAIT",
        "pauseOnError" : "false",
        "taskId" : "',$_FP_PSOb.'_FP_Result','",
        "taskName" : "',$_FP_PSOb.'_FP_TACLabel','",
        "timeout": "3600"
    }')

    "$_FUV_JSON" | ConvertToBase64 | ForEach-Object{
        [String]::Concat($_FP_PSOb.'_FP_TACURL','/metaServlet?',$_) | InvokeRestWebAPI | ForEach-Object{
            if($_."ReturnCode" -notin $_TSCV_ReturnCodeList){"$_" | ProcessMessage | ExitWithError}
            "$_" | ProcessMessage
        }
    }
    Write-Output $_FP_PSOb
}

Function DeployTask{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_PSOb
    )
    [String]::Concat('Deploying Job ',$_FP_PSOb.'_FP_JobName',' with Task ID : ',$_FP_PSOb.'_FP_Result',' and TAC Label : ',$_FP_PSOb.'_FP_TACLabel') | ProcessMessage

    $_FUV_JSON=[String]::Concat('{
        "actionName" : "requestDeploy",
        "authPass"   : "',$_FP_PSOb.'_FP_Password','",
        "authUser"   : "',$_FP_PSOb.'_FP_UserName','",
        "taskId"     : "',$_FP_PSOb.'_FP_Result','"
    }')
    "$_FUV_JSON" | ConvertToBase64 | ForEach-Object{
        [String]::Concat($_FP_PSOb.'_FP_TACURL','/metaServlet?',$_) | InvokeRestWebAPI | ForEach-Object{
            if($_."ReturnCode" -notin $_TSCV_ReturnCodeList){"$_" | ProcessMessage | ExitWithError}
            "$_" | ProcessMessage
        }
    }
    "Deployment is successfull" | ProcessMessage
}

Function InitiateDeployment{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject]$_FP_PSOb
    )
    [String]::Concat('Starting deployment of job ',$_FP_PSOb.'_FP_JobName',' using TAC URL : ',$_FP_PSOb.'_FP_TACURL') | ProcessMessage
    $_FP_PSOb | GetTaskID | ForEach-Object{
        if(-Not [string]::IsNullOrEmpty($_.'_FP_Result')){
            $_ | UpdateTask | DeployTask
        }
        else{
            $_ | CreateTask | ForEach-Object{
                $_ | GetTaskID | DeployTask
            }
        }
    }

}






###################################################
# Script Execution Starts from here
###################################################

#set Script Home
$_TSV_ScriptHome = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

#Load Config Files
if(Test-Path -Path "$_TSV_ScriptHome\Config"){

    Get-ChildItem -Path "$_TSV_ScriptHome\Config\" -Filter "*.ps1" |ForEach-Object{
        . $_.FullName
        Write-Output $_.FullName
    } | Measure-Object | ForEach-Object{
        if($_.count -lt 2){"Config file for script not found" | ExitWithError}
    }
}else{
    "Config folder with config files not found" | ExitWithError
}

#Validate script input parameters
ValidateScriptInput

"Starting script in $TS_Mode mode" | ProcessMessage

$_TSV_PSObBuild=@{
    _FP_Env          =$TBS_Env
    _FP_UserName     =$TBS_UserName
    _FP_Password     =$TBS_Password
    _FP_Project      =$TBS_ProjectName
    _FP_Branch       =$TBS_Branch
    _FP_JobName      =$TBS_JobName
    _FP_SVnURL       =$_TSCV_Build_SVNRootURL
    _FP_SVNUser      =$_TSCV_Build_SVNUserName
    _FP_SVNPass      =$_TSCV_Build_SVNPassword
    _FP_TACURL       =$_TSCV_Build_TACURL
    _FP_CLPath       =$_TSCV_CommandLinePath
    _FP_ExportPath   =$_TSCV_BuildExportPath
	_FP_JobVersion   =''
    _FP_Result       =''
}

if($TS_Mode -in @($_TSCV_PredefinedValueList[0][0],$_TSCV_PredefinedValueList[0][2])){

    New-Object -TypeName psobject -Property $_TSV_PSObBuild | GetTagName | RunBuild | ForEach-Object{
        $TOS_JobNameWithRevision=$_.'_FP_Result'
    }

}

$_TSV_PSObDeploy=@{
    _FP_TimeStamp  =$_TSCV_DateTime
    _FP_Env        =$TDS_Env
    _FP_TACLabel   =$TDS_JobTACLabel
    _FP_Password   =$TDS_Password
    _FP_UserName   =$TDS_UserName
    _FP_JobName    ="$_TSCV_BuildExportPath\\$TOS_JobNameWithRevision.zip"
    _FP_TACURL     =$_TSCV_Deploy_TACURL
    _FP_Result   =''
}

if($TS_Mode -in @($_TSCV_PredefinedValueList[0][1],$_TSCV_PredefinedValueList[0][2])){

    New-Object -TypeName psobject -Property $_TSV_PSObDeploy | InitiateDeployment
}