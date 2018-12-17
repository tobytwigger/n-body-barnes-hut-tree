from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize
import numpy

ext_modules = [
    Extension(
        'src.area',
        ['src/area.pyx'],
        include_dirs=[numpy.get_include()]
    )
]

setup(
    name='area',
    package_data={
        '': ['src/area.pxd'],
    },
    ext_modules=cythonize(ext_modules)

)






ext_modules = [
    Extension(
        'src.node',
        ['src/node.pyx'],
        include_dirs=[numpy.get_include()]
    )
]

setup(
    name='node',
    package_data={
        '': ['src/node.pxd'],
    },
    ext_modules=cythonize(ext_modules)
)






ext_modules = [
    Extension(
        'src.bodies',
        ['src/bodies.pyx'],
        include_dirs=[numpy.get_include()]
    )
]

setup(
    name='bodies',
    package_data={
        '': ['src/bodies.pxd'],
    },
    ext_modules=cythonize(ext_modules)
)






ext_modules = [
    Extension(
        'src.bhtree',
        ['src/bhtree.pyx'],
        include_dirs=[numpy.get_include()]
    )
]

setup(
    name='bhtree',
    package_data={
        '': ['src/bhtree.pxd'],
    },
    ext_modules=cythonize(ext_modules)
)






ext_modules = [
    Extension(
        'src.main',
        ['src/main.pyx'],
        include_dirs=[numpy.get_include()]
    )
]

setup(
    name='main',
    package_data={
        '': ['src/main.pxd'],
    },
    ext_modules=cythonize(ext_modules)
)