/*************************************************************************************************
 * Class            : WoonstadSupplierService
 * Layer            : Service
 * Purpose          : Resolve supplier API name, display name, and email with overrides + fallback.
 *
 * Notes            :
 *  - Never default the API name to a display label.
 *  - Weijntjes fields are ONLY populated when Weijntjes is the selected supplier.
 *
 * Owner            : Woonstad
 * Author           : Dennis van Musschenbroek
 * Created          : 2025-08-25
 * Last Modified    : 2025-08-25
 * ===============================================================================================
 * Change Log
 * ===============================================================================================
 * 2025-08-25 | DvM | Weijntjes fields only when Weijntjes selected; no fallback API names.
 *************************************************************************************************/
public with sharing class WoonstadSupplierService {

    public class SupplierContext {
        public String apiName;           // picklist API value for Request__c.Supplier_Name_Plate__c
        public String name;             // display name for email / output
        public String email;            // supplier email for sending

        // Weijntjes display defaults (only if Weijntjes selected)
        public String weijntjesApiName;
        public String weijntjesName;
        public String weijntjesEmail;
    }

    public static SupplierContext resolveSupplier(Id accountId, String overrideName, String overrideEmail) {
        SupplierContext out = new SupplierContext();

        // Retrieve first supplier from RealEstateSupplierFlowController
        RealEstateSupplierFlowController.SupplierWrapper sw =
            RealEstateSupplierFlowController.getFirstSupplier(accountId);

        // API name: ONLY from wrapper (never fallback to a label)
        out.apiName = (sw != null) ? sw.supplierApiName : null;

        // Preferred display values: allow overrides, else wrapper values
        out.name  = !String.isBlank(overrideName)  ? overrideName  : ((sw != null) ? sw.supplierName  : null);
        out.email = !String.isBlank(overrideEmail) ? overrideEmail : ((sw != null) ? sw.supplierEmail : null);

        // Weijntjes fields: ONLY if apiName matches Weijntjes API name from wrapper
        String wijApi = (sw != null) ? sw.weijntjesApiName : null;
        if (wijApi != null && out.apiName != null && out.apiName == wijApi) {
            out.weijntjesApiName = wijApi;
            out.weijntjesName    = (sw != null) ? sw.weijntjesName  : null;
            out.weijntjesEmail   = (sw != null) ? sw.weijntjesEmail : null;
        } else {
            out.weijntjesApiName = null;
            out.weijntjesName    = null;
            out.weijntjesEmail   = null;
        }

        return out;
    }
}