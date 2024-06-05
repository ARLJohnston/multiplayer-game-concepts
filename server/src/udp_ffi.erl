-module(udp_ffi).

-export([udp_open/1, udp_send/4, udp_close/1, udp_recv/2]).

%% Open in binary to allow decoding to a BitArray
udp_open(Port) ->
    normalise(gen_udp:open(Port, [binary])).

udp_send(Socket, Target_ip, Target_port, Data) ->
    normalise(gen_udp:send(Socket, Target_ip, Target_port, Data)).

udp_recv(Socket, Length) ->
    normalise(gen_udp:recv(Socket, Length)).

udp_close(Socket) ->
    normalise(gen_udp:close(Socket)).

%% Transforms {ok||err, obj} to a Gleam Result
normalise(ok) ->
    {ok, nil};
normalise({ok, T}) ->
    {ok, T};
normalise({error, {timeout, _}}) ->
    {error, timeout};
normalise({error, _} = E) ->
    E.
