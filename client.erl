-module(client).
-export[start/0].

start() ->
    io:fwrite("\n\n Hii, I am a new client\n\n"),
    PortNumber = 1204,
    IPAddress = "localhost",
    {ok, Sock} = gen_tcp:connect(IPAddress, PortNumber, [binary, {packet, 0}]),
    ok = gen_tcp:send(Sock, "I want work"),
    io:fwrite("\n\n Just sent my request to the server\n\n"),
    receive
        {tcp, Sock, Data} ->
            io:fwrite(Data);
        {tcp, closed, Sock} ->
            closed
    end.

%loop() ->
    % ask user for a command
    % user enters a command 
    % call a method to run that command - new process
    %receive
    %    {tcp, Sock, Data} ->
    %        io:fwrite(Data);
    %        loop()
    %    {tcp, closed, Sock} ->
    %        closed
    %end.
    % loop()

% subscribe <user_name>
% INPUT