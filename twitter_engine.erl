-module(twitter_engine).
-import(maps, []).
-export[start/0].

start() ->
    io:fwrite("\n\n Howdy!!, I am The Twitter Engine Clone \n\n"),
    Table = ets:new(t, [ordered_set]),
    Map = maps:new(),
    {ok, ListenSocket} = gen_tcp:listen(1204, [binary, {keepalive, true}, {reuseaddr, true}, {active, false}]),
    await_connections(ListenSocket, Table).

await_connections(Listen, Table) ->
    {ok, Socket} = gen_tcp:accept(Listen),
    ok = gen_tcp:send(Socket, "YIP"),
    spawn(fun() -> await_connections(Listen, Table) end),
    %conn_loop(Socket).
    do_recv(Socket, Table, []).

do_recv(Socket, Table, Bs) ->
    io:fwrite("Do Receive\n\n"),
    case gen_tcp:recv(Socket, 0) of
        {ok, Data1} ->
            
            Data = re:split(Data1, ","),
            Type = binary_to_list(lists:nth(1, Data)),

            io:format("\n\nDATA: ~p\n\n ", [Data]),
            io:format("\n\nTYPE: ~p\n\n ", [Type]),

            if 
                Type == "register" ->
                    UserName = binary_to_list(lists:nth(2, Data)),

                    io:format("Type: ~p\n", [Type]),
                    io:format("\n~p wants to register an account\n", [UserName]),
                    
                    % Map1 = maps:put(UserName, 0, Map),
                    % Output = maps:find(UserName, Map),
                    Output = ets:lookup(Table, UserName),
                    io:format("Output: ~p\n", [Output]),
                    if
                        Output == [] ->
                            % Map1 = maps:put(UserName, #{"followers" => [], "tweets" => []}, Map),
                            Map = maps:to_list(#{"followers" => [], "tweets" => []}),
                            %ets:insert(Table, {UserName, Map}),
                            ets:insert(Table, {UserName, "Map"}),
                            % {ok, Val} = maps:find(UserName, Map1),
                            Val = maps:from_list(ets:lookup(Table, UserName)),
                            printMap(Val),
                            ok = gen_tcp:send(Socket, "User has been registered"), % RESPOND BACK - YES/NO
                            io:fwrite("Good to go, Key is not in database\n");
                        true ->
                            ok = gen_tcp:send(Socket, "Username already taken! Please run the command again with a new username"),
                            io:fwrite("Duplicate key!\n")
                    end,
                    do_recv(Socket, Table, [UserName]);

                Type == "tweet" ->
                    UserName = binary_to_list(lists:nth(2, Data)),
                    Tweet = binary_to_list(lists:nth(3, Data)),
                    io:format("\n ~p sent the following tweet: ~p", [UserName, Tweet]),
                    
                    % {ok, Val} = maps:find(UserName, Map),
                    Val = ets:lookup(Table, UserName),
                    {ok, CurrentTweets} = maps:find("tweets",Val),
                    NewTweets = CurrentTweets ++ [Tweet],
                    Map2 = maps:update("tweets", NewTweets, Val),
                    % Map1 = maps:update(UserName, Map2, Map),
                    ets:update_element(Table, UserName, [Map2]),
                    Val1 = ets:lookup(Table, UserName),
                    % {ok, Val1} = maps:find(UserName, Map1),
                    printMap(Val1),
                    ok = gen_tcp:send(Socket, "Tweeted!"),
                    do_recv(Socket, Table, [UserName]);

                Type == "retweet" ->
                    UserName = binary_to_list(lists:nth(2, Data)),
                    io:format("\n ~p wants to retweet something", [UserName]),
                    do_recv(Socket, Table, [UserName]);

                Type == "subscribe" ->
                    UserName = binary_to_list(lists:nth(2, Data)),
                    SubscribedUserName = binary_to_list(lists:nth(3, Data)),
                    Sub_User = string:strip(SubscribedUserName, right, $\n),
                    Output1 = maps:find(Sub_User, Table),
                    if
                        Output1 == error ->
                            io:fwrite("The username entered doesn't exist! Please try again. \n");
                        true ->
                            {ok, Val} = maps:find(Sub_User, Table),
                            {ok, CurrentFollowers} = maps:find("followers",Val),
                            NewFollowers = CurrentFollowers ++ [UserName,","],
                            Map2 = maps:update("followers", NewFollowers, Val),
                            Map1 = maps:update(UserName, Map2, Table),
                            {ok, Val1} = maps:find(UserName, Map1),
                            printMap(Val1),
                            ok = gen_tcp:send(Socket, "Subscribed!"),
                            do_recv(Socket, Map1, [UserName])
                    end,
                    io:format("\n ~p wants to subscribe to ~p\n", [UserName, Sub_User]),
                    ok = gen_tcp:send(Socket, "Subscribed!"),
                    do_recv(Socket, Table, [UserName]);

                Type == "query" ->
                    UserName = binary_to_list(lists:nth(2, Data)),
                    io:format("\n ~p wants to query", [UserName]),
                    do_recv(Socket, Table, [UserName]);
                true ->
                    io:fwrite("\n Anything else!")
            end;

        {error, closed} ->
            {ok, list_to_binary(Bs)};
        {error, Reason} ->
            io:fwrite("error"),
            io:fwrite(Reason)
    end.

printMap(Map) ->
    io:fwrite("**************\n"),
    List1 = maps:to_list(Map),
    io:format("~s~n",[tuplelist_to_string(List1)]),
    io:fwrite("**************\n").

tuplelist_to_string(L) ->
    tuplelist_to_string(L,[]).

tuplelist_to_string([],Acc) ->
    lists:flatten(["[",
           string:join(lists:reverse(Acc),","),
           "]"]);
tuplelist_to_string([{X,Y}|Rest],Acc) ->
    S = ["{\"x\":\"",X,"\", \"y\":\"",Y,"\"}"],
    tuplelist_to_string(Rest,[S|Acc]).

conn_loop(Socket) ->
    io:fwrite("Uh Oh, I can sense someone trying to connect to me!\n\n"),
    receive
        {tcp, Socket, Data} ->
            io:fwrite("...."),
            io:fwrite("\n ~p \n", [Data]),
            if 
                Data == <<"register_account">> ->
                    io:fwrite("Client wants to register an account"),
                    ok = gen_tcp:send(Socket, "username"), % RESPOND BACK - YES/NO
                    io:fwrite("is now registered");
                true -> 
                    io:fwrite("TRUTH")
            end,
            conn_loop(Socket);
            
        {tcp_closed, Socket} ->
            io:fwrite("I swear I am not here!"),
            closed
    end.

% {tcp, Socket, "register_account"} ->
        %     io:fwrite("Client wants to register an account"),
        %     ok = gen_tcp:send(Socket, "username"), % RESPOND BACK - YES/NO
        %     io:fwrite("is now registered"),
        %     conn_loop(Socket);

        % {send_tweet, Socket, Data} ->
        %     io:fwrite("Client wants to register an account");
        % {subscribe, Socket, Data} ->
        %     io:fwrite("Client wants to register an account");
        % {re_tweet, Socket, Data} ->
        %     io:fwrite("Client wants to register an account");
        % {query_tweet, Socket, Data} ->
        %     io:fwrite("Client wants to register an account");

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