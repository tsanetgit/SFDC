global class TSANetScheduledJob implements Schedulable, Database.AllowsCallouts {
    
    public class TSANetScheduledJobException extends Exception {}

    global void execute(SchedulableContext sc){
        try {
            Id jobId = System.enqueueJob(new TSANetQueueableJob(0, null, null, null, null));
			System.debug('jobId : ' + jobId);
        } catch(Exception e){
            System.debug(e.getMessage());
        }
    }
}