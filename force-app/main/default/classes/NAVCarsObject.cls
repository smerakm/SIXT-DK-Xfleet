public with sharing class NAVCarsObject {
    
    public String Vin_No {get;set;} // that is how the parameter is named in NAV API 
    public String regNo {get;set;}
    public String vatType {get;set;}

    public NAVCarsObject(String vinNo, String regNo, String vatType) {
        this.Vin_No = vinNo;
        this.regNo = regNo;
        this.vatType = vatType;
    }
}
