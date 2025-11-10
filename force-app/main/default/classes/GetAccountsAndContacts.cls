global with sharing class GetAccountsAndContacts implements System.Callable {
    public Boolean call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');
        return invokeMethod(action, input, output, options);
    }

    public Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options){
        try {
            String firstName = options.get('firstName').toString();
            String lastName = options.get('lastName').toString();
            String city = options.get('city').toString();
            System.debug('options: ' + options.toString());
            System.debug('input: ' + input.toString());
            System.debug('firstName: ' + firstName);
            System.debug('lastName: ' + lastName);
            System.debug('city: ' + city);
            String condition = null;
            List<sObject> data = new List<sObject>();

            if(!(String.isEmpty(firstName) && String.isEmpty(lastName) && String.isEmpty(city))) {
                if(!String.isEmpty(firstName)) {
                    condition = 'FirstName like \'%' + firstName + '%\'';
                }
                if(!String.isEmpty(lastName)) {
                    if(!String.isEmpty(condition)) {
                        condition = condition + ' AND LastName like \'%' + lastName + '%\'';
                    } else {
                        condition = 'LastName like \'%' + lastName + '%\'';
                    }
                }

                String accountCondition = condition;
                if(!String.isEmpty(city)) {
                    if(!String.isEmpty(accountCondition)) {
                        accountCondition = accountCondition + ' AND ShippingCity like \'%' + city + '%\'';
                    } else {
                        accountCondition = 'ShippingCity like \'%' + city + '%\'';
                    }
                }

                String getAccountsSoql = 'SELECT firstname, name, id, shippingcity, shippingaddress, lastname FROM Account WHERE ' + accountCondition + ' AND IsPersonAccount = true LIMIT 50000';
                System.debug('getAccountsSoql: ' + getAccountsSoql);
                List<sObject> accountSobjList = Database.query(getAccountsSoql);
                System.debug(accountSobjList.size() + ' account(s) returned.');

                String contactCondition = condition;
                if(!String.isEmpty(city)) {
                    if(!String.isEmpty(contactCondition)) {
                        contactCondition = contactCondition + ' AND MailingCity like \'%' + city + '%\'';
                    } else {
                        contactCondition = 'MailingCity like \'%' + city + '%\'';
                    }
                }

                String getContactsSoql = 'SELECT firstname, name, id, mailingcity, mailingaddress, lastname FROM Contact WHERE ' + contactCondition + ' AND IsPersonAccount = false LIMIT 50000';
                System.debug('getContactsSoql: ' + getContactsSoql);
                List<sObject> contactSobjList = Database.query(getContactsSoql);
                System.debug(contactSobjList.size() + ' contact(s) returned.');

                data.addAll(accountSobjList);
                data.addAll(contactSobjList);            
            }

            if(data.size() == 0) {
                output.put('data',new Map<String,String>());
            } else {
                output.put('data',data);
            }

            return true;
        } catch (Exception e) {
            ApexFaultHandler.publishError(e, 'GetAccountsAndContacts', 'invokeMethod');
            return false;
        }
    }
}