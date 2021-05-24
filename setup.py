from setuptools import find_packages, setup

with open("README.md", "r") as fh:
    long_description = fh.read()

setup(
    name="azcam-soguiders",
    version="21.0",
    description="azcam-soguiders",
    long_description_content_type="text/markdown",
    long_description=long_description,
    author="Michael Lesser",
    author_email="mlesser@arizona.edu",
    keywords="ccd imaging astronomy observation observatory",
    packages=find_packages(),
    zip_safe=False,
    url="https://mplesser.github.io/azcam/",
)
