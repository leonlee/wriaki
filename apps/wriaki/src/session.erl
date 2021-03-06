%% -------------------------------------------------------------------
%%
%% Copyright (c) 2009-2010 Basho Technologies, Inc.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------
-module(session).

-export([fetch/2,
         create/1,
         get_user/1,
         get_expiry/1,
         refresh/1,
         is_valid/1]).
-include("wriaki.hrl").

-define(F_USER, <<"username">>).
-define(F_EXPIRY, <<"expiry">>).

-define(EXTENSION, (60*60*6)). %% expire after 6hrs of inactivity

fetch(Client, Key) ->
    wrc:get(Client, ?B_SESSION, Key).

create(Username) when is_binary(Username) ->
    refresh(wobj:create(?B_SESSION, unique_id_62(),
                        {struct, [{?F_USER, Username}]})).

get_user(Session) ->
    wobj:get_json_field(Session, ?F_USER).

get_expiry(Session) ->
    wobj:get_json_field(Session, ?F_EXPIRY).

refresh(Session) ->
    wobj:set_json_field(Session, ?F_EXPIRY, now_secs()+?EXTENSION).

is_valid(Session) ->
    now_secs() < get_expiry(Session).

now_secs() ->
    calendar:datetime_to_gregorian_seconds(calendar:universal_time()).

%% @spec unique_id_62() -> string()
%% @doc Create a random identifying integer, returning its string
%%      representation in base 62.
%%      Slightly modified from riak_util
unique_id_62() ->
    Rand = crypto:sha(term_to_binary({make_ref(), now()})),
    <<I:160/integer>> = Rand,
    list_to_binary(base62_list(I)).

base62_list(I) -> base62_list(I,[]).
base62_list(I0, R0) ->
    D = I0 rem 62,
    I1 = I0 div 62,
    R1 = if D >= 36 ->
                 [D-36+$a|R0];
            D >= 10 ->
                 [D-10+$A|R0];
            true ->
                 [D+$0|R0]
         end,
    if I1 =:= 0 ->
            R1;
       true ->
            base62_list(I1, R1)
    end.
