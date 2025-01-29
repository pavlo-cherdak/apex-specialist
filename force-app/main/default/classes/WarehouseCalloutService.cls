public with sharing class WarehouseCalloutService implements Queueable, Database.AllowsCallouts {

    private static final String WAREHOUSE_URL = 'https://th-superbadge-apex.herokuapp.com/equipment';

    public void execute(QueueableContext context) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(WAREHOUSE_URL);
        request.setMethod('GET');
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            List<Object> equipments_response = (List<Object>) JSON.deserializeUntyped(response.getBody());
            List<Product2> equipmentsToUpsert = new List<Product2>();

            for (Object rawEquipment : equipments_response) {
                Map<String, Object> equipment = (Map<String, Object>) rawEquipment;
                Product2 newEquipment = new Product2();

                newEquipment.Replacement_Part__c = (Boolean) equipment.get('replacement');
                newEquipment.Name = (String) equipment.get('name');
                newEquipment.Maintenance_Cycle__c = (Decimal) equipment.get('maintenanceperiod');
                newEquipment.Lifespan_Months__c = (Decimal) equipment.get('lifespan');
                newEquipment.Cost__c = (Decimal) equipment.get('cost');
                newEquipment.Warehouse_SKU__c = (String) equipment.get('sku');
                newEquipment.Current_Inventory__c = (Decimal) equipment.get('quantity');

                equipmentsToUpsert.add(newEquipment);
            }

            if (!equipmentsToUpsert.isEmpty()) {
                upsert equipmentsToUpsert Product2.Fields.Warehouse_SKU__c;
            }
        }
    }
}