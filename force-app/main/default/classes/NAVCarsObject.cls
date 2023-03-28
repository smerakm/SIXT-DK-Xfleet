public with sharing class NAVCarsObject {
    public String Vin_No { get; set; } // that is how the parameter is named in NAV API
    public String regNo { get; set; }
    public String vatType { get; set; }
    public Datetime createdAt { get; set; }
    public Datetime modifiedAt { get; set; }
    public Boolean isPaid { get; set; }
    public Decimal createUnitPrice { get; set; }
    public String creatExtDocNo { get; set; }
    public String createInvoice { get; set; } // Account NAV number for invoice
    public String createQuote { get; set; } // Account NAV number for advi
    public Integer createQuantity { get; set; }
    public Boolean createAddToDoc { get; set; } // shall be false, business decision, keep it available in code
    public String createPickupAddr { get; set; } // pickup address for invoice
    public String description { get; set; }
    public Integer km { get; set; }
    public Boolean createAlternativeAccount {get; set;} // an optional parameter and when set to true uses the alternative account (210850)

    // constructor used for Create or Update car
    public NAVCarsObject(String vinNo, String regNo, String vatType, String description, Integer km) {
        this.Vin_No = vinNo;
        this.regNo = regNo;
        this.vatType = convertToNAVVatType(vatType);
        this.description = description?.left(50);
        this.km = km;
    }

    // constructor used for Invoice or Advi (default createAlternativeAccount as False)
    public NAVCarsObject(Decimal amount, String createExtDocNo, String createInvoice, String createQuote, Integer createQuantity, Boolean createAddToDoc, String description, Integer km, String pickupLocation) {
        this(amount, createExtDocNo, createInvoice, createQuote, createQuantity, createAddToDoc, description, km, pickupLocation, false);
    }

    // constructor used for Invoice or Advi
    public NAVCarsObject(Decimal amount, String createExtDocNo, String createInvoice, String createQuote, Integer createQuantity, Boolean createAddToDoc, String description, Integer km, String pickupLocation, Boolean useAlternativeAccount) {
        this.createUnitPrice = amount;
        this.creatExtDocNo = createExtDocNo;
        this.createInvoice = createInvoice;
        this.createQuote = createQuote;
        this.createAddToDoc = createAddToDoc;
        this.createQuantity = createQuantity;
        this.km = km;
        this.description = description?.left(50);
        this.createPickupAddr = pickupLocation?.left(50);
        this.createAlternativeAccount = useAlternativeAccount;
    }

    public String convertToNAVVatType() {
        return convertToNAVVatType(this.vatType);
    }

    public String convertToNAVVatType(String vatTypeXfleet) {
        if (vatTypeXfleet == null) {
            return null;
        } else if (vatTypeXfleet.equalsIgnoreCase('DK - L94')) {
            return 'L94';
        } else if (vatTypeXfleet.equalsIgnoreCase('Valuta')) {
            return 'VALUTA';
        } else if (vatTypeXfleet.equalsIgnoreCase('DK - Full tax')) {
            return 'FULD MOMS';
        } else if (vatTypeXfleet.equalsIgnoreCase('DK - Tax type not determined')) {
            return null;
        } else {
            // do not convert (in case already converted)
            return vatTypeXfleet;
        }
    }
}