global class GetObjectCheckboxes extends VisualEditor.DynamicPickList{
    VisualEditor.DesignTimePageContext context;
    VisualEditor.DataRow defaultValue;

    global GetObjectCheckboxes(VisualEditor.DesignTimePageContext context) {
       this.context = context;
    }
    
    global override VisualEditor.DataRow getDefaultValue(){
        return null;
    }

    global override VisualEditor.DynamicPickListRows getValues() {
        String objectName = context.entityName;
        Map<String, SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        VisualEditor.DynamicPickListRows  myValues = new VisualEditor.DynamicPickListRows();

        for (String fieldName : fieldMap.keySet()) {
            DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
            // checking to see if the field is custom to make sure it's not a system read-only field
            if (fieldDescribe.getType() == Schema.DisplayType.Boolean && fieldDescribe.isCustom()) {
                VisualEditor.DataRow newVal = new VisualEditor.DataRow(fieldDescribe.getLabel(), fieldName);
                myValues.addRow(newVal);
            }
        }
        
        return myValues;
    }
}