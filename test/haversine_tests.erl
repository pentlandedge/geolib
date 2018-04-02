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

-module(haversine_tests).

-include_lib("eunit/include/eunit.hrl").

%% Define a test generator function to run all the tests. 
haversine_test_() ->
    [haversine_checks(), initial_bearing_checks(), destination_checks()].

haversine_checks() ->
    Pt1 = {55.9987, -2.71},
    Pt2 = {56.001, -2.734},
    Dist = haversine:distance(Pt1, Pt2),

    [?_assert(almost_equal(1514, Dist, 1))].

initial_bearing_checks() ->
    Pt1 = {55.9987, -2.71},
    Pt2 = {56.001, -2.734},
    Bearing = haversine:initial_bearing(Pt1, Pt2),

    [?_assert(almost_equal(279.735, Bearing, 0.001))].

destination_checks() ->
    Pt1 = {55.9987, -2.71},
    Bearing = 279.735,
    Distance = 1514,

    Destination = haversine:destination(Pt1, Bearing, Distance),
    {Lat, Lon} = Destination,

    [?_assert(almost_equal(56.001, Lat, 0.001)),
     ?_assert(almost_equal(-2.734, Lon, 0.001))].
    
%% Utility function to compare whether floating point values are within a 
%% specified range.
almost_equal(V1, V2, Delta) ->
    abs(V1 - V2) =< Delta.
 
