/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * test for FixedRateLoanUtility class
 *
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         Marek Smerak      <marek.smerak@wipro.com>
 * @modifiedBy     Marek Smerak      <marek.smerak@wipro.com>
 * @version        1.0
 * @created        2022-10-28
 * @modified       2022-10-28
 * @systemLayer    Test
 * @see            SIXT-57
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v1.0            marek.smerak@wipro.com
 * 2022-10-28      initial version
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
@isTest
public with sharing class FixedRateLoanUtility_Test {
    @isTest
    public static void type1() {
        Double r = 0.025 / 12;
        Integer per = 6;
        Integer nper = 9;
        Double pv = 335258;
        Double fv = -305085;
        Integer algType = 1;
        Double pmt = -4015;

        System.assertEquals(-4015, Math.round(FixedRateLoanUtility.pmt(r, nper, pv, fv, algType)), 'PMT is not calculated correctly!');
        System.assertEquals(-315204, Math.round(FixedRateLoanUtility.fv(r, per, pmt, pv, algType)), 'FV is not calculated correctly!');
        System.assertEquals(-662, Math.round(FixedRateLoanUtility.ipmt(r, per, nper, pv, fv, algType)), 'IPMT is not calculated correctly!');
        System.assertEquals(-3353, Math.round(FixedRateLoanUtility.ppmt(r, per, nper, pv, fv, algType)), 'PPMT is not calculated correctly!');
        System.assertEquals(335260, Math.round(FixedRateLoanUtility.pv(r, nper, pmt, fv, algType)), 'PV is not calculated correctly!');

    }

    @isTest
    public static void type0() {
        Double r = 0.08 / 12;
        Integer per;
        Integer nper = 10;
        Double pv = 10000;
        Double fv = 0;
        Integer algType = 0;

        System.assertEquals(-1037, Math.round(FixedRateLoanUtility.pmt(r, nper, pv, fv, algType)), 'PMT is not calculated correctly!');

        r = 0.12 / 12;
        per = 12;
        Double pmt = -1000;

        System.assertEquals(12683, Math.round(FixedRateLoanUtility.fv(r, per, pmt, 0, algType)), 'FV is not calculated correctly!');

        r = 0.1;
        per = 1;
        nper = 3;
        pv = 8000;
        // monthly
        System.assertEquals(
            -67,
            Math.round(FixedRateLoanUtility.ipmt(Double.valueOf(r / 12), per, nper * 12, pv, 0, 0)),
            'monthly IPMT is not calculated correctly!'
        );
        // yearly
        per = 3;
        System.assertEquals(-292, Math.round(FixedRateLoanUtility.ipmt(Double.valueOf(r), per, nper, pv, 0, 0)), 'yearly IPMT is not calculated correctly!');

        r = 0.1;
        per = 1;
        nper = 2;
        pv = 2000;
        // monthly
        System.assertEquals(
            -76,
            Math.round(FixedRateLoanUtility.ppmt(Double.valueOf(r / 12), per, nper * 12, pv, 0, 0)),
            'monthly PPMT is not calculated correctly!'
        );
        // yearly
        r = 0.08;
        per = 10;
        nper = 10;
        pv = 200000;
        System.assertEquals(-27598, Math.round(FixedRateLoanUtility.ppmt(Double.valueOf(r), per, nper, pv, 0, 0)), 'yearly PPMT is not calculated correctly!');

        // pv
        pmt = 500; // get paid 500 every moth
        r = 0.08 / 12; // interest rate monthly
        nper = 20 * 12; // get paid for 20 years
        System.assertEquals(-59777, Math.round(FixedRateLoanUtility.pv(r, nper, pmt, 0, 0)), 'PV - present value is not calculated correctly - type 0!');
    }

    @isTest
    public static void overloads() {
        Double r = 0.025 / 12;
        Integer per = 6;
        Integer nper = 9;
        Double pv = 335258;
        Double fv = -305085;
        // PMT
        System.assertEquals(FixedRateLoanUtility.pmt(r, nper, pv, fv, 0), FixedRateLoanUtility.pmt(r, nper, pv, fv), 'PMT omiting type overload failed!');
        System.assertEquals(
            FixedRateLoanUtility.pmt(r, nper, pv, 0, 0),
            FixedRateLoanUtility.pmt(r, nper, pv),
            'PMT omiting future value and type overload failed!'
        );

        //FV
        System.assertEquals(FixedRateLoanUtility.fv(r, per, -4015, pv, 0), FixedRateLoanUtility.fv(r, per, -4015, pv), 'FV omiting type overload failed!');
        System.assertEquals(
            FixedRateLoanUtility.fv(r, per, -4015, 0, 0),
            FixedRateLoanUtility.fv(r, per, -4015),
            'FV omiting present value and type overload failed!'
        );
    }
}