-module(client).
-export[start/0].

start() ->
    io:fwrite("\n\n Hii, I am a new client\n\n"),
    PortNumber = 1204,
    IPAddress = "localhost",
    {ok, Sock} = gen_tcp:connect(IPAddress, PortNumber, [binary, {packet, 0}]),

    % ok = gen_tcp:send(Sock, "I want work"),

    % ok = gen_tcp:send(Sock, "I SERIOUSLY want work"),

    io:fwrite("\n\n Just sent my request to the server\n\n"),
    loop(Sock, "_").
    % receive
    %     {tcp, Sock, Data} ->
    %         io:fwrite(Data);
    %     {tcp, closed, Sock} ->
    %         closed
    % end.

loop(Sock, UserName) ->
    % ask user for a command
    % user enters a command 
    % call a method to run that command - new process
    receive
       {tcp, Sock, Data} ->
           io:fwrite(Data),

            % ask user for a input command
            {ok, [CommandType]} = io:fread("\nEnter the command: ", "~s\n"),
            io:fwrite(CommandType),
            % parse that command - register, subscribe <user_name>

            if 
                CommandType == "register" ->
                    UserName1 = register_account(Sock),
                    loop(Sock, UserName1);
                CommandType == "tweet" ->
                    if
                        UserName == "_" ->
                            io:fwrite("Please register first!\n");
                        true ->
                            send_tweet(Sock,UserName)
                    end,
                    loop(Sock, UserName);
                CommandType == "retweet" ->
                    re_tweet();
                CommandType == "subscribe" ->
                    subscribe_to_user("anjali0645");
                CommandType == "query" ->
                    query_tweet();
                true ->
                    io:fwrite("Invalid command!\n")
            end;

        {tcp, closed, Sock} ->
            io:fwrite("Client Cant connect anymore - TCP Closed")
         
        end.

register_account(Sock) ->

    % Input user-name
    {ok, [UserName]} = io:fread("\nEnter the User Name: ", "~s\n"),
    % send the server request
    ok = gen_tcp:send(Sock, [["register", UserName]]),
    io:fwrite("\nAccount has been Registered\n"),
    UserName.

send_tweet(Sock,UserName) ->
    {ok, [Tweet]} = io:fread("\nWhat's on your mind?: ", "~s\n"),
    ok = gen_tcp:send(Sock, ["tweet",UserName, Tweet]),
    io:fwrite("\nTweet Sent\n").

re_tweet() ->
    io:fwrite("\nRetweeted\n").

subscribe_to_user(User_Name) ->
    io:format("Subscribed to the user ~p", [User_Name]).

query_tweet() ->
    io:fwrite("Queried related tweets").

% subscribe <user_name>
% INPUT