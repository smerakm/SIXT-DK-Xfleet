/**
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┐
 * Common utilities class.
 * Utilities:
 *  - string merge fields
 *
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         Marek Smerak      <marek.smerak@wipro.com>
 * @modifiedBy     Marek Smerak      <marek.smerak@wipro.com>
 * @version        1.0
 * @created        2023-04-03
 * @modified       2022-04-03
 * @systemLayer    Utility
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v1.0            marek.smerak@wipro.com
 * 2022-04-03      initial version
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
public inherited sharing class UtilityCommon {
    public static final String MERGE_FIELD_SEPARATOR_OPEN = '{{';
    public static final String MERGE_FIELD_SEPARATOR_CLOSE = '}}';

    /* Method to replace substrings in the string with values from fields of the object
     * similar how merge fields works in email template
     * theLabel = original string
     * obj = object that was queried with required field
     * openBracket = open (left) separator for a merge field, e.g. {{
     * closeBracket = close (right) separator for a merge field, e.g. }}
     *
     * returns string where fields from the obj was merget into theLabel
     */
    public static String mergeFieldsIntoString(String inputLabel, SObject obj, String openBracket, String closeBracket) {
        String theLabel = inputLabel;
        // check if there are any merge fields
        while (theLabel.contains(openBracket) && theLabel.contains(closeBracket)) {
            // get the field name
            String fieldNameWhole = theLabel.substringBetween(openBracket, closeBracket);
            String fieldName = fieldNameWhole;

            System.debug('fieldName: ' + fieldName);

            String fieldValue = '';
            SObject o = obj;

            // check if the field is from related object
            while (fieldName.contains('.')) {
                String objectName = fieldName.substringBefore('.');
                fieldName = fieldName.substringAfter('.');
                System.debug('temp field: ' + fieldName);
                System.debug('the object: ' + objectName);
                o = o.getSobject(objectName);
            }
            // get the field value (as String)
            if (o != null && fieldName != null) {
                fieldValue = (String) o.get(fieldName);
            }
            // replace / merge it into the label
            theLabel = theLabel.replace(openBracket + fieldNameWhole + closeBracket, fieldValue);

            System.debug('the new label: ' + theLabel);
        }
        return theLabel;
    }

    /* Method to replace substrings in the string with values from fields of the object
     * similar how merge fields works in email template
     * - using default sepators {{...}}
     *
     * theLabel = original string
     * obj = object that was queried with required field
     *
     * returns string where fields from the obj was merget into theLabel
     */
    public static String mergeFieldsIntoString(String inputLabel, SObject obj) {
        return mergeFieldsIntoString(inputLabel, obj, MERGE_FIELD_SEPARATOR_OPEN, MERGE_FIELD_SEPARATOR_CLOSE);
    }
}