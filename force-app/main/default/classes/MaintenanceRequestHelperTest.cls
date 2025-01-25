@IsTest
public with sharing class MaintenanceRequestHelperTest {
    @TestSetup static void setup() {
        Vehicle__c newVehicle = new Vehicle__c(Name = 'Passat B6');
        insert newVehicle;

        Product2 newEquipment = new Product2(Name = 'TNVD', Cost__c = 225, Maintenance_Cycle__c = 10, Lifespan_Months__c = 10, Replacement_Part__c = true);
        insert newEquipment;

        Case newMainReq = new Case(
            Status = 'New',
            Origin = 'Web',
            Type = 'Repair',
            Subject = 'passat b6 test',
            Vehicle__c = newVehicle.Id,
            Date_Reported__c = Date.today()
        );
        insert newMainReq;

        Equipment_Maintenance_Item__c newEquipMainItem = new Equipment_Maintenance_Item__c(
            Maintenance_Request__c = newMainReq.Id,
            Equipment__c = newEquipment.Id
        );
        insert newEquipMainItem;
    }

    @IsTest static void testMaintenanceRequestHelperSuccess() {
        Case mainReq = [SELECT Id FROM Case WHERE Subject = 'passat b6 test' LIMIT 1];

        mainReq.Status = 'Closed';

        Test.startTest();
        update mainReq;
        Test.stopTest();

        Case newMainReq = [SELECT Id, Subject, Date_Due__c FROM Case WHERE Subject != 'passat b6 test' LIMIT 1];
        List<Equipment_Maintenance_Item__c> equipMainItems = [SELECT Id FROM Equipment_Maintenance_Item__c];
        Assert.isTrue(newMainReq.Subject == 'Routine Maintenance', 'Subject should be "Routine Maintenance"');
        Assert.areEqual(
            Date.today().addDays(10),
            newMainReq.Date_Due__c,
            'Due date should be +10 days from today, current:' + newMainReq.Date_Due__c
        );
        Assert.areEqual(equipMainItems.size(), 2, 'Should be 2 Equipment_Maintenance_Item__c');
    }

    @IsTest static void testMaintenanceRequestHelperWithoutCycle() {
        Product2 equipment = [SELECT Id FROM Product2];
        Case mainReq = [SELECT Id FROM Case WHERE Subject = 'passat b6 test' LIMIT 1];

        mainReq.Status = 'Closed';
        delete equipment;

        Test.startTest();
        update mainReq;
        Test.stopTest();

        Case newMainReq = [SELECT Id, Subject, Date_Due__c FROM Case WHERE Subject != 'passat b6 test' LIMIT 1];
        Assert.areEqual(
            null,
            newMainReq.Date_Due__c,
            'Due date should be null, current:' + newMainReq.Date_Due__c
        );
    }

    @IsTest static void testMaintenanceRequestHelperWithOtherStatus() {
        Case mainReq = [SELECT Id FROM Case WHERE Subject = 'passat b6 test' LIMIT 1];

        mainReq.Status = 'Working';

        Test.startTest();
        update mainReq;
        Test.stopTest();

        List<Case> newMainReq = [SELECT Id, Subject, Date_Due__c FROM Case WHERE Subject != 'passat b6 test'];
        Assert.isTrue(newMainReq.size() == 0, 'Should be 0 cases created');
    }
}