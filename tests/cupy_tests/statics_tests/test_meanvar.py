import unittest

import numpy

import cupy
from cupy import testing


@testing.gpu
class TestAverage(unittest.TestCase):

    _multiprocess_can_split_ = True

    @testing.for_all_dtypes()
    @testing.numpy_cupy_allclose()
    def test_average_all(self, xp, dtype):
        a = testing.shaped_arange((2, 3), xp, dtype)
        return xp.average(a)

    @testing.for_all_dtypes()
    @testing.numpy_cupy_allclose()
    def test_average_axis(self, xp, dtype):
        a = testing.shaped_arange((2, 3, 4), xp, dtype)
        return xp.average(a, axis=1)

    @testing.for_all_dtypes()
    @testing.numpy_cupy_allclose()
    def test_average_weights(self, xp, dtype):
        a = testing.shaped_arange((2, 3), xp, dtype)
        w = testing.shaped_arange((2, 3), xp, dtype)
        return xp.average(a, weights=w)

    @testing.for_all_dtypes()
    @testing.numpy_cupy_allclose()
    def test_average_axis_weights(self, xp, dtype):
        a = testing.shaped_arange((2, 3, 4), xp, dtype)
        w = testing.shaped_arange((2, 3, 4), xp, dtype)
        return xp.average(a, axis=2, weights=w)

    def check_returned(self, a, axis, weights):
        average_cpu, sum_weights_cpu = numpy.average(
            a, axis, weights, returned=True)
        result = cupy.average(
            cupy.asarray(a), axis, weights, returned=True)
        self.assertTrue(isinstance(result, tuple))
        self.assertEqual(len(result), 2)
        average_gpu, sum_weights_gpu = result
        testing.assert_allclose(average_cpu, average_gpu)
        testing.assert_allclose(sum_weights_cpu, sum_weights_gpu)

    @testing.for_all_dtypes()
    def test_returned(self, dtype):
        a = testing.shaped_arange((2, 3), numpy, dtype)
        w = testing.shaped_arange((2, 3), numpy, dtype)
        self.check_returned(a, axis=1, weights=None)
        self.check_returned(a, axis=None, weights=w)
        self.check_returned(a, axis=1, weights=w)


@testing.gpu
class TestMeanVar(unittest.TestCase):

    @testing.for_all_dtypes()
    @testing.numpy_cupy_allclose()
    def test_mean_all(self, xp, dtype):
        a = testing.shaped_arange((2, 3), xp, dtype)
        return a.mean()

    @testing.for_all_dtypes()
    @testing.numpy_cupy_allclose()
    def test_external_mean_all(self, xp, dtype):
        a = testing.shaped_arange((2, 3), xp, dtype)
        return xp.mean(a)

    @testing.for_all_dtypes()
    @testing.numpy_cupy_allclose()
    def test_mean_axis(self, xp, dtype):
        a = testing.shaped_arange((2, 3, 4), xp, dtype)
        return a.mean(axis=1)

    @testing.for_all_dtypes()
    @testing.numpy_cupy_allclose()
    def test_external_mean_axis(self, xp, dtype):
        a = testing.shaped_arange((2, 3, 4), xp, dtype)
        return xp.mean(a, axis=1)

    @testing.for_all_dtypes(no_complex=True)
    @testing.numpy_cupy_allclose()
    def test_var_all(self, xp, dtype):
        a = testing.shaped_arange((2, 3), xp, dtype)
        return a.var()

    @testing.for_all_dtypes(no_complex=True)
    @testing.numpy_cupy_allclose()
    def test_external_var_all(self, xp, dtype):
        a = testing.shaped_arange((2, 3), xp, dtype)
        return xp.var(a)

    @testing.for_all_dtypes(no_complex=True)
    @testing.numpy_cupy_allclose()
    def test_var_all_ddof(self, xp, dtype):
        a = testing.shaped_arange((2, 3), xp, dtype)
        return a.var(ddof=1)

    @testing.for_all_dtypes(no_complex=True)
    @testing.numpy_cupy_allclose()
    def test_external_var_all_ddof(self, xp, dtype):
        a = testing.shaped_arange((2, 3), xp, dtype)
        return xp.var(a, ddof=1)

    @testing.for_all_dtypes(no_complex=True)
    @testing.numpy_cupy_allclose()
    def test_var_axis(self, xp, dtype):
        a = testing.shaped_arange((2, 3, 4), xp, dtype)
        return a.var(axis=1)

    @testing.for_all_dtypes(no_complex=True)
    @testing.numpy_cupy_allclose()
    def test_external_var_axis(self, xp, dtype):
        a = testing.shaped_arange((2, 3, 4), xp, dtype)
        return xp.var(a, axis=1)

    @testing.for_all_dtypes(no_complex=True)
    @testing.numpy_cupy_allclose()
    def test_var_axis_ddof(self, xp, dtype):
        a = testing.shaped_arange((2, 3, 4), xp, dtype)
        return a.var(axis=1, ddof=1)

    @testing.for_all_dtypes(no_complex=True)
    @testing.numpy_cupy_allclose()
    def test_external_var_axis_ddof(self, xp, dtype):
        a = testing.shaped_arange((2, 3, 4), xp, dtype)
        return xp.var(a, axis=1, ddof=1)

    @testing.for_all_dtypes(no_complex=True)
    @testing.numpy_cupy_allclose()
    def test_std_all(self, xp, dtype):
        a = testing.shaped_arange((2, 3), xp, dtype)
        return a.std()

    @testing.for_all_dtypes(no_complex=True)
    @testing.numpy_cupy_allclose()
    def test_external_std_all(self, xp, dtype):
        a = testing.shaped_arange((2, 3), xp, dtype)
        return xp.std(a)

    @testing.for_all_dtypes(no_complex=True)
    @testing.numpy_cupy_allclose()
    def test_std_all_ddof(self, xp, dtype):
        a = testing.shaped_arange((2, 3), xp, dtype)
        return a.std(ddof=1)

    @testing.for_all_dtypes(no_complex=True)
    @testing.numpy_cupy_allclose()
    def test_external_std_all_ddof(self, xp, dtype):
        a = testing.shaped_arange((2, 3), xp, dtype)
        return xp.std(a, ddof=1)

    @testing.for_all_dtypes(no_complex=True)
    @testing.numpy_cupy_allclose()
    def test_std_axis(self, xp, dtype):
        a = testing.shaped_arange((2, 3, 4), xp, dtype)
        return a.std(axis=1)

    @testing.for_all_dtypes(no_complex=True)
    @testing.numpy_cupy_allclose()
    def test_external_std_axis(self, xp, dtype):
        a = testing.shaped_arange((2, 3, 4), xp, dtype)
        return xp.std(a, axis=1)

    @testing.for_all_dtypes(no_complex=True)
    @testing.numpy_cupy_allclose()
    def test_std_axis_ddof(self, xp, dtype):
        a = testing.shaped_arange((2, 3, 4), xp, dtype)
        return a.std(axis=1, ddof=1)

    @testing.for_all_dtypes(no_complex=True)
    @testing.numpy_cupy_allclose()
    def test_external_std_axis_ddof(self, xp, dtype):
        a = testing.shaped_arange((2, 3, 4), xp, dtype)
        return xp.std(a, axis=1, ddof=1)


@testing.parameterize(
    *testing.product({
        'shape': [(3, 4), (4, 3, 5)],
        'axis': [None, 0, 1],
        'keepdims': [True, False],
        'ddof': [0, 1]
    }))
@testing.gpu
class TestNanVarStd(unittest.TestCase):

    @testing.for_all_dtypes(no_float16=True, no_complex=True)
    @testing.numpy_cupy_allclose(rtol=1e-6)
    def test_nanvar(self, xp, dtype):
        a = testing.shaped_random(self.shape, xp, dtype=dtype)
        if a.dtype.kind not in 'biu':
            a[0, :] = xp.nan
        return xp.nanvar(
            a, axis=self.axis, ddof=self.ddof, keepdims=self.keepdims)

    @testing.for_all_dtypes(no_float16=True, no_complex=True)
    @testing.numpy_cupy_allclose(rtol=1e-6)
    def test_nanstd(self, xp, dtype):
        a = testing.shaped_random(self.shape, xp, dtype=dtype)
        if a.dtype.kind not in 'biu':
            a[0, :] = xp.nan
        return xp.nanstd(
            a, axis=self.axis, ddof=self.ddof, keepdims=self.keepdims)


@testing.gpu
class TestNanVarStdAdditional(unittest.TestCase):

    @testing.for_all_dtypes(no_float16=True, no_complex=True)
    @testing.numpy_cupy_allclose(rtol=1e-6)
    def test_nanvar_out(self, xp, dtype):
        a = testing.shaped_random((10, 20, 30), xp, dtype)
        z = xp.zeros((20, 30))

        if a.dtype.kind not in 'biu':
            a[1, :] = xp.nan
            a[:, 3] = xp.nan

        xp.nanvar(a, axis=0, out=z)
        return z

    @testing.slow
    @testing.for_all_dtypes(no_float16=True, no_complex=True)
    @testing.numpy_cupy_allclose(rtol=1e-6)
    def test_nanvar_huge(self, xp, dtype):
        a = testing.shaped_random((1024, 512), xp, dtype)

        if a.dtype.kind not in 'biu':
            a[:512, :256] = xp.nan

        return xp.nanvar(a, axis=1)

    @testing.numpy_cupy_allclose(rtol=1e-4)
    def test_nanvar_float16(self, xp):
        a = testing.shaped_arange((4, 5), xp, numpy.float16)
        a[0][0] = xp.nan
        return xp.nanvar(a, axis=0)

    @testing.for_all_dtypes(no_float16=True, no_complex=True)
    @testing.numpy_cupy_allclose(rtol=1e-6)
    def test_nanstd_out(self, xp, dtype):
        a = testing.shaped_random((10, 20, 30), xp, dtype)
        z = xp.zeros((20, 30))

        if a.dtype.kind not in 'biu':
            a[1, :] = xp.nan
            a[:, 3] = xp.nan

        xp.nanstd(a, axis=0, out=z)
        return z

    @testing.slow
    @testing.for_all_dtypes(no_float16=True, no_complex=True)
    @testing.numpy_cupy_allclose(rtol=1e-6)
    def test_nanstd_huge(self, xp, dtype):
        a = testing.shaped_random((1024, 512), xp, dtype)

        if a.dtype.kind not in 'biu':
            a[:512, :256] = xp.nan

        return xp.nanstd(a, axis=1)

    @testing.numpy_cupy_allclose(rtol=1e-4)
    def test_nanstd_float16(self, xp):
        a = testing.shaped_arange((4, 5), xp, numpy.float16)
        a[0][0] = xp.nan
        return xp.nanstd(a, axis=1)
