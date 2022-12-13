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
        this.vatType = vatType;
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
}
