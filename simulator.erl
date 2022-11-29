-module(simulator).
-export[start/0].

start() ->
    io:fwrite("\n\n Simulator Running\n\n"),
    {ok, [NumClients]} = io:fread("\nNumber of clients to simulate: ", "~s\n"),
    {ok, [MaxSubscribers]} = io:fread("\nMaximum Number of Subscribers a client can have: ", "~s\n"),
    {ok, [DisconnectClients]} = io:fread("\nPercentage of clients to disconnect to simulate periods of live connection and disconnection ", "~s\n"),

    Clients = startClient(NumClients),

    % register all clients:
    registerClients(Clients, Clients),
    
    %start time
    Start_Time = erlang:system_time(millisecond),
    checkAliveClients(Clients),
    %End time
    End_Time = erlang:system_time(millisecond),
    io:format("\nTime Taken to Converge: ~p milliseconds\n", [End_Time - Start_Time]).

checkAliveClients(Clients) ->
    Alive_Clients = [{C, C_PID} || {C, C_PID} <- Clients, is_process_alive(C_PID) == true],
    if
        Alive_Clients == [] ->
            io:format("\nCONVERGED: ");
        true ->
            checkAliveClients(Alive_Clients)
    end.

registerClients(Clients, AllClients) ->
    [{_, ClientPID}|Remaning_Clients] = Clients,
    ClientPID ! {self(), {register, AllClients}},
    registerClients(Remaning_Clients, AllClients).

startClient(NumClients) ->
    
    Clients = [  % { {Pid, Ref}, Id }
        {Id, spawn(client, test, [Id])}
        || Id <- lists:seq(1, NumClients)
    ],
    Clients.

% Simulate as many users as you can
% Simulate periods of live connection and disconnection for users
% Simulate a Zipf distribution on the number of subscribers. 
% For accounts with a lot of subscribers, increase the number of tweets. 
% Make some of these messages re-tweets
