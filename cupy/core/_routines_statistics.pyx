from cupy.core._kernel import create_reduction_func
from cupy.core._kernel import ReductionKernel

from cupy.core cimport _routines_math as _math
from cupy.core.core cimport ndarray


cdef ndarray _ndarray_max(ndarray self, axis, out, dtype, keepdims):
    return _amax(self, axis=axis, out=out, dtype=dtype, keepdims=keepdims)


cdef ndarray _ndarray_min(ndarray self, axis, out, dtype, keepdims):
    return _amin(self, axis=axis, out=out, dtype=dtype, keepdims=keepdims)


cdef ndarray _ndarray_argmax(ndarray self, axis, out, dtype, keepdims):
    return _argmax(self, axis=axis, out=out, dtype=dtype, keepdims=keepdims)

cdef ndarray _ndarray_nanargmax(ndarray self, axis, out, dtype, keepdims):
    return _nanargmax(self, axis=axis, out=out, dtype=dtype, keepdims=keepdims)

cdef ndarray _ndarray_argmin(ndarray self, axis, out, dtype, keepdims):
    return _argmin(self, axis=axis, out=out, dtype=dtype, keepdims=keepdims)

cdef ndarray _ndarray_nanargmin(ndarray self, axis, out, dtype, keepdims):
    return _nanargmin(self, axis=axis, out=out, dtype=dtype, keepdims=keepdims)

cdef ndarray _ndarray_mean(ndarray self, axis, dtype, out, keepdims):
    return _mean(self, axis=axis, dtype=dtype, out=out, keepdims=keepdims)


cdef ndarray _ndarray_var(ndarray self, axis, dtype, out, ddof, keepdims):
    return _var(
        self, axis=axis, dtype=dtype, out=out, ddof=ddof, keepdims=keepdims)


cdef ndarray _ndarray_std(ndarray self, axis, dtype, out, ddof, keepdims):
    return _std(
        self, axis=axis, dtype=dtype, out=out, ddof=ddof, keepdims=keepdims)


cpdef ndarray _ndarray_nanvar(ndarray self, axis, dtype, out, ddof, keepdims):
    return _nanvar(
        self, axis=axis, dtype=dtype, out=out, ddof=ddof, keepdims=keepdims)


cpdef ndarray _ndarray_nanstd(ndarray self, axis, dtype, out, ddof, keepdims):
    return _nanstd(
        self, axis=axis, dtype=dtype, out=out, ddof=ddof, keepdims=keepdims)


cdef _min_max_preamble = '''
template <typename T>
struct min_max_st{
    T value;
    int index;
    __device__ min_max_st() : index(-1) { }
    __device__ min_max_st(T v) : value(v), index(0) { }
    __device__ min_max_st(T v, int i) : value(v), index(i) { }
};

template <typename T>
inline __device__ bool is_nan(T x) {
    return x != x;
}

template <typename T>
__device__ min_max_st<T> my_min(
        const min_max_st<T>& a, const min_max_st<T>& b) {
    if (a.index == -1) return b;
    if (b.index == -1) return a;
    return min_max_st<T>(min(a.value, b.value));
}
template <typename T>
__device__ min_max_st<T> my_min_float(
        const min_max_st<T>& a, const min_max_st<T>& b) {
    if (a.index == -1) return b;
    if (b.index == -1) return a;
    if (is_nan(a.value)) return a;
    if (is_nan(b.value)) return b;
    return min_max_st<T>(min(a.value, b.value));
}
template <typename T>
__device__ min_max_st<T> my_min_complex(
        const min_max_st<T>& a, const min_max_st<T>& b) {
    if (a.index == -1) return b;
    if (b.index == -1) return a;
    if (is_nan(a.value.real())) return a;
    if (is_nan(a.value.imag())) return a;
    if (is_nan(b.value.real())) return b;
    if (is_nan(b.value.imag())) return b;
    return min_max_st<T>(min(a.value, b.value));
}

template <typename T>
__device__ min_max_st<T> my_max(
        const min_max_st<T>& a, const min_max_st<T>& b) {
    if (a.index == -1) return b;
    if (b.index == -1) return a;
    return min_max_st<T>(max(a.value, b.value));
}
template <typename T>
__device__ min_max_st<T> my_max_float(
        const min_max_st<T>& a, const min_max_st<T>& b) {
    if (a.index == -1) return b;
    if (b.index == -1) return a;
    if (is_nan(a.value)) return a;
    if (is_nan(b.value)) return b;
    return min_max_st<T>(max(a.value, b.value));
}
template <typename T>
__device__ min_max_st<T> my_max_complex(
        const min_max_st<T>& a, const min_max_st<T>& b) {
    if (a.index == -1) return b;
    if (b.index == -1) return a;
    if (is_nan(a.value.real())) return a;
    if (is_nan(a.value.imag())) return a;
    if (is_nan(b.value.real())) return b;
    if (is_nan(b.value.imag())) return b;
    return min_max_st<T>(max(a.value, b.value));
}

template <typename T>
__device__ min_max_st<T> my_argmin(
        const min_max_st<T>& a, const min_max_st<T>& b) {
    if (a.index == -1) return b;
    if (b.index == -1) return a;
    if (a.value == b.value)
        return min_max_st<T>(a.value, min(a.index, b.index));
    return (a.value <= b.value) ? a : b;
}
template <typename T>
__device__ min_max_st<T> my_argmin_float(
        const min_max_st<T>& a, const min_max_st<T>& b) {
    if (a.index == -1) return b;
    if (b.index == -1) return a;
    if (a.value == b.value)
        return min_max_st<T>(a.value, min(a.index, b.index));
    if (is_nan(a.value)) return a;
    if (is_nan(b.value)) return b;
    return (a.value <= b.value) ? a : b;
}
template <typename T>
__device__ min_max_st<T> my_argmin_complex(
        const min_max_st<T>& a, const min_max_st<T>& b) {
    if (a.index == -1) return b;
    if (b.index == -1) return a;
    if (a.value == b.value)
        return min_max_st<T>(a.value, min(a.index, b.index));
    if (is_nan(a.value.real())) return a;
    if (is_nan(a.value.imag())) return a;
    if (is_nan(b.value.real())) return b;
    if (is_nan(b.value.imag())) return b;
    return (a.value <= b.value) ? a : b;
}

template <typename T>
__device__ min_max_st<T> my_argmax(
        const min_max_st<T>& a, const min_max_st<T>& b) {
    if (a.index == -1) return b;
    if (b.index == -1) return a;
    if (a.value == b.value)
        return min_max_st<T>(a.value, min(a.index, b.index));
    return (a.value >= b.value) ? a : b;
}
template <typename T>
__device__ min_max_st<T> my_argmax_float(
        const min_max_st<T>& a, const min_max_st<T>& b) {
    if (a.index == -1) return b;
    if (b.index == -1) return a;
    if (a.value == b.value)
        return min_max_st<T>(a.value, min(a.index, b.index));
    if (is_nan(a.value)) return a;
    if (is_nan(b.value)) return b;
    return (a.value >= b.value) ? a : b;
}
template <typename T>
__device__ min_max_st<T> my_argmax_complex(
        const min_max_st<T>& a, const min_max_st<T>& b) {
    if (a.index == -1) return b;
    if (b.index == -1) return a;
    if (a.value == b.value)
        return min_max_st<T>(a.value, min(a.index, b.index));
    if (is_nan(a.value.real())) return a;
    if (is_nan(a.value.imag())) return a;
    if (is_nan(b.value.real())) return b;
    if (is_nan(b.value.imag())) return b;
    return (a.value >= b.value) ? a : b;
}

'''


cdef _amin = create_reduction_func(
    'cupy_min',
    ('?->?', 'b->b', 'B->B', 'h->h', 'H->H', 'i->i', 'I->I', 'l->l', 'L->L',
     'q->q', 'Q->Q',
     ('e->e', (None, 'my_min_float(a, b)', None, None)),
     ('f->f', (None, 'my_min_float(a, b)', None, None)),
     ('d->d', (None, 'my_min_float(a, b)', None, None)),
     ('F->F', (None, 'my_min_complex(a, b)', None, None)),
     ('D->D', (None, 'my_min_complex(a, b)', None, None))),
    ('min_max_st<type_in0_raw>(in0)', 'my_min(a, b)', 'out0 = a.value',
     'min_max_st<type_in0_raw>'),
    None, _min_max_preamble)


cdef _amax = create_reduction_func(
    'cupy_max',
    ('?->?', 'b->b', 'B->B', 'h->h', 'H->H', 'i->i', 'I->I', 'l->l', 'L->L',
     'q->q', 'Q->Q',
     ('e->e', (None, 'my_max_float(a, b)', None, None)),
     ('f->f', (None, 'my_max_float(a, b)', None, None)),
     ('d->d', (None, 'my_max_float(a, b)', None, None)),
     ('F->F', (None, 'my_max_complex(a, b)', None, None)),
     ('D->D', (None, 'my_max_complex(a, b)', None, None)),
     ),
    ('min_max_st<type_in0_raw>(in0)', 'my_max(a, b)', 'out0 = a.value',
     'min_max_st<type_in0_raw>'),
    None, _min_max_preamble)


nanmin = create_reduction_func(
    'cupy_nanmin',
    ('?->?', 'b->b', 'B->B', 'h->h', 'H->H', 'i->i', 'I->I', 'l->l', 'L->L',
     'q->q', 'Q->Q', 'e->e', 'f->f', 'd->d'),
    ('min_max_st<type_in0_raw>(in0)', 'my_min(a, b)', 'out0 = a.value',
     'min_max_st<type_in0_raw>'),
    None, _min_max_preamble)


nanmax = create_reduction_func(
    'cupy_nanmax',
    ('?->?', 'b->b', 'B->B', 'h->h', 'H->H', 'i->i', 'I->I', 'l->l', 'L->L',
     'q->q', 'Q->Q', 'e->e', 'f->f', 'd->d'),
    ('min_max_st<type_in0_raw>(in0)', 'my_max(a, b)', 'out0 = a.value',
     'min_max_st<type_in0_raw>'),
    None, _min_max_preamble)


cdef _argmin = create_reduction_func(
    'cupy_argmin',
    ('?->q', 'B->q', 'h->q', 'H->q', 'i->q', 'I->q', 'l->q', 'L->q',
     'q->q', 'Q->q',
     ('e->q', (None, 'my_argmin_float(a, b)', None, None)),
     ('f->q', (None, 'my_argmin_float(a, b)', None, None)),
     ('d->q', (None, 'my_argmin_float(a, b)', None, None)),
     ('F->q', (None, 'my_argmin_complex(a, b)', None, None)),
     ('D->q', (None, 'my_argmin_complex(a, b)', None, None))),
    ('min_max_st<type_in0_raw>(in0, _J)', 'my_argmin(a, b)', 'out0 = a.index',
     'min_max_st<type_in0_raw>'),
    None, _min_max_preamble)


cdef _argmax = create_reduction_func(
    'cupy_argmax',
    ('?->q', 'B->q', 'h->q', 'H->q', 'i->q', 'I->q', 'l->q', 'L->q',
     'q->q', 'Q->q',
     ('e->q', (None, 'my_argmax_float(a, b)', None, None)),
     ('f->q', (None, 'my_argmax_float(a, b)', None, None)),
     ('d->q', (None, 'my_argmax_float(a, b)', None, None)),
     ('F->q', (None, 'my_argmax_complex(a, b)', None, None)),
     ('D->q', (None, 'my_argmax_complex(a, b)', None, None))),
    ('min_max_st<type_in0_raw>(in0, _J)', 'my_argmax(a, b)', 'out0 = a.index',
     'min_max_st<type_in0_raw>'),
    None, _min_max_preamble)


cdef _nanargmin = create_reduction_func(
    'cupy_nanargmin',
    ('?->q', 'B->q', 'h->q', 'H->q', 'i->q', 'I->q', 'l->q', 'L->q',
     'q->q', 'Q->q',
     ('e->q', (None, 'my_argmin_float(a, b)', None, None)),
     ('f->q', (None, 'my_argmin_float(a, b)', None, None)),
     ('d->q', (None, 'my_argmin_float(a, b)', None, None)),
     ('F->q', (None, 'my_argmin_complex(a, b)', None, None)),
     ('D->q', (None, 'my_argmin_complex(a, b)', None, None))),
    ('min_max_st<type_in0_raw>(in0, is_nan(in0) ? -1 : _J)',
     'my_argmin(a, b)', 'out0 = a.index', 'min_max_st<type_in0_raw>'),
    None, _min_max_preamble)


cdef _nanargmax = create_reduction_func(
    'cupy_nanargmax',
    ('?->q', 'B->q', 'h->q', 'H->q', 'i->q', 'I->q', 'l->q', 'L->q',
     'q->q', 'Q->q',
     ('e->q', (None, 'my_argmax_float(a, b)', None, None)),
     ('f->q', (None, 'my_argmax_float(a, b)', None, None)),
     ('d->q', (None, 'my_argmax_float(a, b)', None, None)),
     ('F->q', (None, 'my_argmax_complex(a, b)', None, None)),
     ('D->q', (None, 'my_argmax_complex(a, b)', None, None))),
    ('min_max_st<type_in0_raw>(in0, is_nan(in0) ? -1 : _J)',
     'my_argmax(a, b)', 'out0 = a.index', 'min_max_st<type_in0_raw>'),
    None, _min_max_preamble)


cdef ndarray _var(
        ndarray a, axis=None, dtype=None, out=None, ddof=0, keepdims=False):
    assert a.dtype.kind != 'c', 'Variance for complex numbers is not ' \
                                'implemented. Current implemention does not ' \
                                'convert the dtype'
    if axis is None:
        axis = tuple(range(a.ndim))
    if not isinstance(axis, tuple):
        axis = (axis,)

    if dtype is None and a.dtype.kind in 'biu':
        dtype = 'd'

    shape = a.shape
    items = 1
    for ax in axis:
        items *= shape[ax]
    alpha = 1. / max(items - ddof, 0)
    arrmean = a.mean(axis=axis, dtype=dtype, out=None, keepdims=True)
    if out is None:
        return _var_core(a, arrmean, alpha, axis=axis, keepdims=keepdims)
    else:
        return _var_core_out(
            a, arrmean, alpha, out, axis=axis, keepdims=keepdims)


cdef ndarray _std(
        ndarray a, axis=None, dtype=None, out=None, ddof=0, keepdims=False):
    ret = _var(
        a, axis=axis, dtype=dtype, out=None, ddof=ddof, keepdims=keepdims)
    return _math._sqrt(ret, dtype=dtype, out=out)


cdef _var_core = ReductionKernel(
    'S x, T mean, T alpha', 'T out',
    '(x - mean) * (x - mean)',
    'a + b', 'out = alpha * a', '0', '_var_core')

cdef _var_core_out = ReductionKernel(
    'S x, T mean, T alpha', 'U out',
    '(x - mean) * (x - mean)',
    'a + b', 'out = alpha * a', '0', '_var_core')

# TODO(okuta) needs cast
cdef _mean = create_reduction_func(
    'cupy_mean',
    ('?->d', 'B->d', 'h->d', 'H->d', 'i->d', 'I->d', 'l->d', 'L->d',
     'q->d', 'Q->d',
     ('e->e', (None, None, None, 'float')),
     'f->f', 'd->d', 'F->F', 'D->D'),
    ('in0', 'a + b',
     'out0 = a / _type_reduce(_in_ind.size() / _out_ind.size())', None))


_count_non_nan = create_reduction_func(
    'cupy_count_non_nan',
    ('e->l', 'f->l', 'd->l'),
    ('(in0 == in0) ? 1 : 0', 'a + b', 'out0 = a', None), 0)


cdef ndarray _nanstd(
        ndarray a, axis=None, dtype=None, out=None, ddof=0, keepdims=False):
    ret = _nanvar(
        a, axis=axis, dtype=dtype, out=None, ddof=ddof, keepdims=keepdims)
    return _math._sqrt(ret, dtype=dtype, out=out)


cdef ndarray _nanvar(
        ndarray a, axis=None, dtype=None, out=None, ddof=0, keepdims=False):

    assert a.dtype.kind != 'c', 'Variance for complex numbers is not ' \
                                'implemented. Current implemention does not ' \
                                'convert the dtype'

    _count = _count_non_nan(a, axis=axis, keepdims=True)
    arrsum = a._nansum(axis=axis, dtype=dtype, out=None, keepdims=True)

    if out is None:
        return _nanvar_core(
            a, arrsum, _count, ddof, axis=axis, keepdims=keepdims)
    else:
        return _nanvar_core_out(
            a, arrsum, _count, ddof, out, axis=axis, keepdims=keepdims)


cdef _nanvar_preamble = '''
template <typename S, typename T>
__device__ T nanvar_impl(S x, T mean, long long alpha) {
    return (x == x ? T((x - mean) * (x - mean)) : T(0)) / alpha;
}
'''


cdef _nanvar_core = ReductionKernel(
    'S x, T sum, int64 _count, int64 ddof', 'S out',
    'nanvar_impl<S, T>(x, sum / _count, max(_count - ddof, 0LL))',
    'a + b', 'out = a', '0', '_nanvar_core', preamble=_nanvar_preamble)


cdef _nanvar_core_out = ReductionKernel(
    'S x, T sum, int64 _count, int64 ddof', 'U out',
    'nanvar_impl<S, T>(x, sum / _count, max(_count - ddof, 0LL))',
    'a + b', 'out = a', '0', '_nanvar_core', preamble=_nanvar_preamble)


# Variables to expose to Python
# (cythonized data cannot be exposed to Python, even with cpdef.)


amax = _amax
amin = _amin
