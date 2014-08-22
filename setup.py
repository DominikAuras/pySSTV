# -*- encoding: utf-8 -*-

from setuptools import setup
from distutils.extension import Extension

from distutils.command.sdist import sdist as _sdist

cmdclass = {}

class sdist(_sdist):
  def run(self):
    # Make sure the compiled Cython files in the distribution are up-to-date
    from Cython.Build import cythonize
    cythonize(['pysstv/sstv.pyx'])
    _sdist.run(self)
        
cmdclass['sdist'] = sdist

setup(
    cmdclass = cmdclass,
    name='PySSTV',
    version='0.2.5cy',
    description='Python classes for generating Slow-scan Television transmissions',
    author=u'András Veres-Szentkirályi',
    author_email='vsza@vsza.hu',
    url='https://github.com/dnet/pySSTV',
    packages=['pysstv', 'pysstv.tests', 'pysstv.examples'],
    keywords='HAM SSTV slow-scan television Scottie Martin Robot',
    install_requires = ['pillowfight',],
    license='MIT',
    ext_modules = [Extension("pysstv.sstv",["pysstv/sstv.c"])],
    classifiers=[
        'Development Status :: 4 - Beta',
        'Topic :: Communications :: Ham Radio',
        'Topic :: Multimedia :: Video :: Conversion',
        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
        ],
    long_description=open('README.md').read(),
    entry_points={
        'console_scripts': [
            'pysstv = pysstv.__main__:main'
        ],
    },
)
