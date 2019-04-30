####################################################################
#   Env List                                                       #
####################################################################
$_TSECV_EnvList=@("Dev","KLif","ACC","REC","PROD")

#####################################################################
#  SVN Details                                                      #
#####################################################################
$_TSECV_Dev_SVNRootURL='https://svn.ancy.fr.sopra/svnii'
$_TSECV_Dev_SVNUserName="_svn_Talend";
$_TSECV_Dev_SVNPassword="svnTalend";

######################################################################
#   TAC URLS For ALl the Env declared in $_TSECV_EnvList             #
#   for all the env in $_TSECV_EnvList TAC URL should be added below #
#   Format : $TSECV_<env-Name>_TACURL="<Value>"                      #
######################################################################
$_TSECV_Dev_TACURL="http://india.poc.tlddi.corp.sopra:8080/Talend";
$_TSECV_Klif_TACURL="http://localhost:8080/Talend"

######################################################################
#   File Paths                                                       #
######################################################################
#$_TSECV_LogFilePath='C:\Users\samishra\Downloads'
$_TSECV_LogFilePath='D:\Visual Studio Projects\BuildAndDeploy_InProgress'
$_TSECV_CommandLinePath='C:\Talend\cmdLine'
#$_TSECV_BuildExportPath='\\india.poc.tlddi.corp.sopra\d$\Talend\Export'
$_TSECV_BuildExportPath='C:\Talend\TalendStudio'
