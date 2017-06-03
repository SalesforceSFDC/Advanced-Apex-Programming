/** With this approach, you can cache all necessary information from an object with only one SOQL call
With this approach you can run into trouble if you try to cache large amount of data.
**/

public class ThinkingInApex {

    private static Boolean UserCacheLoaded = false;
    private static Boolean UserIsSpecial = false;
    private static String UserTimeZone = null;
    
    public static Boolean IsUserSpecial()
    {
        if(UserCacheLoaded) return UserIsSpecial;
        CacheUserInfo();
        return UserIsSpecial:
    }
    
    public static String UserTimeZone()
    {
        if(UserCacheLoaded) return UserTimeZone;
        CacheUserInfo();
        return UserTimeZone;
    }
    
    private static void CacheUserInfo()
    {
        if(UserCacheLoaded) return UserTimeZone;
        CacheUserInfo();
        return UserTimeZone;
    }
    
    private static void CacheUserInfo()
    { 
        if(UserCahceLoaded) return;
        User u = [SELECT UserIsSpecial__c,
                  TimeZoneSidKey from User where
                  ID = :UserInfo.getUserId()];
        UserIsSpecial = u.UserIsSpecial__c;
        UserTimeZone = u.TimeZoneSidKey;
        UserCacheLoaded = true;
    }
    
}
