/** Enforce that every opportunity is created with an OpportunityContactRole 
**/

trigger OnOpportunity on Opportunity (before insert) {
    Think
