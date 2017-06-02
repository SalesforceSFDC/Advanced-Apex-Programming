User u = [SELECT UserIsSpecial__c FROM
            User WHERE ID = :UserInfo.getUserId()];
Boolean UserIsSpecial = u.UserIsSpecial__c;
