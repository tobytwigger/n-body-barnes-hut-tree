from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize
import numpy



ext_modules = [
    Extension(
        'src.node',
        ['src/node.pyx'],
        include_dirs=[numpy.get_include(), 'src'],
        # define_macros=[
        #     ("NPY_NO_DEPRECATED_API", "NPY_1_7_API_VERSION"),
        # ]
    ),
    Extension(
        'src.galaxy',
        ['src/galaxy.pyx'],
        include_dirs=[numpy.get_include(), 'src'],
        # define_macros=[
        #     ("NPY_NO_DEPRECATED_API", "NPY_1_7_API_VERSION"),
        # ]
    ),
    Extension(
        'src.bhtree',
        ['src/bhtree.pyx'],
        include_dirs=[numpy.get_include(), 'src'],
        # define_macros=[
        #     ("NPY_NO_DEPRECATED_API", "NPY_1_7_API_VERSION"),
        # ]
    ),
    Extension(
        'src.main',
        ['src/main.pyx'],
        include_dirs=[numpy.get_include(), 'src'],
        # define_macros=[
        #     ("NPY_NO_DEPRECATED_API", "NPY_1_7_API_VERSION"),
        # ]
    ),
    Extension(
        'analysis.plotting',
        ['analysis/plotting.pyx'],
        include_dirs=[numpy.get_include(), 'plotting'],
        # define_macros=[
        #     ("NPY_NO_DEPRECATED_API", "NPY_1_7_API_VERSION"),
        # ]
    )
]

setup(
    name='universe',
    package_data = {
        'node': ['src/node.pxd'],
        'galaxy': ['src/galaxy.pxd'],
        'bhtree': ['src/bhtree.pxd'],
        'main': ['src/main.pxd']
    },
    ext_modules=cythonize(ext_modules, language_level=3)#, annotate=True)
)

