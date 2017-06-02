public class ThinkingInApex {
  
  private static Boolean IsUserSpecialChecked = false;
  
  private static Boolean UserIsSpecial = false;
  
  public static Boolean IsUserSpecial()
  {
      if(IsUserSpecialChecked) return UserIsSpecial;
    
      User u = [SELECT UserIsSpecial__c 
