
#include "DSDef.h"
#include <stdlib.h>

struct _DSVal
{
    enum DSValType vt;
    union {
        int i;
        double d;
        char* s;
        void* p;
    } val;
};

/* Begin of struct _DSVal function implementations */
DSVal dsval_i_new(int i)
{
    DSVal v = malloc(sizeof(struct _DSVal));
    if (v) {
        v->vt = vt_i;
        v->val.i = i;
    }
    return v;
}

DSVal dsval_d_new(double d)
{
    DSVal v = malloc(sizeof(struct _DSVal));
    if (v) {
        v->vt = vt_d;
        v->val.d = d;
    }
    return v;
}

DSVal dsval_s_new(char* s)
{
    DSVal v = malloc(sizeof(struct _DSVal));
    if (v) {
        v->vt = vt_s;
        v->val.s = s;
    }
    return v;
}

DSVal dsval_p_new(void* p)
{
    DSVal v = malloc(sizeof(struct _DSVal));
    if (v) {
        v->vt = vt_p;
        v->val.p = p;
    }
    return v;
}

DSVal dsval_delete(DSVal v, DSValDtor dtor)
{
    if (!v) { return NULL; }
    if (v->vt == vt_p) {
        if (dtor) {
            dtor(v->val.p);
        }
    }
    free(v);
    return NULL;
}

enum DSValType dsval_type(DSVal v) { return v ? v->vt : vt_n; }
int dsval_i(DSVal v) { return v ? v->val.i : 0; }
double dsval_d(DSVal v) { return v ? v->val.d : 0; }
char* dsval_s(DSVal v) { return v ? v->val.s : NULL; }
void* dsval_p(DSVal v) { return v ? v->val.p : NULL; }
/* End of struct _DSVal function implementations */