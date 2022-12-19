public with sharing class NAVCarsObject {
    public String Vin_No { get; set; } // that is how the parameter is named in NAV API
    public String regNo { get; set; }
    public String vatType { get; set; }
    public Datetime createdAt { get; set; }
    public Datetime modifiedAt { get; set; }
    public Boolean carIsPaid { get; set; }
    public Decimal createUnitPrice { get; set; }
    public String creatExtDocNo { get; set; }
    public String createInvoice { get; set; } // Account NAV number for invoice
    public String createQuote { get; set; } // Account NAV number for advi
    public Integer createQuantity { get; set; }
    public Boolean createAddToDoc { get; set; }

    // constructor used for Create or Update car
    public NAVCarsObject(String vinNo, String regNo, String vatType) {
        this.Vin_No = vinNo;
        this.regNo = regNo;
        this.vatType = convertToNAVVatType(vatType);
    }

    // constructor used for Invoice or Advi
    public NAVCarsObject(Decimal amount, String createExtDocNo, String createInvoice, String createQuote, Integer createQuantity, Boolean createAddToDoc) {
        this.createUnitPrice = amount;
        this.creatExtDocNo = createExtDocNo;
        this.createInvoice = createInvoice;
        this.createQuote = createQuote;
        this.createAddToDoc = createAddToDoc;
        this.createQuantity = createQuantity;
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