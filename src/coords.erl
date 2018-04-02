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
    haversine_distance/2,
    initial_bearing/2,
    destination/3,
    ecef_to_enu/2,
    fmod/2, 
    calc_angle/3,
    dot_product/2,
    vec_mag/1,
    dec_to_dms/1,
    dms_to_dec/1]).

%% WGS84 constants.
-define(WGS84_A, 6378137).
-define(WGS84_B, 6356752.31424518).

%% Mean radius of the earth used for haversine
-define(EARTH_MEAN_RAD, 6371000).

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

%% Calculate the great circle distance between two points using the haversine 
%% formula. Reference http://www.movable-type.co.uk/scripts/latlong.html.
haversine_distance({Lat1, Lon1}, {Lat2, Lon2}) ->
    LatRad1 = deg_to_rad(Lat1), 
    LonRad1 = deg_to_rad(Lon1), 
    LatRad2 = deg_to_rad(Lat2), 
    LonRad2 = deg_to_rad(Lon2), 
    
    DeltaLat = LatRad2 - LatRad1, 
    DeltaLon = LonRad2 - LonRad1, 

    SinHalfDLat = math:sin(DeltaLat/2),
    SinSqHalfDLat = SinHalfDLat * SinHalfDLat,  

    SinHalfDLon = math:sin(DeltaLon/2),
    SinSqHalfDLon = SinHalfDLon * SinHalfDLon, 

    A = SinSqHalfDLat + math:cos(LatRad1) * math:cos(LatRad2) * SinSqHalfDLon, 
    C = 2 * math:atan2(math:sqrt(A), math:sqrt(1-A)),
    Distance = ?EARTH_MEAN_RAD * C,
    Distance.

%% Calculates the initial bearing on the great circle path from point 1 to 
%% point 2.
%% θ = atan2(sin Δλ ⋅ cos φ2 , cos φ1 ⋅ sin φ2 − sin φ1 ⋅ cos φ2 ⋅ cos Δλ)
%% where λ = Lon, φ = Lat.
%% Angles in radians.
%% The output from the atan2 is converted from +-180 to 0-360 degrees.
initial_bearing({Lat1, Lon1}, {Lat2, Lon2}) ->
    LatRad1 = deg_to_rad(Lat1), 
    LonRad1 = deg_to_rad(Lon1), 
    LatRad2 = deg_to_rad(Lat2), 
    LonRad2 = deg_to_rad(Lon2), 
    
    DeltaLon = LonRad2 - LonRad1, 
    Y = math:sin(DeltaLon) * math:cos(LatRad2),
    X = math:cos(LatRad1) * math:sin(LatRad2) - 
        math:sin(LatRad1) * math:cos(LatRad2) * math:cos(DeltaLon),

    RadBearing = math:atan2(Y, X),
    DegBearing = rad_to_deg(RadBearing),
    case DegBearing >= 0.0 of
        true -> DegBearing;
        _    -> DegBearing + 360.0
    end.
     
%% Calculate the destination given a start point, bearing and distance along
%% a great circle arc.
%% From http://www.movable-type.co.uk/scripts/latlong.html
%% φ2 = asin( sin φ1 ⋅ cos δ + cos φ1 ⋅ sin δ ⋅ cos θ )
%% λ2 = λ1 + atan2( sin θ ⋅ sin δ ⋅ cos φ1, cos δ − sin φ1 ⋅ sin φ2 )
%% where where  φ is latitude, λ is longitude, θ is the bearing (clockwise 
%% from north), δ is the angular distance d/R; d being the distance travelled, 
%% R the earth’s radius.
destination({StartLat, StartLon}, Bearing, Distance) ->
    LatRad1 = deg_to_rad(StartLat), 
    LonRad1 = deg_to_rad(StartLon), 
    BearRad = deg_to_rad(Bearing),

    AngDist = Distance/?EARTH_MEAN_RAD,

    Prod1 = math:sin(LatRad1) * math:cos(AngDist), 
    Prod2 = math:cos(LatRad1) * math:sin(AngDist) * math:cos(BearRad),
    LatRad2 = math:asin(Prod1 + Prod2),

    Term1 = math:sin(BearRad) * math:sin(AngDist) * math:cos(LatRad1),
    Term2 = math:cos(AngDist) - math:sin(LatRad1) * math:sin(LatRad2),
    LonRad2 = LonRad1 + math:atan2(Term1, Term2),

    %% Convert angles back to degrees and normalise.
    LatDeg = rad_to_deg(LatRad2),
    LonDeg = rad_to_deg(LonRad2),
    NormLonDeg = fmod((LonDeg + 540.0), 360.0) - 180.0,  
    {LatDeg, NormLonDeg}.

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

%% Calculate the floating point remainder. Referenced rvirding's luerl.
fmod(X, Y) ->
    Div = float(trunc(X/Y)),
    Rem = X - Div*Y,
    Rem.

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

