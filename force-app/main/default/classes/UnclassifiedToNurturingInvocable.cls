public class UnclassifiedToNurturingInvocable {

    @InvocableMethod(label='New Unclassified to Nurturing' description='Move all Leads in the New Unclassified Leads queue with a Status of Open and Pardot Score < 100 to Prospects for Nurturing queue')
    public static void unclassifiedToNurturing() {
        BatchLeadUnclassifiedToNurturing leadBatch = new BatchLeadUnclassifiedToNurturing();
        Id batchId = Database.executeBatch(leadBatch, 50);
    }

    
}