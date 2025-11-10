public with sharing class InvocableUUID {
    @InvocableMethod(Description='Generate a unique UUID'  Label='Get UUID String')
    public static List<String> generateUuid(List<String> recordIds) {
        List<String> output = new List<String>();

        //
        // Needs some kind of list as input to generate the same nr of outputs (and in the same order) so the flow can
        // deal with the response. Id has no specific role in the UUID generation, so casting it as strings
        for(String recId : recordIds) {
            String uuidValue = IdentifierService.getUUID();
            output.add(uuidValue);
        }
        return output;
    }
}