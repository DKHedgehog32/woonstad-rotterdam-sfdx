//
// Batch class to update records in bulk with a "fake" update
// Query should include a field that stops the query from returning records
// E.g. UpdateAddressesBatch.startBatch('SELECT Id FROM Address__c WHERE Correction__c=false LIMIT 10000');
public class UpdateAddressesBatch implements Database.Batchable<SObject> {
    private static final Integer maxRuns = 350; // Max handles 350 x 200 = 70.000 records
    public Integer currentRun = 0;
    public String query;
    public static void startBatch(String query) {
        if(String.isEmpty(query)) {
            throw new DeleteBatchException();
        }
        startBatch(query, 0);
    }

    private static void startBatch(String query, Integer count) {

        UpdateAddressesBatch db = new UpdateAddressesBatch();
        db.currentRun = count;
        db.query = query;
        Database.executeBatch(db);
    }
    public Database.QueryLocator start(Database.BatchableContext bc){

        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope){
        try {
            for(SObject s : scope) {
                s.put('Correction__c', true);
            }
            Database.update(scope, false);
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'UpdateAddressesBatch' ,'execute');
        }
    }

    public void finish(Database.BatchableContext bc){
        try {
            if(maxRuns <= this.currentRun) {
                return; // Quit
            }
            if(!Test.isRunningTest() && Database.query(this.query)?.size() > 0) {
                startBatch(this.query, this.currentRun++);
            }
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'UpdateAddressesBatch' ,'finish');
        }
    }
    public class DeleteBatchException extends Exception {

    }
}