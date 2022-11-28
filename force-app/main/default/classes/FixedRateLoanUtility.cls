/**
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┐
 * Calculates Fixed Rate Loan / Mortgage payment, future value, ...
 * Use the same algorithm as MS Excel functions:
 * - PMT: payments
 * - FV: future value
 * - IPMT: interest portion of payment
 * - PPMT: principal portion of payment
 *
 * based on https://www.experts-exchange.com/articles/1948/A-Guide-to-the-PMT-FV-IPMT-and-PPMT-Functions.html
 *
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         Marek Smerak      <marek.smerak@wipro.com>
 * @modifiedBy     Marek Smerak      <marek.smerak@wipro.com>
 * @version        1.0
 * @created        2022-10-28
 * @modified       2022-10-28
 * @systemLayer    Utility
 * @see            SIXT-54
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v1.0            marek.smerak@wipro.com
 * 2022-10-28      initial version
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */

public with sharing class FixedRateLoanUtility {
    /**
     * Emulates Excel/Calc's PMT(interest_rate, number_payments, PV, FV, Type)
     * function, which calculates the mortgage or annuity payment / yield per
     * period.
     *
     * @param r
     *            - periodic interest rate represented as a decimal.
     * @param nper
     *            - number of total payments / periods.
     * @param pv
     *            - present value -- borrowed or invested principal.
     * @param fv
     *            - future value of loan or annuity.
     * @param type
     *            - when payment is made: beginning of period is 1; end, 0.
     * @return <code>Double</code> representing periodic payment amount.
     */
    public static Double pmt(Double r, Integer nper, Double pv, Double fv, Integer type) {
        // pmt = r / ((1 + r)^N - 1) * -(pv * (1 + r)^N + fv)
        Double cf = compoundFactor(r, nper);
        Double pmt = (1 / cf) * -1 * (pv * Math.pow(1 + r, nper) + fv);

        // account for payments at beginning of period versus end.
        if (type == 1) {
            pmt /= (1 + r);
        }

        // return results to caller.
        return pmt;
    }

    /**
     * Overloaded pmt() call omitting type, which defaults to 0.
     *
     * @see #pmt(Double, int, Double, Double, int)
     */
    public static Double pmt(Double r, Integer nper, Double pv, Double fv) {
        return pmt(r, nper, pv, fv, 0);
    }

    /**
     * Overloaded pmt() call omitting fv and type, which both default to 0.
     *
     * @see #pmt(Double, int, Double, Double, int)
     */
    public static Double pmt(Double r, Integer nper, Double pv) {
        return pmt(r, nper, pv, 0);
    }

    /**
     * Emulates Excel/Calc's FV(interest_rate, number_payments, payment, PV,
     * Type) function, which calculates future value or principal at period N.
     *
     * @param r
     *            - periodic interest rate represented as a decimal.
     * @param nper
     *            - number of total payments / periods.
     * @param c
     *            - periodic payment amount.
     * @param pv
     *            - present value -- borrowed or invested principal.
     * @param type
     *            - when payment is made: beginning of period is 1; end, 0.
     * @return <code>Double</code> representing future principal value.
     */
    public static Double fv(Double r, Integer nper, Double c, Double pv, Integer type) {
        // account for payments at beginning of period versus end.
        // since we are going in reverse, we multiply by 1 plus interest rate.
        if (type == 1) {
            c *= (1 + r);
        }

        // fv = -(((1 + r)^N - 1) / r * c + pv * (1 + r)^N);
        Double cf = compoundFactor(r, nper);
        Double fv = -(cf * c + pv * Math.pow(1 + r, nper));

        // return results to caller.
        return fv;
    }

    /**
     * Overloaded fv() call omitting type, which defaults to 0.
     *
     * @see #fv(Double, int, Double, Double, int)
     */
    public static Double fv(Double r, Integer nper, Double c, Double pv) {
        return fv(r, nper, c, pv, 0);
    }

    /**
     * Overloaded fv() call omitting present value and type, which defaults to 0.
     *
     * @see #fv(Double, int, Double, Double, int)
     */
    public static Double fv(Double r, Integer nper, Double c) {
        return fv(r, nper, c, 0);
    }

    /**
     * Emulates Excel/Calc's IPMT(interest_rate, period, number_payments, PV,
     * FV, Type) function, which calculates the portion of the payment at a
     * given period that is the interest on previous balance.
     *
     * @param r
     *            - periodic interest rate represented as a decimal.
     * @param per
     *            - period (payment number) to check value at.
     * @param nper
     *            - number of total payments / periods.
     * @param pv
     *            - present value -- borrowed or invested principal.
     * @param fv
     *            - future value of loan or annuity.
     * @param type
     *            - when payment is made: beginning of period is 1; end, 0.
     * @return <code>Double</code> representing interest portion of payment.
     *
     * @see #pmt(Double, int, Double, Double, int)
     * @see #fv(Double, int, Double, Double, int)
     */
    public static Double ipmt(Double r, Integer per, Integer nper, Double pv, Double fv, Integer type) {
        // Prior period (i.e., per-1) balance times periodic interest rate.
        // i.e., ipmt = fv(r, per-1, c, pv, type) * r
        // where c = pmt(r, nper, pv, fv, type)
        Double ipmt = fv(r, per - 1, pmt(r, nper, pv, fv, type), pv, type) * r;

        // account for payments at beginning of period versus end.
        if (type == 1) {
            ipmt /= (1 + r);
        }

        // return results to caller.
        return ipmt;
    }

    /**
     * Emulates Excel/Calc's PPMT(interest_rate, period, number_payments, PV,
     * FV, Type) function, which calculates the portion of the payment at a
     * given period that will apply to principal.
     *
     * @param r
     *            - periodic interest rate represented as a decimal.
     * @param per
     *            - period (payment number) to check value at.
     * @param nper
     *            - number of total payments / periods.
     * @param pv
     *            - present value -- borrowed or invested principal.
     * @param fv
     *            - future value of loan or annuity.
     * @param type
     *            - when payment is made: beginning of period is 1; end, 0.
     * @return <code>Double</code> representing principal portion of payment.
     *
     * @see #pmt(Double, int, Double, Double, int)
     * @see #ipmt(Double, int, int, Double, Double, int)
     */
    public static Double ppmt(Double r, Integer per, Integer nper, Double pv, Double fv, Integer type) {
        // Calculated payment per period minus interest portion of that period.
        // i.e., ppmt = c - i
        // where c = pmt(r, nper, pv, fv, type)
        // and i = ipmt(r, per, nper, pv, fv, type)
        return pmt(r, nper, pv, fv, type) - ipmt(r, per, nper, pv, fv, type);
    }

    /**
     * Emulates Excel/Calc's PV(interest_rate, number_payments, PMT,
     * FV, Type) function, which calculates the present value of a loan or an investment,
     * based on a constant interest rate. You can use PV with either periodic,
     * constant payments (such as a mortgage or other loan),
     * or a future value that's your investment goal.
     *
     * @param r
     *            - periodic interest rate represented as a decimal.
     * @param nper
     *            - number of total payments / periods.
     * @param pmt
     *            - payment -- money paid every period.
     * @param fv
     *            - future value of loan or annuity.
     * @param type
     *            - when payment is made: beginning of period is 1; end, 0.
     * @return <code>Double</code> representing principal portion of payment.
     *
     * @see #pmt(Double, int, Double, Double, int)
     * @see #ipmt(Double, int, int, Double, Double, int)
     */
    public static Double pv(Double r, Integer nper, Double pmt, Double fv, Integer type) {
        // Equation: pv*(1+r)^nper + pmt*(1+r*type)*((1+r)^nper - 1)/r + fv = 0
        // i.e. in case rate=0, (pmt * nper) + pv + fv = 0
        Double cf = compoundFactor(r, nper);
        Double pv = (-1 * fv - pmt * (1 + r * type) * cf) / Math.pow(1 + r, nper);
        return pv;
    }

    /**
     * Compound factor, used in several calculations:
     * ((1+rate)^nper - 1)/rate
     *
     * @param r
     *            - periodic interest rate represented as a decimal.
     * @param nper
     *            - number of total payments / periods.
     *
     * @return <code>Double</code> representing the compound factor
     *
     * @see #fv(Double, Integer, Double, Double, Integer)
     * @see #pmt(Double, Integer, Integer, Double, Double, Integer)
     * @see #pv(Double, Integer, Double, Double, Integer)
     */
    private static Double compoundFactor(Double r, Integer nper) {
        // exception for r=0, where derivation leads as to cr=nper
        if (r==0) {
            return nper;
        }
        // Equation: ((1+rate)^nper - 1)/rate
        return (Math.pow((1 + r), nper) - 1) / r;
    }
}
