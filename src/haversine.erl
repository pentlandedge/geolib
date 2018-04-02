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
-module(haversine).

-export([distance/2, initial_bearing/2, destination/3, fmod/2]).

%% Mean radius of the earth used for haversine
-define(EARTH_MEAN_RAD, 6371000).

%% Calculate the great circle distance between two points using the haversine 
%% formula. Reference http://www.movable-type.co.uk/scripts/latlong.html.
distance({Lat1, Lon1}, {Lat2, Lon2}) ->
    LatRad1 = coords:deg_to_rad(Lat1), 
    LonRad1 = coords:deg_to_rad(Lon1), 
    LatRad2 = coords:deg_to_rad(Lat2), 
    LonRad2 = coords:deg_to_rad(Lon2), 
    
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
    LatRad1 = coords:deg_to_rad(Lat1), 
    LonRad1 = coords:deg_to_rad(Lon1), 
    LatRad2 = coords:deg_to_rad(Lat2), 
    LonRad2 = coords:deg_to_rad(Lon2), 
    
    DeltaLon = LonRad2 - LonRad1, 
    Y = math:sin(DeltaLon) * math:cos(LatRad2),
    X = math:cos(LatRad1) * math:sin(LatRad2) - 
        math:sin(LatRad1) * math:cos(LatRad2) * math:cos(DeltaLon),

    RadBearing = math:atan2(Y, X),
    DegBearing = coords:rad_to_deg(RadBearing),
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
    LatRad1 = coords:deg_to_rad(StartLat), 
    LonRad1 = coords:deg_to_rad(StartLon), 
    BearRad = coords:deg_to_rad(Bearing),

    AngDist = Distance/?EARTH_MEAN_RAD,

    Prod1 = math:sin(LatRad1) * math:cos(AngDist), 
    Prod2 = math:cos(LatRad1) * math:sin(AngDist) * math:cos(BearRad),
    LatRad2 = math:asin(Prod1 + Prod2),

    Term1 = math:sin(BearRad) * math:sin(AngDist) * math:cos(LatRad1),
    Term2 = math:cos(AngDist) - math:sin(LatRad1) * math:sin(LatRad2),
    LonRad2 = LonRad1 + math:atan2(Term1, Term2),

    %% Convert angles back to degrees and normalise.
    LatDeg = coords:rad_to_deg(LatRad2),
    LonDeg = coords:rad_to_deg(LonRad2),
    NormLonDeg = fmod((LonDeg + 540.0), 360.0) - 180.0,  
    {LatDeg, NormLonDeg}.

%% Calculate the floating point remainder. Referenced rvirding's luerl.
fmod(X, Y) ->
    Div = float(trunc(X/Y)),
    Rem = X - Div*Y,
    Rem.

