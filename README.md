# geolib
Common utilities for handling geographic coordinate system conversions and related calculations. Written in Erlang. The code originated in pentlandege/s4607_extra, but has been extracted to make it easier to use in a broader range of applications.

There are currently utilities for converting between coordinates specified as Latitude, Longitude and Altitude triples and ECEF (Earth Centred Earth Fixed) form.

There are also functions for performing Haversine (great circle) calculations such as computing the final destination given a starting point and an initial bearing.

# Building
Compile the code and run the unit tests using rebar:
```
rebar compile eunit
```

