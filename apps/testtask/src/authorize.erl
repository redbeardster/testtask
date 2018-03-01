-module(authorize).
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
                                   jsx:encode([{<<"result">>, <<"failure">>}, {<<"error_msg">>, <<"No username or password specified">>}]), Req), Opts};
        true ->

%%             process the request
          case etsmgr:is_user(User) of
            [] ->
                    {ok, cowboy_req:reply(403, #{<<"content-type">> => <<"application/json; charset=utf-8">>},
                                                jsx:encode([{<<"result">>, <<"failure">>}, {<<"error_msg">>, <<"User not found">>}]), Req), Opts} ;
            [{User, Pwd}] ->
              case Pwd of
             Pass     ->

                etsmgr:add_token(User),
                [{User, Token}] = ets:lookup(tokens, User),

               {ok, cowboy_req:reply(200, #{<<"content-type">> => <<"application/json; charset=utf-8">>},
                 jsx:encode([{<<"result">>, <<"success">>}, {<<"result">>, Token}]), Req), Opts};
                _ ->
                  {ok, cowboy_req:reply(403, #{<<"content-type">> => <<"application/json; charset=utf-8">>},
                    jsx:encode([{<<"result">>, <<"failure">>}, {<<"error_msg">>, <<"Password mismatch">>}]), Req), Opts}
              end
          end

      end
  catch
    _:_ ->
      io:format("Bad json~n"),
      {ok, cowboy_req:reply(403, #{<<"content-type">> => <<"application/json; charset=utf-8">>},
        jsx:encode([{<<"result">>, <<"failure">>}, {<<"error_msg">>, <<"Malformed request">>}]), Req), Opts}
  end.



