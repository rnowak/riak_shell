%% -------------------------------------------------------------------
%%
%% connection management extension for riakshell
%%
%% Copyright (c) 2007-2016 Basho Technologies, Inc.  All Rights Reserved.
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
-module(connection_EXT).

-include("riakshell.hrl").

-export([
         help/1
        ]).

-export([
         show_cookie/1,
         show_nodes/1,
         reconnect/1,
         connect/2,
         ping/1,
         ping/2,
         connection_prompt/2,
         show_connection/1
        ]).

help(show_nodes) ->
    "Type 'show_nodes;' to see which nodes riakshell is connected to.";
help(show_cookie) ->
    "Type 'show_cookie;' to see what the Erlang cookie is for riakshell. The riakshell needs to have the same cookie as the riak nodes you are connecting to.";
help(ping) ->
    "Typing 'ping;' will ping all the nodes specified in the config file and print the results. Typing 'ping \"dev1@127.0.0.1\"; will ping a particular node. You need to replace dev1 etc with your actual node name";
help(reconnect) ->
    "Typing 'reconnect;' will try to connect you to one of the nodes listed in your riakshell.config. It will try each node until it succeeds (or doesn't). To connect to a specific node (or one not in your riakshell.config please use the connect command.";
help(connect) ->
    "You can connect to a specific node (whether in your riakshell.config or not) by typing 'connect \"dev1@127.0.0.1\";' substituting your node name for dev1. You may need to change the Erlang cookie to do this. There is a command 'reconnect' which can be used to try all the nodes in your riakshell.config file.";
help(connection_prompt) ->
    "Type 'connection_prompt on;' to display the connection status in the prompt, or 'connection_prompt off; to disable it";
help(show_connection) ->
    "This shows which riak nodes riakshell is connected to".

show_nodes(State) ->
    Msg = io_lib:format("The connected nodes are: ~p", [nodes()]),
    {Msg, State}.

show_cookie(#state{cookie = Cookie} = State) ->
    Msg = io_lib:format("Cookie is ~p ~p", [Cookie, erlang:get_cookie()]),
    {Msg, State}.

ping(#state{config = Config} = State) ->
    Nodes = riakshell_shell:read_config(Config, nodes, []),
    FoldFn = fun(Node, {Msg, S}) ->
                     {Msg2, S2} = ping2(S, Node),
                     {[Msg2] ++ Msg, S2}
             end,
    {Msgs2, S2} = lists:foldl(FoldFn, {[], State}, Nodes),
    {string:join(Msgs2, "\n"), S2#state{log_this_cmd = false}}.

ping(State, Node) ->
    N = list_to_atom(Node),
    ping2(State#state{log_this_cmd = false}, N).

ping2(State, Node) ->
    Msg = case net_adm:ping(Node) of
              pong -> io_lib:format("~p: " ++ ?GREENTICK ++ " ", [Node]);
              pang -> io_lib:format("~p: " ++ ?REDCROSS  ++ " ", [Node])
          end,
    {Msg, State}.
    
show_connection(#state{has_connection = false} = State) ->
    {"Riakshell is not connected to riak", State};
show_connection(#state{has_connection = true,
                       connection     = {Node, Port}} = State) ->
    Msg = io_lib:format("Riakshell is connected to: ~p on port ~p", 
                        [Node, Port]), 
    {Msg, State}. 

reconnect(S) ->
    Reply = connection_srv:reconnect(),
    Msg = io_lib:format("~p", [Reply]),
    {Msg, S}.

connect(S, Node) when is_atom(Node) ->
    Reply = connection_srv:connect([Node]),
    Msg = io_lib:format("~p", [Reply]),
    {Msg, S};
connect(S, Node) ->
    Msg = io_lib:format("Error: node has to be an atom ~p", [Node]),
    {Msg, S#state{cmd_error = true}}.

connection_prompt(State, on) ->
    Msg = io_lib:format("Connection Prompt turned on", []),
    {Msg, State#state{show_connection_status = true}};
connection_prompt(State, off) ->
    Msg = io_lib:format("Connection Prompt turned off", []),
    {Msg, State#state{show_connection_status = false}};
connection_prompt(State, Toggle) ->
    ErrMsg = io_lib:format("Invalid parameter passed to connection_prompt ~p. Should be 'off' or 'on'.", [Toggle]),
    {ErrMsg, State#state{cmd_error = true}}.
                              