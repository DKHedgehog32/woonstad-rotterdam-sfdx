/**
 * Created by harm on 23/08/2024.
 */

global class OkapiResponseModel {
    @AuraEnabled @InvocableVariable
    global Boolean isSuccess;
    @AuraEnabled @InvocableVariable
    global List<String> errors;

}