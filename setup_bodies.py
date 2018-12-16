from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize

ext_modules = [
    Extension(
        'bodies',
        ['bodies.pyx']
    )
]

setup(name='bodies', ext_modules=cythonize(ext_modules))