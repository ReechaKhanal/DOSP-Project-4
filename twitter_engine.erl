-module(twitter_engine).
-import(maps, []).
-export[start/0].

start() ->
    io:fwrite("\n\n Howdy!!, I am The Twitter Engine Clone \n\n"),
    %Table = ets:new(t, [ordered_set]),
    Table = ets:new(messages, [ordered_set, named_table, public]),
    Client_Socket_Mapping = ets:new(clients, [ordered_set, named_table, public]),
    All_Clients = [],
    Map = maps:new(),
    {ok, ListenSocket} = gen_tcp:listen(1204, [binary, {keepalive, true}, {reuseaddr, true}, {active, false}]),
    await_connections(ListenSocket, Table, Client_Socket_Mapping).

await_connections(Listen, Table, Client_Socket_Mapping) ->
    {ok, Socket} = gen_tcp:accept(Listen),
    ok = gen_tcp:send(Socket, "YIP"),
    spawn(fun() -> await_connections(Listen, Table, Client_Socket_Mapping) end),
    %conn_loop(Socket).
    do_recv(Socket, Table, [], Client_Socket_Mapping).

do_recv(Socket, Table, Bs, Client_Socket_Mapping) ->
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
                    PID = binary_to_list(lists:nth(3, Data)),
                    io:format("\nPID:~p\n", [PID]),
                    io:format("\nSocket:~p\n", [Socket]),
                    io:format("Type: ~p\n", [Type]),
                    io:format("\n~p wants to register an account\n", [UserName]),
                    
                    % Map1 = maps:put(UserName, 0, Map),
                    % Output = maps:find(UserName, Map),
                    Output = ets:lookup(Table, UserName),
                    io:format("Output: ~p\n", [Output]),
                    if
                        Output == [] ->

                            ets:insert(Table, {UserName, [{"followers", []}, {"tweets", []}]}),      
                            ets:insert(Client_Socket_Mapping, {UserName, PID}),                      
                            Temp_List = ets:lookup(Table, UserName),
                            io:format("~p", [lists:nth(1, Temp_List)]),

                            %Val = maps:from_list(Temp_List),
                            %printMap(Val),
                            ok = gen_tcp:send(Socket, "User has been registered"), % RESPOND BACK - YES/NO
                            io:fwrite("Good to go, Key is not in database\n");
                        true ->
                            ok = gen_tcp:send(Socket, "Username already taken! Please run the command again with a new username"),
                            io:fwrite("Duplicate key!\n")
                    end,
                    do_recv(Socket, Table, [UserName], Client_Socket_Mapping);

                Type == "tweet" ->
                    UserName = binary_to_list(lists:nth(2, Data)),
                    Tweet = binary_to_list(lists:nth(3, Data)),
                    io:format("\n ~p sent the following tweet: ~p", [UserName, Tweet]),
                    
                    % {ok, Val} = maps:find(UserName, Map),
                    Val = ets:lookup(Table, UserName),
                    io:format("Output: ~p\n", [Val]),
                    Val3 = lists:nth(1, Val),
                    Val2 = element(2, Val3),
                    Val1 = maps:from_list(Val2),
                    {ok, CurrentFollowers} = maps:find("followers",Val1),                         
                    {ok, CurrentTweets} = maps:find("tweets",Val1),

                    NewTweets = CurrentTweets ++ [Tweet],
                    io:format("~p~n",[NewTweets]),
                    
                    ets:insert(Table, {UserName, [{"followers", CurrentFollowers}, {"tweets", NewTweets}]}),
                    sendMessage(Socket, Client_Socket_Mapping, Tweet, CurrentFollowers, UserName),
                    ok = gen_tcp:send(Socket, "Tweeted!"),
                    do_recv(Socket, Table, [UserName], Client_Socket_Mapping);

                Type == "retweet" ->
                    UserName = binary_to_list(lists:nth(2, Data)),
                    io:format("\n ~p wants to retweet something", [UserName]),
                    do_recv(Socket, Table, [UserName], Client_Socket_Mapping);

                Type == "subscribe" ->
                    UserName = binary_to_list(lists:nth(2, Data)),
                    SubscribedUserName = binary_to_list(lists:nth(3, Data)),
                    Sub_User = string:strip(SubscribedUserName, right, $\n),

                    Output1 = ets:lookup(Table, Sub_User),
                    io:format("Output: ~p\n", [Output1]),
                    %Output1 = maps:find(Sub_User, Table),

                    if
                        Output1 == [] ->
                            io:fwrite("The username entered doesn't exist! Please try again. \n");
                        true ->

                            Val = ets:lookup(Table, Sub_User),
                            io:format("~p~n",[Val]),
                            Val3 = lists:nth(1, Val),
                            Val2 = element(2, Val3),

                            Val1 = maps:from_list(Val2),                            
                            {ok, CurrentFollowers} = maps:find("followers",Val1),
                            {ok, CurrentTweets} = maps:find("tweets",Val1),

                            NewFollowers = CurrentFollowers ++ [UserName],
                            io:format("~p~n",[NewFollowers]),
                            % Map2 = maps:update("followers", NewFollowers, Val1),

                            %ets:insert(Table, {Sub_User, [Map2]}),
                            ets:insert(Table, {Sub_User, [{"followers", NewFollowers}, {"tweets", CurrentTweets}]}),
                            ok = gen_tcp:send(Socket, "Subscribed!"),

                            do_recv(Socket, Table, [UserName], Client_Socket_Mapping)
                    end,
                    io:format("\n ~p wants to subscribe to ~p\n", [UserName, Sub_User]),
                    ok = gen_tcp:send(Socket, "Subscribed!"),
                    do_recv(Socket, Table, [UserName], Client_Socket_Mapping);

                Type == "query" ->
                    UserName = binary_to_list(lists:nth(2, Data)),
                    io:format("\n ~p wants to query", [UserName]),
                    do_recv(Socket, Table, [UserName], Client_Socket_Mapping);
                true ->
                    io:fwrite("\n Anything else!")
            end;

        {error, closed} ->
            {ok, list_to_binary(Bs)};
        {error, Reason} ->
            io:fwrite("error"),
            io:fwrite(Reason)
    end.

sendMessage(Socket, Client_Socket_Mapping, Tweet, Subscribers, UserName) ->
    if
        Subscribers == [] ->
            io:fwrite("\nNo followers!\n");
        % Client_Socket_Mapping == [] ->
        %     io:fwrite("\nAll clients empty!\n");
        true ->
            % io:format("\nAll Clients: ~p~n",[Client_Socket_Mapping]),

            [Client_To_Send | Remaining_List ] = Subscribers,
            io:format("Client to send: ~p\n", [Client_To_Send]),
            io:format("\nRemaining List: ~p~n",[Remaining_List]),
            Client_Socket_Row = ets:lookup(Client_Socket_Mapping,Client_To_Send),
            Val3 = lists:nth(1, Client_Socket_Row),
            Client_Socket = list_to_pid(element(2, Val3)),
            io:format("\nClient Socket: ~p~n",[Client_Socket]),
            % List_Client_Socket = pid(Client_Socket),
            % io:format("\nList Client Socket: ~p~n",[List_Client_Socket]),
            % {ok, SockAddress} = socket:sockname(Socket),
            % {ok, SockAddress} = socket:sockname(Client_Socket),
            Client_Socket ! {self(), {udpok,"tweetedddd"}},
            % Out = socket:sendto(Client_Socket, "Yayyyyyyy!! Tweet received!\n", "localhost"),
            % ok = gen_tcp:send(Socket, "Yayyyyyyy!! Tweet received by Current!\n"),
            Socket ! {self(), {udpok, "tweetedddd"}},
            % if
            %     Out == ok ->
            %         io:fwrite("\n Looks Gooooood!\n");
            %     true ->
            %         io:fwrite("\nWe are in true\n"),
            %         {error, Reason} = Out,
            %         io:format("\nError reason: ~p", [Reason])
            % end,
            % ok = gen_tcp:send(Client_Socket, [Tweet,",",UserName,",",Subscribers]),
            sendMessage(Socket, Client_Socket_Mapping, Tweet, Remaining_List, UserName)
    end,
    io:fwrite("Send message!\n").


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