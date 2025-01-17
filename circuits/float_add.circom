pragma circom 2.0.0;

/////////////////////////////////////////////////////////////////////////////////////
/////////////////////// Templates from the circomlib ////////////////////////////////
////////////////// Copy-pasted here for easy reference //////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////

/*
 * Outputs `a` AND `b`
 */
template AND() {
    signal input a;
    signal input b;
    signal output out;

    out <== a*b;
}

/*
 * Outputs `a` OR `b`
 */
template OR() {
    signal input a;
    signal input b;
    signal output out;

    out <== a + b - a*b;
}

/*
 * `out` = `cond` ? `L` : `R`
 */
template IfThenElse() {
    signal input cond;
    signal input L;
    signal input R;
    signal output out;

    out <== cond * (L - R) + R;
}

/*
 * (`outL`, `outR`) = `sel` ? (`R`, `L`) : (`L`, `R`)
 */
template Switcher() {
    signal input sel;
    signal input L;
    signal input R;
    signal output outL;
    signal output outR;

    signal aux;

    aux <== (R-L)*sel;
    outL <==  aux + L;
    outR <== -aux + R;
}

/*
 * Decomposes `in` into `b` bits, given by `bits`.
 * Least significant bit in `bits[0]`.
 * Enforces that `in` is at most `b` bits long.
 */
template Num2Bits(b) {
    signal input in;
    signal output bits[b];

    for (var i = 0; i < b; i++) {
        bits[i] <-- (in >> i) & 1;
        bits[i] * (1 - bits[i]) === 0;
    }
    var sum_of_bits = 0;
    for (var i = 0; i < b; i++) {
        sum_of_bits += (2 ** i) * bits[i];
    }
    sum_of_bits === in;
}

/*
 * Reconstructs `out` from `b` bits, given by `bits`.
 * Least significant bit in `bits[0]`.
 */
template Bits2Num(b) {
    signal input bits[b];
    signal output out;
    var lc = 0;

    for (var i = 0; i < b; i++) {
        lc += (bits[i] * (1 << i));
    }
    out <== lc;
}

/*
 * Checks if `in` is zero and returns the output in `out`.
 */
template IsZero() {
    signal input in;
    signal output out;

    signal inv;

    inv <-- in!=0 ? 1/in : 0;

    out <== -in*inv +1;
    in*out === 0;
}

/*
 * Checks if `in[0]` == `in[1]` and returns the output in `out`.
 */
template IsEqual() {
    signal input in[2];
    signal output out;

    component isz = IsZero();

    in[1] - in[0] ==> isz.in;

    isz.out ==> out;
}

/*
 * Checks if `in[0]` < `in[1]` and returns the output in `out`.
 * Assumes `n` bit inputs. The behavior is not well-defined if any input is more than `n`-bits long.
 */
template LessThan(n) {
    assert(n <= 252);
    signal input in[2];
    signal output out;

    component n2b = Num2Bits(n+1);

    n2b.in <== in[0]+ (1<<n) - in[1];

    out <== 1-n2b.bits[n];
}

/////////////////////////////////////////////////////////////////////////////////////
///////////////////////// Templates for this lab ////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////

/*
 * Outputs `out` = 1 if `in` is at most `b` bits long, and 0 otherwise.
 */
template CheckBitLength(b) {
    assert(b < 254);
    signal input in;
    signal output out;

    // TODO
    // convert `in` into b-bits long form and sum all b-bits
    signal bits_slice[b];
    for (var i = 0; i < b; i++) {
        bits_slice[i] <-- (in >> i) & 1;
        bits_slice[i] * (1 - bits_slice[i]) === 0;
    }

    var sum_of_bits = 0;
    for (var i = 0; i < b; i++) {
        sum_of_bits += (2 ** i) * bits_slice[i];
    }

    /* Method 1; Leverage existed template */
    component check_bit_equal = IsEqual();
    check_bit_equal.in[0] <== in;
    check_bit_equal.in[1] <== sum_of_bits;

    out <== check_bit_equal.out;

    /* Method 2: Create the circuit on our own */
    // signal check_bit_equal;
    // signal diff;
    // signal inv;

    // diff <== in - sum_of_bits;
    // inv <-- diff != 0 ? 1 / diff : 0;
    // check_bit_equal <== -diff * inv + 1;    // if diff is non-zero, diff * inv = 1
    // diff * check_bit_equal === 0;   // constraint the witness appropriately

    // out <== check_bit_equal;
}

/*
 * Enforces the well-formedness of an exponent-mantissa pair (e, m), which is defined as follows:
 * if `e` is zero, then `m` must be zero
 * else, `e` must be at most `k` bits long, and `m` must be in the range [2^p, 2^p+1)
 */
template CheckWellFormedness(k, p) {
    signal input e;
    signal input m;

    // check if `e` is zero
    component is_e_zero = IsZero();
    is_e_zero.in <== e;

    // Case I: `e` is zero
    //// `m` must be zero
    component is_m_zero = IsZero();
    is_m_zero.in <== m;

    // Case II: `e` is nonzero
    //// `e` is `k` bits
    component check_e_bits = CheckBitLength(k);
    check_e_bits.in <== e;
    //// `m` is `p`+1 bits with the MSB equal to 1
    //// equivalent to check `m` - 2^`p` is in `p` bits
    component check_m_bits = CheckBitLength(p);
    check_m_bits.in <== m - (1 << p);

    // choose the right checks based on `is_e_zero`
    component if_else = IfThenElse();
    if_else.cond <== is_e_zero.out;
    if_else.L <== is_m_zero.out;
    //// check_m_bits.out * check_e_bits.out is equivalent to check_m_bits.out AND check_e_bits.out
    if_else.R <== check_m_bits.out * check_e_bits.out;

    // assert that those checks passed
    if_else.out === 1;
}

/*
 * Right-shifts `b`-bit long `x` by `shift` bits to output `y`, where `shift` is a public circuit parameter.
 */
template RightShift(b, shift) {
    assert(shift < b);
    signal input x;
    signal output y;

    // TODO
    // check the length of x
    component check_x_len = CheckBitLength(b);
    check_x_len.in <== x;
    check_x_len.out === 1;

    // Right-shift x by `shift` bits
    y <-- x >> shift;

    // // (Trivial) check the length of y
    // component check_y_len = CheckBitLength(b-shift);
    // check_y_len.in <== y;
    // check_y_len.out === 1;
}

/*
 * Rounds the input floating-point number and checks to ensure that rounding does not make the mantissa unnormalized.
 * Rounding is necessary to prevent the bitlength of the mantissa from growing with each successive operation.
 * The input is a normalized floating-point number (e, m) with precision `P`, where `e` is a `k`-bit exponent and `m` is a `P`+1-bit mantissa.
 * The output is a normalized floating-point number (e_out, m_out) representing the same value with a lower precision `p`.
 */
template RoundAndCheck(k, p, P) {
    signal input e;
    signal input m;
    signal output e_out;
    signal output m_out;
    assert(P > p);

    // check if no overflow occurs
    component if_no_overflow = LessThan(P+1);
    if_no_overflow.in[0] <== m;
    if_no_overflow.in[1] <== (1 << (P+1)) - (1 << (P-p-1));
    signal no_overflow <== if_no_overflow.out;

    var round_amt = P-p;
    // Case I: no overflow
    // compute (m + 2^{round_amt-1}) >> round_amt
    var m_prime = m + (1 << (round_amt-1));
    //// Although m_prime is P+1 bits long in no overflow case, it can be P+2 bits long
    //// in the overflow case and the constraints should not fail in either case
    component right_shift = RightShift(P+2, round_amt);
    right_shift.x <== m_prime;
    var m_out_1 = right_shift.y;
    var e_out_1 = e;

    // Case II: overflow
    var e_out_2 = e + 1;
    var m_out_2 = (1 << p);

    // select right output based on no_overflow
    component if_else[2];
    for (var i = 0; i < 2; i++) {
        if_else[i] = IfThenElse();
        if_else[i].cond <== no_overflow;
    }
    if_else[0].L <== e_out_1;
    if_else[0].R <== e_out_2;
    if_else[1].L <== m_out_1;
    if_else[1].R <== m_out_2;
    e_out <== if_else[0].out;
    m_out <== if_else[1].out;
}

/*
 * Left-shifts `x` by `shift` bits to output `y`.
 * Enforces 0 <= `shift` < `shift_bound`.
 * If `skip_checks` = 1, then we don't care about the output and the `shift_bound` constraint is not enforced.
 */
template LeftShift(shift_bound) {
    signal input x;
    signal input shift;
    signal input skip_checks;
    signal output y;

    // TODO
    // If shift_bound < shift, shift_num = 0
    var shift_num = 0;
    signal check_eq[shift_bound];

    for (var i = 0; i < shift_bound; i++) {
        check_eq[i] <-- shift - i == 0 ? 1 : 0;  // check_eq = 1 iif i == shift
        check_eq[i] * (shift - i) === 0;
        shift_num += check_eq[i] * (1 << i);
    }

    // If shift > shift_bound, shift_num = valid_shift = 0
    // If skip_checks = 1, constraints does not matter
    signal valid_shift <-- shift_num != 0 ? 1 : 0;
    (1 - valid_shift) * (1 - skip_checks) === 0;

    y <== shift_num * x;


    // // Falsely code structure in HDL
    // if (skip_checks == 1) {
    //     y <-- x << shift;
    // }
    // else {
    //     // contraints
    // }
}

/*
 * Find the Most-Significant Non-Zero Bit (MSNZB) of `in`, where `in` is assumed to be non-zero value of `b` bits.
 * Outputs the MSNZB as a one-hot vector `one_hot` of `b` bits, where `one_hot`[i] = 1 if MSNZB(`in`) = i and 0 otherwise.
 * The MSNZB is output as a one-hot vector to reduce the number of constraints in the subsequent `Normalize` template.
 * Enforces that `in` is non-zero as MSNZB(0) is undefined.
 * If `skip_checks` = 1, then we don't care about the output and the non-zero constraint is not enforced.
 */
template MSNZB(b) {
    signal input in;
    signal input skip_checks;
    signal output one_hot[b];

    // TODO
    // Find the i for one-hot vector first
    signal valid_lower_bound[b];
    signal valid_upper_bound[b];
    for (var i = 0; i < b; i++) {
        // valid_lower_bound[i] = LessThan(b);
        // valid_upper_bound[i] = LessThan(b);

        valid_lower_bound[i] <-- (2 ** i) <= in ? 1 : 0;
        // valid_lower_bound[i].in[0] <== 2 ** i;
        // valid_lower_bound[i].in[1] <== in;

        valid_upper_bound[i] <-- in < (2 ** (i + 1)) ? 1 : 0;
        // valid_upper_bound[i].in[0] <== in;
        // valid_upper_bound[i].in[1] <== 2 ** (i + 1);

        one_hot[i] <== valid_lower_bound[i] * valid_upper_bound[i];
    }

    // check `in` is non_zero
    component zero_in = IsZero();
    zero_in.in <== in;
    zero_in.out * (1 - skip_checks) === 0;

    // check output is valid
    component one_hot_integer = Bits2Num(b);
    component valid_output = CheckBitLength(b);
    for (var i = 0; i < b; i++) {
        one_hot_integer.bits[i] <== one_hot[i];
    }
    valid_output.in <== one_hot_integer.out;
    (1 - valid_output.out) * (1 - skip_checks) === 0;
}

/*
 * Normalizes the input floating-point number.
 * The input is a floating-point number with a `k`-bit exponent `e` and a `P`+1-bit *unnormalized* mantissa `m` with precision `p`, where `m` is assumed to be non-zero.
 * The output is a floating-point number representing the same value with exponent `e_out` and a *normalized* mantissa `m_out` of `P`+1-bits and precision `P`.
 * Enforces that `m` is non-zero as a zero-value can not be normalized.
 * If `skip_checks` = 1, then we don't care about the output and the non-zero constraint is not enforced.
 */
template Normalize(k, p, P) {
    signal input e;
    signal input m;
    signal input skip_checks;
    signal output e_out;
    signal output m_out;
    assert(P > p);

    // TODO
    component ell = MSNZB(P+1);
    ell.in <== m;
    ell.skip_checks <== skip_checks;

    // Find the difference between old and new precision
    // P: new precision
    // p: old precision
    // P >= msnzb > p

    // p + diff_e = msnzb
    // msnzb + diff_m = P

    var diff_e = 0;
    var diff_m = 0;

    for (var i = 0; i < P+1; i++) {
        diff_e += ell.one_hot[i] * (i - p);
        diff_m += ell.one_hot[i] * (P - i);
    }
    e_out <== e + diff_e;
    // log(P, p, diff_e, diff_m);
    

    component left_shift_m = LeftShift(P-p+1);
    left_shift_m.x <== m;
    left_shift_m.shift <== diff_m;
    left_shift_m.skip_checks <== skip_checks;

    m_out <== left_shift_m.y;
    // log(e, m, e_out, m_out);
}

/*
 * Adds two floating-point numbers.
 * The inputs are normalized floating-point numbers with `k`-bit exponents `e` and `p`+1-bit mantissas `m` with scale `p`.
 * Does not assume that the inputs are well-formed and makes appropriate checks for the same.
 * The output is a normalized floating-point number with exponent `e_out` and mantissa `m_out` of `p`+1-bits and scale `p`.
 * Enforces that inputs are well-formed.
 */
template FloatAdd(k, p) {
    signal input e[2];
    signal input m[2];
    signal output e_out;
    signal output m_out;

    // TODO
    // Check the well-formedness
    component check_well_formed[2];
    for (var i = 0; i < 2; i++) {
        check_well_formed[i] = CheckWellFormedness(k, p);
        check_well_formed[i].e <== e[i];
        check_well_formed[i].m <== m[i];
    }

    // Find larger number by arragning numbers in the order of their magnitude
    component mgn[2];
    component first_mgn_is_smaller = LessThan(p+k+2);   // Comparison over k+p+1 bits 
    for (var i = 0; i < 2; i++) {
        mgn[i] = LeftShift(p+2);
        mgn[i].x <== e[i];
        mgn[i].shift <== p + 1;
        mgn[i].skip_checks <== 0;
        first_mgn_is_smaller.in[i] <== mgn[i].y + m[i];
    }

    // outL is alpha_e, outR is beta_e
    component switcher_mgn_e = Switcher();
    switcher_mgn_e.sel <== first_mgn_is_smaller.out;
    switcher_mgn_e.L <== e[0];
    switcher_mgn_e.R <== e[1];

    // outL is alpha_m, outR is beta_m
    component switcher_mgn_m = Switcher();
    switcher_mgn_m.sel <== first_mgn_is_smaller.out;
    switcher_mgn_m.L <== m[0];
    switcher_mgn_m.R <== m[1];

    // Calculate the difference of exponents to check
    // 1. Difference too large (diff > p + 1)
    // 2. Alpha_e is zero (alpha_e == 0)
    // If not above, the result is the sume of the two numbers
    signal diff <== switcher_mgn_e.outL - switcher_mgn_e.outR;
    component large_diff_exist = LessThan(k);     // exponents are k bits
    large_diff_exist.in[0] <== p + 1;
    large_diff_exist.in[1] <== diff;

    component alpha_e_isz = IsZero();
    alpha_e_isz.in <== switcher_mgn_e.outL;

    // Using OR gate to combine two condition
    component skip_sum = OR();
    skip_sum.a <== large_diff_exist.out;
    skip_sum.b <== alpha_e_isz.out;

    // Left-shift alpha_m by diff bits to align the mantissa
    component alpha_m_lsh = LeftShift(p+2);
    alpha_m_lsh.x <== switcher_mgn_m.outL;
    alpha_m_lsh.shift <== diff;
    alpha_m_lsh.skip_checks <== skip_sum.out;

    // Add the aligned mantissa to get an unnormalized output mantissa
    component normalized = Normalize(k, p, 2*p+1);  // two b bits sum is at most 2*b+1 bits
    normalized.e <== switcher_mgn_e.outR;   // e = beta_e
    normalized.m <== alpha_m_lsh.y + switcher_mgn_m.outR;   // m = alpha_m + beta_m
    normalized.skip_checks <== skip_sum.out;

    // Round normalized mantissa by p+1 bits
    // to get a p+1-bit mantissa with precision p
    component rounded = RoundAndCheck(k, p, 2*p+1);
    rounded.e <== normalized.e_out;
    rounded.m <== normalized.m_out;

    // Use If-else gate to set (e_out, m_out)
    // by the condition of skip_sum.out
    component final_e = IfThenElse();
    final_e.cond <== skip_sum.out;
    final_e.L <== switcher_mgn_e.outL;  // skip_sum == 1
    final_e.R <== rounded.e_out;

    component final_m = IfThenElse();
    final_m.cond <== skip_sum.out;
    final_m.L <== switcher_mgn_m.outL;  // skip_sum == 1
    final_m.R <== rounded.m_out;

    // If skip_sum == 1, (e_out, m_out) = (alpha_e, alpha_m)
    // else, (e_out, m_out) = (rounded_e, rounded_m)
    e_out <== final_e.out;
    m_out <== final_m.out;
}
