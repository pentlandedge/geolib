# geolib
Common utilities for handling geographic coordinate system conversions and related calculations. Written in Erlang. The code originated in pentlandege/s4607_extra, but has been extracted to make it easier to use in a broader range of applications.

There are currently utilities for converting between coordinates specified as Latitude, Longitude and Altitude triples and ECEF (Earth Centred Earth Fixed) form.

There are also functions for performing Haversine (great circle) calculations such as computing the final destination given a starting point and an initial bearing.

## Prerequisites
It is necessary to have Erlang installed, and the compiler erlc available on the path. The rebar3 tool is used to control the build process, so it is necessary to have this installed and on the path too. 

If using the (optional) Makefile, then the make utility must be available.

## Building

The simplest way to build the software, run the unit tests, perform static analysis and generate the module documentation in one step is to use make:
```
# make
```
The makefile has rules for each of these steps which can be run separately if preferred. It uses rebar3 to do the real work.

Alternatively, the software can be compiled (on a Linux platform) directly using rebar3:
```
# rebar3 compile
```

