//
// Holds the model for contact data, used to (de)serialize in integrations and use in flows
global class ContactGegevensModel {
    @AuraEnabled @InvocableVariable
    global String email;
    @AuraEnabled @InvocableVariable
    global String telefoonVast;
    @AuraEnabled @InvocableVariable
    global String telefoonMobiel;
    @AuraEnabled @InvocableVariable
    global String telefoonVoorkeur; // Enum: Vast/Mobiel

    public static ContactGegevensModel getMock() {
        ContactGegevensModel model = new ContactGegevensModel();
        model.email = 'mock@mail.com';
        model.telefoonVast = '0581234123';
        model.telefoonMobiel = '0612341234';
        model.telefoonVoorkeur = 'Mobiel';
        return model;
    }
}