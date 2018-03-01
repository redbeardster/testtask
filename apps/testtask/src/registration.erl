-module(registration).
-export([init/2]).

init(Req0, Opts) ->

      {ok, PostVals, Req} = cowboy_req:read_urlencoded_body(Req0),
      [{Echo, true}] = PostVals,
      io:format("Echo :~p~n", [Echo]),

  try
    jsx:decode(Echo) of
   _ ->
     io:format("it's OK~n"),
         User = proplists:get_value(<<"user">>, jsx:decode(Echo)),
         Pass = proplists:get_value(<<"password">>, jsx:decode(Echo)),

         io:format("User: ~p~n", [User]),
         io:format("Pass: ~p~n", [Pass]),

         if User == undefined orelse Pass == undefined
           ->
%%           no username or password
           {ok, cowboy_req:reply(403, #{<<"content-type">> => <<"application/json; charset=utf-8">>},
             jsx:encode([{<<"result">>, <<"failure">>}, {<<"error_msg">>, <<"Malformed username or password parameter">>}]), Req), Opts};
           true ->
%%             process the request

             case etsmgr:adduser(User, Pass) of
               false  ->

                 {ok, cowboy_req:reply(403, #{<<"content-type">> => <<"application/json; charset=utf-8">>},
                   jsx:encode([{<<"result">>, <<"failure">>}, {<<"error_msg">>, <<"Already registered">>}]), Req), Opts};
               _ ->
                 {ok, cowboy_req:reply(200, #{<<"content-type">> => <<"application/json; charset=utf-8">>},
                   jsx:encode([{<<"result">>, <<"success">>}]), Req), Opts}
              end

          end
    catch
    _:_ ->
        io:format("Bad json~n"),
        {ok, cowboy_req:reply(200, #{<<"content-type">> => <<"application/json; charset=utf-8">>},
          jsx:encode([{<<"result">>, <<"failure">>}]), Req), Opts}
   end.

