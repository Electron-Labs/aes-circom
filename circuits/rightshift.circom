pragma circom 2.0.0;

template RightShift(n, r) {
    signal input in[n];
    signal output out[n];

    for(var i=n-1; i>=0; i--){
        if(i-r >= 0){
            out[i] <== in[i-r];
        } else {
            out[i] <== 0;
        }
    }
}