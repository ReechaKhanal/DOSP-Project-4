-module(twitter_engine).
-export[start/0].

start() ->
    io:fwrite("\n\n Howdy!!, I am The Twitter Engine Clone \n\n"),
    {ok, ListenSocket} = gen_tcp:listen(1204, [binary, {keepalive, true}, {reuseaddr, true}, {active, once}]),
    await_connections(ListenSocket).

await_connections(Listen) ->
    {ok, Socket} = gen_tcp:accept(Listen),
    ok = gen_tcp:send(Socket, "YIP"),
    spawn(fun() -> await_connections(Listen) end),
    conn_loop(Socket).

conn_loop(Socket) ->
    io:fwrite("Uh Oh, I can sense someone trying to connect to me!\n\n"),
    receive
        {Socket, Data} ->
            io:fwrite("\n"),
            io:fwrite(Data),
            io:fwrite("\n");
        {register_account, Socket, Data} ->
            io:fwrite("Client wants to register an account");
        {send_tweet, Socket, Data} ->
            io:fwrite("Client wants to register an account");
        {subscribe, Socket, Data} ->
            io:fwrite("Client wants to register an account");
        {re_tweet, Socket, Data} ->
            io:fwrite("Client wants to register an account");
        {query_tweet, Socket, Data} ->
            io:fwrite("Client wants to register an account");
        {tcp_closed, Socket} ->
            closed
    end.





% Implement a twitter-like engine with following functionality:
% 1. Register Account
% 2. Send Tweet
%      - tweets can have hashtags (e.g., #COP5615isgreat) and mentions (@bestuser)
% 3. Subscribe to user's tweet
% 4. Re-tweets
% 5. Allow querying tweets subscribed to, tweets with specific hashtags, 
%    tweets in which the user is mentioned (my mentions)
% 
% 6. If the user is connected, deliver the above types of tweets live (without querying)
% 7. Simulate as many users as you can
% 8. Simulate periods of live connection and disconnection for users
% 
% 9. Simulate a Zipf distribution on the number of subscribers. For accounts with a lot of subscribers
%    increase the number of tweets -- make some of these messages re-tweets.
%     
% 10. Other Considerations:
%     1. The client part (send/receive tweets) and the engine (distribute tweets)
%        have to be in seperate processes.
%         
%     2. Preferably, you use multiple independent client processes that simulate
%        thousands of clients and a single-engine process
%        
%     3. You need to measure various aspects of your simulator and report performance 
%     
%     4. Submit your code and a report with performance numbers with instructions on how to run it.