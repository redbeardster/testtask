-module(chpass).
-export([init/2]).

init(Req0, Opts) ->

  {ok, PostVals, Req} = cowboy_req:read_urlencoded_body(Req0),

  case PostVals of
   []   ->

     {ok, cowboy_req:reply(403, #{<<"content-type">> => <<"application/json; charset=utf-8">>},
                                jsx:encode([{<<"result">>, <<"failure">>}, {<<"error_msg">>, <<"Bad header">>}]), Req), Opts};

  _ ->

    [{Echo, true}] = PostVals,

%%  io:format("Echo :~p~n", [Echo]),

  <<_Prefix:48,User/binary>> = cowboy_req:path(Req),

  io:format("User: ~p~n", [User]),

  Token = cowboy_req:header(<<"authorization">>, Req0),

   ActualToken =
      case ets:lookup(tokens, User) of
      [{User, AToken}]  ->
                        AToken;
       _ ->
                        <<"">>
      end,

   case Token of
   undefined ->
                {ok, cowboy_req:reply(403, #{<<"content-type">> => <<"application/json; charset=utf-8">>},
                                           jsx:encode([{<<"result">>, <<"failure">>}, {<<"error_msg">>, <<"No access token">>}]), Req), Opts} ;
    [] ->

      {ok, cowboy_req:reply(200, #{<<"content-type">> => <<"application/json; charset=utf-8">>},
        jsx:encode([{<<"result">>, <<"failure">>}, {<<"error_msg">>, <<"No access token">>}]), Req), Opts} ;

      ActualToken ->

     try
    jsx:decode(Echo) of
    _ ->
      io:format("it's OK~n"),
      Pass = proplists:get_value(<<"old_password">>, jsx:decode(Echo)),
      NewPass = proplists:get_value(<<"new_password">>, jsx:decode(Echo)),

      io:format("User: ~p~n", [User]),
      io:format("Pass: ~p~n", [Pass]),

      if User == undefined orelse Pass == undefined orelse NewPass == undefined
        ->
%%           no username or password
        {ok, cowboy_req:reply(403, #{<<"content-type">> => <<"application/json; charset=utf-8">>},
          jsx:encode([{<<"result">>, <<"failure">>}, {<<"error_msg">>, <<"No username or passwords specified">>}]), Req), Opts};
        true ->

%%             process the request
          case etsmgr:is_user(User) of
            [] ->
              {ok, cowboy_req:reply(403, #{<<"content-type">> => <<"application/json; charset=utf-8">>},
                                        jsx:encode([{<<"result">>, <<"failure">>}, {<<"error_msg">>, <<"User not found">>}]), Req), Opts} ;

            [{User, Pwd}] ->
              case Pwd of
                Pass     ->

                  etsmgr:chpass(User, NewPass),

                  {ok, cowboy_req:reply(200, #{<<"content-type">> => <<"application/json; charset=utf-8">>},
                    jsx:encode([{<<"result">>, <<"success">>}]), Req), Opts} ;

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
  end;
   _ ->
        {ok, cowboy_req:reply(403, #{<<"content-type">> => <<"application/json; charset=utf-8">>},
        jsx:encode([{<<"result">>, <<"failure">>}, {<<"error_msg">>, <<"Wrong access token">>}]), Req), Opts}
  end
end.

