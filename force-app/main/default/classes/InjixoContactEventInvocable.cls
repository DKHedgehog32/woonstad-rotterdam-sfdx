public with sharing class InjixoContactEventInvocable {
    @InvocableMethod(label='Injixo Contact Event' description='Sends the contact event to Injixo')
    public static void sendContactEvents(List<List<InjixoContactEventModel>> events) {
        List<InjixoContactEventModel> allEvents = new List<InjixoContactEventModel>();
        for(List<InjixoContactEventModel> oneList : events) {
            allEvents.addAll(oneList);
        }
        sendEventsFuture(JSON.serialize(allEvents));
    }
    @Future(callout=true) @TestVisible
    private static void sendEventsFuture(String eventJson) {
        List<InjixoContactEventModel> events = (List<InjixoContactEventModel>) JSON.deserialize(eventJson, List<InjixoContactEventModel>.class);
        InjixoClient.sendContactEventRequest(events);
    }
}