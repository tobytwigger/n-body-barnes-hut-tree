from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize
import numpy



ext_modules = [
    Extension(
        'src.node',
        ['src/node.pyx'],
        include_dirs=[numpy.get_include(), 'src']
    ),
    Extension(
        'src.galaxy',
        ['src/galaxy.pyx'],
        include_dirs=[numpy.get_include(), 'src']
    ),
    Extension(
        'src.bhtree',
        ['src/bhtree.pyx'],
        include_dirs=[numpy.get_include(), 'src']
    ),
    Extension(
        'src.main',
        ['src/main.pyx'],
        include_dirs=[numpy.get_include(), 'src']
    ),
    Extension(
        'analysis.plotting',
        ['analysis/plotting.pyx'],
        include_dirs=[numpy.get_include(), 'plotting']
    )
]

setup(
    name='galaxy',
    package_data = {
        'node': ['src/node.pxd'],
        'galaxy': ['src/galaxy.pxd'],
        'bhtree': ['src/bhtree.pxd'],
        'main': ['src/main.pxd']
    },
    ext_modules=cythonize(ext_modules, language_level=3)
)

