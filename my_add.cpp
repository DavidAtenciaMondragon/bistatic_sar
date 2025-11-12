#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    double *in, *out;
    in = (double *) mxGetPr(prhs[0]);
    plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
    out = (double *) mxGetPr(plhs[0]);
    *out = *in + 1.0;
}