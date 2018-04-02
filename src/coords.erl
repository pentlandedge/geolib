%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Copyright 2018 Pentland Edge Ltd.
%%
%% Licensed under the Apache License, Version 2.0 (the "License"); you may not
%% use this file except in compliance with the License. 
%% You may obtain a copy of the License at
%%
%% http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software 
%% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT 
%% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the 
%% License for the specific language governing permissions and limitations 
%% under the License.
%%
-module(coords).

-export([
    lla_to_ecef/1, 
    signed_lon/1,
    ecef_distance/2,
    enu_distance/2,
    deg_to_rad/1, 
    rad_to_deg/1, 
    ecef_to_enu/2,
    calc_angle/3,
    dot_product/2,
    vec_mag/1,
    dec_to_dms/1,
    dms_to_dec/1]).

%% WGS84 constants.
-define(WGS84_A, 6378137).
-define(WGS84_B, 6356752.31424518).

%% Function to convert from Lat, Lon, Alt to ECEF format
lla_to_ecef({Lat,Lon,Alt}) ->

    % Convert the Lat, Lon into radians.
    LatRad = deg_to_rad(Lat),
    LonRad = deg_to_rad(Lon),

    % Need to check that this height is from the correct reference.
    H = Alt,

    Asquared = ?WGS84_A * ?WGS84_A,
    Bsquared = ?WGS84_B * ?WGS84_B,
    Esquared = (Asquared - Bsquared) / Asquared, 

    SinLat = math:sin(LatRad),
    CosLat = math:cos(LatRad),
    SinLon = math:sin(LonRad),
    CosLon = math:cos(LonRad),

    % Calculate the radius of curvature
    N = ?WGS84_A / math:sqrt(1 - Esquared * SinLat * SinLat),

    % Calculate the coordinate points.
    X = (N + H) * CosLat * CosLon,
    Y = (N + H) * CosLat * SinLon,
    Z = ((Bsquared/Asquared) * N + H) * SinLat, 

    {X, Y, Z}.

%% Convert Longitude to signed degrees format
signed_lon(Lon) ->

    case Lon > 180.0 of
        true -> Lon - 360.0;
        false -> Lon
    end.

%% @doc Calculate the magnitude of the difference between two points 
%% specified in ECEF format.
ecef_distance({X1, Y1, Z1}, {X2, Y2, Z2}) ->
    T1 = math:pow(X2 - X1, 2),
    T2 = math:pow(Y2 - Y1, 2),
    T3 = math:pow(Z2 - Z1, 2),
    math:sqrt(T1 + T2 + T3).

%% @doc Calculate the magnitude of the difference between two points 
%% specified in ENU format.
enu_distance(Pt1, Pt2) ->
    % Can reuse ECEF distance since both are vector magnitude calculations.
    ecef_distance(Pt1, Pt2).

deg_to_rad(Deg) ->
    Deg * math:pi() / 180.

rad_to_deg(Rad) ->
    Rad * 180 / math:pi().

%% Convert ECEF coordinates to ENU (East, North, Up) local plane.
%% Based on the formulae at:
%% http://wiki.gis.com/wiki/index.php/Geodetic_system#From_WGS-84_to_ENU:_sample_code
ecef_to_enu({RefLat,RefLon,RefH}, {X, Y, Z}) ->
    % Find reference location in ECEF.
    {Xr, Yr, Zr} = lla_to_ecef({RefLat,RefLon,RefH}),

    % Convert the Lat, Lon into radians.
    LatRad = deg_to_rad(RefLat),
    LonRad = deg_to_rad(RefLon),

    SinRefLat = math:sin(LatRad), 
    SinRefLon = math:sin(LonRad), 
    CosRefLat = math:cos(LatRad), 
    CosRefLon = math:cos(LonRad), 

    Xdiff = X - Xr,
    Ydiff = Y - Yr,
    Zdiff = Z - Zr,

    E = -SinRefLon*Xdiff + CosRefLon*Ydiff,
    N = -SinRefLat*CosRefLon*Xdiff - SinRefLat*SinRefLon*Ydiff + CosRefLat*Zdiff,
    U = CosRefLat*CosRefLon*Xdiff + CosRefLat*SinRefLon*Ydiff + SinRefLat*Zdiff,
    
    {E, N, U}.

%% Calculate the angle between two points from a common origin. Return value
%% is in radians. Arguments must be supplied in ECEF format.
calc_angle({X1,Y1,Z1} = _Orig, {X2,Y2,Z2} = _A, {X3,Y3,Z3} = _B) ->
    % Create vectors OA and OB.
    OA = {X2-X1, Y2-Y1, Z2-Z1},
    OB = {X3-X1, Y3-Y1, Z3-Z1},
    % Calculate the dot product of the two vectors.
    DotProd = dot_product(OA, OB),
    % Calculate vector magnitudes.
    MagOA = vec_mag(OA),
    MagOB = vec_mag(OB),
    % Compute the angle.
    math:acos(DotProd / (MagOA * MagOB)).


%% Calculate the dot product of two vectors.
dot_product({X1, Y1, Z1}, {X2, Y2, Z2}) ->
    X1*X2 + Y1*Y2 + Z1*Z2.

%% Calculate the magnitude of a vector.
vec_mag({X, Y, Z}) ->
    math:sqrt(X*X + Y*Y + Z*Z).

%% Convert a decimal coordinate to {degrees,minutes,seconds}.
dec_to_dms(Dec) ->
    Deg = trunc(Dec),
    MinF = abs(Dec - Deg),
    Min = trunc(60.0 * MinF),
    SecF = MinF - (Min / 60.0),
    Sec = 3600.0 * SecF,
    {Deg,Min,Sec}.

dms_to_dec({H,M,S}) ->
    Mag = abs(H) + (M / 60.0) + (S / 3600.0),
    case H >= 0 of
        true  -> Mag;
        false -> -Mag
    end.

