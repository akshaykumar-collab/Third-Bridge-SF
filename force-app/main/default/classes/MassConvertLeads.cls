public class MassConvertLeads {
    @InvocableMethod(label='Mass Convert Campaign Member Leads' description='Given a list of Campaign Member IDs, convert their associated Leads to Contacts')
    public static void massConvertLeads(List<String> input) {
        System.debug(input);
        List<String> parameters = input[0].split(',');
        BatchConvertLeads leadBatch = new BatchConvertLeads(parameters[0], parameters[1]);
        Id batchId = Database.executeBatch(leadBatch, 20);
    }
}