-module(simulator).
-export[start/0].

start() ->
    io:fwrite("\n\n Simulator Running\n\n"),
    {ok, [Number_of_Clients]} = io:fread("\nNumber of clients to simulate: ", "~s\n"),
    Clients = startClient(Number_of_Clients),

    CommandType = ["tweet", "retweet", "subscribe", "query"],
    QueryType = ["1", "2", "3"],

    Clients.

startClient(Number_of_Clients) ->
    
    Clients = [  % { {Pid, Ref}, Id }
        {Id, spawn(client, test, [Id])}
        || Id <- lists:seq(1, Number_of_Clients)
    ],
    Clients.

% Simulate as many users as you can
% Simulate periods of live connection and disconnection for users
% Simulate a Zipf distribution on the number of subscribers. 
% For accounts with a lot of subscribers, increase the number of tweets. 
% Make some of these messages re-tweets
