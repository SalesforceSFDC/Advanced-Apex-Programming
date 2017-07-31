trigger LeadRoundRobinQueueFor18Digit on LeadRoundRobinQueue__c (before insert, before update) 
{

   Id sID;

   for(LeadRoundRobinQueue__c lrr : trigger.new) {
      sID = lrr.Standard_Queue_Id__c;
      lrr.Standard_Queue_Id__c = string.valueOf(sID);
   }
   
}