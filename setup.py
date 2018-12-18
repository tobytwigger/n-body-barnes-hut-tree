from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize
import numpy

ext_modules = [
    Extension(
        'src.area',
        ['src/area.pyx'],
        include_dirs=[numpy.get_include(), '.', 'src']
    ),
    Extension(
        'src.node',
        ['src/node.pyx'],
        include_dirs=[numpy.get_include(), '.', 'src']
    ),
    Extension(
        'src.bodies',
        ['src/bodies.pyx'],
        include_dirs=[numpy.get_include(), '.', 'src']
    ),
    Extension(
        'src.bhtree',
        ['src/bhtree.pyx'],
        include_dirs=[numpy.get_include(), '.', 'src']
    ),
    Extension(
        'src.main',
        ['src/main.pyx'],
        include_dirs=[numpy.get_include(), '.', 'src']
    )
]

setup(
    name='universe',
    package_data={
        'area': ['src/area.pxd'],
        'node': ['src/node.pxd'],
        'bodies': ['src/bodies.pxd'],
        'bhtree': ['src/bhtree.pxd'],
        'main': ['src/main.pxd'],
    },
    ext_modules=cythonize(ext_modules, language_level=3, annotate=True)
)