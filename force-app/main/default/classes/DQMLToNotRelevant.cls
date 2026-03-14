public class DQMLToNotRelevant {

    @InvocableMethod(label='DQ ML to Not Relevant' description='Move all Leads in the Marketing Leads queue with a Status of Disqualified  to Prospects not Relevant queue')
    public static void dqMLtoNotRelevant() {
        BatchLeadMLToNotRelevant leadBatch = new BatchLeadMLToNotRelevant();
        Id batchId = Database.executeBatch(leadBatch, 50);
    }

}