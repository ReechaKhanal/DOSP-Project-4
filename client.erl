-module(client).
-export[start/0].

start() ->
    io:fwrite("I am a new client"),
    PortNumber = 1204,
    IPAddress = "localhost",
    {ok, Sock} = gen_tcp:connect(IPAddress, PortNumber, [binary, {packet, 0}]),
    ok = gen_tcp:send(Sock, "I want work"),

    receive
        {tcp, Sock, Data} ->
            io:fwrite(Data);
        {tcp, closed, Sock} ->
            closed
    end.
