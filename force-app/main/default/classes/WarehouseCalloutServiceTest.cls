@IsTest
private class WarehouseCalloutServiceTest {
    // implement your mock callout test here
    @IsTest static void testWarehouseCalloutService() {
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        WarehouseCalloutService upserter = new WarehouseCalloutService();

        Test.startTest();
        System.enqueueJob(new WarehouseCalloutService());
        Test.stopTest();

        List<Product2> equipments = [SELECT Id, Warehouse_SKU__c FROM Product2];

        Assert.isTrue(equipments.size() == 1);
        Assert.areEqual(
                '100003',
                equipments[0].Warehouse_SKU__c,
                'Should be created equipment with this sku'
        );
    }

}