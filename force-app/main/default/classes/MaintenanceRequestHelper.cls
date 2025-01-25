public with sharing class MaintenanceRequestHelper {
    public static void updateWorkOrders(List<Case> mainReqs, Map<Id, Case> oldMainReqs) {
        Set<String> mainTypes = new Set<String>{
            'Routine Maintenance',
            'Repair'
        };
        Map<Id, Case> mainReqMap = new Map<Id, Case>();

        for (Case mainReq : mainReqs) {
            if (mainReq.Status == 'Closed'
                && oldMainReqs.get(mainReq.Id).Status != 'Closed'
                && mainTypes.contains(mainReq.Type)
            ) {
                mainReqMap.put(mainReq.Id, mainReq);
            }
        }

        if (!mainReqMap.isEmpty()) {
            Map<Id, Integer> minCycle = new Map<Id, Integer>();

            for (AggregateResult aggResult : [
                SELECT Maintenance_Request__c, MIN(Equipment__r.Maintenance_Cycle__c) cycle
                FROM Equipment_Maintenance_Item__c
                WHERE Maintenance_Request__c IN :mainReqMap.keySet()
                GROUP BY Maintenance_Request__c
            ]) {
                minCycle.put(
                    (Id) aggResult.get('Maintenance_Request__c'),
                    aggResult.get('cycle') != null
                        ? ((Decimal) aggResult.get('cycle')).intValue()
                        : 0
                );
            }

            Map<Id, List<Equipment_Maintenance_Item__c>> equipMainItemsMap = new Map<Id, List<Equipment_Maintenance_Item__c>>();

            for (Equipment_Maintenance_Item__c equipMainItem : [
                SELECT Id, Equipment__c, Maintenance_Request__c, Quantity__c
                FROM Equipment_Maintenance_Item__c
                WHERE Maintenance_Request__c IN :mainReqMap.keySet()
            ]) {
                Id mainReqId = equipMainItem.Maintenance_Request__c;
                if (!equipMainItemsMap.containsKey(mainReqId)) {
                    equipMainItemsMap.put(mainReqId, new List<Equipment_Maintenance_Item__c>());
                }

                equipMainItemsMap.get(mainReqId).add(equipMainItem);
            }

            List<Case> mainReqForInsert = new List<Case>();

            for (Id mainReq : mainReqMap.keySet()) {
                Case currentMainReq = mainReqMap.get(mainReq);

                Case newMainReq = new Case(
                    Status = 'New',
                    Origin = 'Web',
                    Type = 'Routine Maintenance',
                    Subject = 'Routine Maintenance',
                    Vehicle__c = currentMainReq.Vehicle__c,
                    Date_Due__c = minCycle.get(mainReq) != 0 ? Date.today().addDays(minCycle.get(mainReq)) : null,
                    Date_Reported__c = Date.today(),
                    ParentId = mainReq
                );

                mainReqForInsert.add(newMainReq);
            }

            insert mainReqForInsert;

            List<Equipment_Maintenance_Item__c> newEquipMainItems = new List<Equipment_Maintenance_Item__c>();

            for (Case newMainReq : mainReqForInsert) {
                List<Equipment_Maintenance_Item__c> oldEquipMainItems = equipMainItemsMap.get(newMainReq.ParentId);

                if (!oldEquipMainItems.isEmpty()) {
                    for (Equipment_Maintenance_Item__c currentEquipMainItem : oldEquipMainItems) {
                        Equipment_Maintenance_Item__c newEquipMainItem = currentEquipMainItem.clone();
                        newEquipMainItem.Maintenance_Request__c = newMainReq.Id;
                        newEquipMainItems.add(newEquipMainItem);
                    }
                }
            }

            if (!newEquipMainItems.isEmpty()) {
                insert newEquipMainItems;
            }
        }
    }
}