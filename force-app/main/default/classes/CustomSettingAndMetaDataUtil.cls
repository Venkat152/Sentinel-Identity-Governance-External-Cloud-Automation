/**
 * @description       : Utility class for custom settings and custom metadata
 * @author            : Nitish Kumar
 * @last modified on  : 03-31-2026
**/
public with sharing class CustomSettingAndMetaDataUtil {
    
    /**
     * Fetches the Governance Metadata record. 
     * Using 'Default_Settings' as the developer name.
     */
    public static Governance_Config__mdt getGovernanceConfig() {
        return Governance_Config__mdt.getInstance('Default_Settings');
    }

    /**
     * Parses the comma-separated profiles from metadata into a Set
     */
    public static Set<String> getTargetProfileNamesFromMetadata() {
        Governance_Config__mdt config = getGovernanceConfig();
        Set<String> profileSet = new Set<String>();
        if (config != null && String.isNotBlank(config.Target_Profiles__c)) {
            for (String profile : config.Target_Profiles__c.split(',')) {
                profileSet.add(profile.trim());
            }
        }
        return profileSet;
    }
}