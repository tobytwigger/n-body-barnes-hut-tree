from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize
import numpy



ext_modules = [
    Extension(
        'numpyarange',
        ['numpyarange.pyx'],
        include_dirs=[numpy.get_include(), '.'],
        define_macros=[
            ("NPY_NO_DEPRECATED_API", "NPY_1_7_API_VERSION"),
        ]
    )
]

setup(
    name='tests',
    package_data = {
      'numpy-arange': ['numpyarange.pxd']
    },
    ext_modules=cythonize(ext_modules, language_level=3, annotate=True)
)

