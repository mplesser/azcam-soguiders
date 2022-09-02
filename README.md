# azcam-soguiders

This repository contains *azcam-soguiders* *azcam* environment. It contains code and data files for the Steward Observatory guide cameras.

## Installation

Download the code (usually into the *azcam* root folder such as `c:\azcam`) and install via  poetry.

```shell
cd /azcam
git clone https://github.com/mplesser/azcam-soguiders
cd azcam-soguiders
poetry install
```

## Code

*guider.tcl* is Tcl/k application written by Gary Schmidt for the Steward Observatory guide cameras. Code additions and modifications have been provided by Grant Williams and Michael Lesser. It is currently maintained by Michael Lesser for use with AzCam cameras.

Both ITL "Magellan" and Astronomical Research Corporation "Gen3" camera controllers are supported with a variety of CCD sensors.
