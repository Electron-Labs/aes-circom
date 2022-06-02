pragma circom 2.0.0;

template LeftShift(n, r) {
    signal input in[n];
    signal output out[n];
    var j=0;
    for (var i=0; i<n; i++) {
        if (i < r) {
            out[i] <== 0;
        } else {
            out[i] <== in[j];
            j++;
        }
    }
}