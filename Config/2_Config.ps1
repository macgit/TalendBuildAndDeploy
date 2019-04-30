#This is an array list of options to validate against the user input
$_TSCV_PredefinedValueList=@(@("BUILD","DEPLOY","BUILDANDDEPLOY"),@());
$_TSCV_ReturnCodeList=@(0,151,5)


#Time when the script was invoked
$_TSCV_DateTime=Get-Date -Format 'yyyy.MM.dd HH.mm.ss'

##########################################################################################

if([string]::IsNullOrEmpty($TOS_JobExportPath)){
    $_TSCV_BuildExportPath=($_TSECV_BuildExportPath).Replace('\','\\');
}else{
    $_TSCV_BuildExportPath=($TOS_JobExportPath).Replace('\','\\');
}
$_TSCV_CommandLinePath=($_TSECV_CommandLinePath).Replace('\','\\');


####################################################################################
$_TSCV_FullLogFileName=[String]::Concat($_TSECV_LogFilePath.Replace('\','\\'),'\\',$_TSCV_DateTime,'.log')


###################################################################################
$_TSCV_Build_SVNRootURL=Get-Variable -ValueOnly _TSECV_${TBS_Env}_SVNRootURL -ErrorAction "silentlycontinue"
$_TSCV_Build_SVNRootURL=[String]::Concat($_TSCV_Build_SVNRootURL,'/',$TBS_ProjectName,'/',$TBS_Branch,'/process');
$_TSCV_Build_SVNUserName=Get-Variable -ValueOnly _TSECV_${TBS_Env}_SVNUserName -ErrorAction "silentlycontinue"
$_TSCV_Build_SVNPassword=Get-Variable -ValueOnly _TSECV_${TBS_Env}_SVNPassword -ErrorAction "silentlycontinue"

$_TSCV_Build_TACURL=Get-Variable -ValueOnly _TSECV_${TBS_Env}_TACURL -ErrorAction "silentlycontinue"

$_TSCV_Deploy_TACURL=Get-Variable -ValueOnly _TSECV_${TDS_Env}_TACURL -ErrorAction "silentlycontinue"





