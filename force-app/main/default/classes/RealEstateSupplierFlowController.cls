/**
 * =============================================
 * RealEstateSupplierFlowController
 * =============================================
 * Date: 2025-08-07
 * Last Changed: 2025-08-07
 * Description:
 * - Provides supplier information for a given Account.
 * - getFirstSupplier (AuraEnabled) for LWC use.
 * - invocableGetFirstSupplier (InvocableMethod) for Flow Apex Action use.
 * - Null-safe defaults; clear "Geen leverancier gevonden" when no match.
 * =============================================
 */
public with sharing class RealEstateSupplierFlowController {

    // -----------------------------
    // LWC-friendly (AuraEnabled)
    // -----------------------------
    @AuraEnabled(cacheable=true)
    public static SupplierWrapper getFirstSupplier(Id accountId) {
        SupplierResult r = resolveSupplier(accountId);
        return new SupplierWrapper(
            r.accountId,
            r.klantNaam,
            r.eigenaar,
            r.supplierApiName,
            r.supplierName,
            r.supplierEmail,
            r.fullStreet,
            r.postalCode,
            r.city,
            r.weijntjesApiName,
            r.weijntjesName,
            r.weijntjesEmail
        );
    }

    // -----------------------------
    // Flow-friendly (Invocable)
    // -----------------------------
    public class FlowInput {
        @InvocableVariable(required=true)
        public Id accountId;
    }

    public class FlowOutput {
        @InvocableVariable public Id accountId;
        @InvocableVariable public String klantNaam;
        @InvocableVariable public String eigenaar;
        @InvocableVariable public String supplierApiName;
        @InvocableVariable public String supplierName;
        @InvocableVariable public String supplierEmail;
        @InvocableVariable public String fullStreet;
        @InvocableVariable public String postalCode;
        @InvocableVariable public String city;

        // Also expose Weijntjes for downstream logic if needed
        @InvocableVariable public String weijntjesApiName;
        @InvocableVariable public String weijntjesName;
        @InvocableVariable public String weijntjesEmail;
    }

    /**
     * Invocable method for Flow Apex Action:
     * - Accepts a list of inputs (Flow contract)
     * - Returns a list of outputs
     */
    @InvocableMethod(label='Get First Supplier For Account' description='Returns preferred supplier info for an Account')
    public static List<FlowOutput> invocableGetFirstSupplier(List<FlowInput> inputs) {
        List<FlowOutput> out = new List<FlowOutput>();
        if (inputs == null) return out;

        for (FlowInput i : inputs) {
            SupplierResult r = resolveSupplier(i != null ? i.accountId : null);
            FlowOutput fo = new FlowOutput();
            fo.accountId        = r.accountId;
            fo.klantNaam        = r.klantNaam;
            fo.eigenaar         = r.eigenaar;
            fo.supplierApiName  = r.supplierApiName;
            fo.supplierName     = r.supplierName;
            fo.supplierEmail    = r.supplierEmail;
            fo.fullStreet       = r.fullStreet;
            fo.postalCode       = r.postalCode;
            fo.city             = r.city;
            fo.weijntjesApiName = r.weijntjesApiName;
            fo.weijntjesName    = r.weijntjesName;
            fo.weijntjesEmail   = r.weijntjesEmail;
            out.add(fo);
        }
        return out;
    }

    // -----------------------------
    // Shared resolver + DTOs
    // -----------------------------
    private class SupplierResult {
        public Id accountId;
        public String klantNaam;
        public String eigenaar;
        public String supplierApiName;
        public String supplierName;
        public String supplierEmail;
        public String fullStreet;
        public String postalCode;
        public String city;

        public String weijntjesApiName;
        public String weijntjesName;
        public String weijntjesEmail;
    }

    private static SupplierResult resolveSupplier(Id accountId) {
        SupplierResult r = new SupplierResult();

        // Static defaults for Weijntjes
        r.weijntjesApiName = 'Weijntjes Hang- En Sluitwerk';
        r.weijntjesName    = 'Weijntjes Hang- En Sluitwerk';
        r.weijntjesEmail   = 'dennis.kristoffers@cobracrm.nl';

        if (accountId == null) {
            // When no account is provided, give a clear "no supplier"
            r.supplierApiName = null;
            r.supplierName    = 'Geen leverancier gevonden';
            r.supplierEmail   = null;
            return r;
        }

        Account acc = [
            SELECT Id, Name, Full_Shipping_Street__c,
                   Full_Shipping_Postal_Code__c, Full_Shipping_City__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
        r.accountId  = acc.Id;
        r.klantNaam  = acc.Name;
        r.fullStreet = acc.Full_Shipping_Street__c;
        r.postalCode = acc.Full_Shipping_Postal_Code__c;
        r.city       = acc.Full_Shipping_City__c;

        // First active Contract Contact Role
        List<Contract_Contact_Role__c> roles = [
            SELECT Id,
                   Real_Estate_Contract__r.Contract_Party__r.Name,
                   Real_Estate_Contract__r.Contract_Party__c
            FROM Contract_Contact_Role__c
            WHERE Active__c = true
              AND Contact_Account__c = :accountId
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        String eigenaar = (roles.isEmpty() || roles[0].Real_Estate_Contract__r == null)
            ? null
            : roles[0].Real_Estate_Contract__r.Contract_Party__r.Name;
        r.eigenaar = eigenaar;

        // Map eigenaar → supplier, with safe fallback
        if (String.isNotBlank(eigenaar)) {
            if (eigenaar.containsIgnoreCase('Noord') || eigenaar.containsIgnoreCase('Oost')) {
                r.supplierApiName = 'Kellers IJzerhandel B.V.';
                r.supplierName    = 'Keller\'s IJzerhandel B.V.';
                r.supplierEmail   = 'denniskristoffers@icloud.com';
            } else if (eigenaar.containsIgnoreCase('Zuid')) {
                r.supplierApiName = 'Het Zuider Sleutelhuis B.V.';
                r.supplierName    = 'Het Zuider Sleutelhuis B.V.';
                r.supplierEmail   = 'denniskristoffers@gmail.com';
            } else if (eigenaar.containsIgnoreCase('Centrum') || eigenaar.containsIgnoreCase('West')) {
                r.supplierApiName = 'IJzerhandel Overschie';
                r.supplierName    = 'IJzerhandel Overschie';
                r.supplierEmail   = 'denniskristoffers@icloud.com';
            }
        }

        // If nothing resolved, either signal "Geen leverancier gevonden"
        // (so the Flow/LWC can block Next), or fall back to Weijntjes.
        // Choose ONE strategy. Here I return "Geen leverancier gevonden".
        if (String.isBlank(r.supplierName)) {
            r.supplierApiName = null;
            r.supplierName    = 'Geen leverancier gevonden';
            r.supplierEmail   = null;
        }

        return r;
    }

    // LWC-friendly wrapper (AuraEnabled)
    public class SupplierWrapper {
        @AuraEnabled public Id accountId;
        @AuraEnabled public String klantNaam;
        @AuraEnabled public String eigenaar;
        @AuraEnabled public String supplierApiName;
        @AuraEnabled public String supplierName;
        @AuraEnabled public String supplierEmail;
        @AuraEnabled public String fullStreet;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String city;

        @AuraEnabled public String weijntjesApiName;
        @AuraEnabled public String weijntjesName;
        @AuraEnabled public String weijntjesEmail;

        public SupplierWrapper(
            Id accountId, String klantNaam, String eigenaar,
            String supplierApiName, String supplierName, String supplierEmail,
            String fullStreet, String postalCode, String city,
            String weijntjesApiName, String weijntjesName, String weijntjesEmail
        ) {
            this.accountId = accountId;
            this.klantNaam = klantNaam;
            this.eigenaar = eigenaar;
            this.supplierApiName = supplierApiName;
            this.supplierName = supplierName;
            this.supplierEmail = supplierEmail;
            this.fullStreet = fullStreet;
            this.postalCode = postalCode;
            this.city = city;
            this.weijntjesApiName = weijntjesApiName;
            this.weijntjesName = weijntjesName;
            this.weijntjesEmail = weijntjesEmail;
        }
    }
}