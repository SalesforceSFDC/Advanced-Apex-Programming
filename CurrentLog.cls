/**
Function to display the current diagnostic log
**/

public static String CurrentLog()
{
    if(DiagnosticLog == null) return null;
    String spaces = '                       ';
    String result = '';
    for(DiagnosticEntry de: DiagnosticLog)
    {
        Integer endindex = 3 * de.level;
        if(endindex >= spaces.length())
            endindex = spaces.length()-1;
        result += spaces.substring(0,endindex) +
            de.description + '\n';
    }
    return result;
}
