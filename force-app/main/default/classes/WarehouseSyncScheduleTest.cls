@IsTest
public with sharing class WarehouseSyncScheduleTest {
    @IsTest static void testWarehouseSyncSchedule() {
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        String cronExp = '0 0 * * * ?'; // Виконується щогодини

        Test.startTest();
        String jobID = System.schedule('Testjob', cronExp, new WarehouseSyncSchedule());

        List<Product2> equipmentsBefore = [SELECT Id, Warehouse_SKU__c FROM Product2];
        Assert.isTrue(equipmentsBefore.size() == 0);
        Test.stopTest();

        CronTrigger scheduledJob = [
                SELECT Id, State, NextFireTime, PreviousFireTime, CronJobDetail.Name
                FROM CronTrigger
                WHERE Id = :jobID
        ];

        Assert.areEqual('WAITING', scheduledJob.State);
        Assert.areEqual('Testjob', scheduledJob.CronJobDetail.Name);
    }
}