"""
CTRL_PGW_MFC_POST_WRF
===========

Modules and Functions useful for dealing with WRF output.
Created by Sopan Kurkute

Output types:
    - NetCDF wrfout
    - tslists
    - ts output (time series and vertical profiles)
"""

__version__="1.0.0"
__author__="Sopan Kurkute"
__date__= "12 Nov 2017"
__all__ = ['read_tslist','WRF_timeseries','stagger_to_mass']
