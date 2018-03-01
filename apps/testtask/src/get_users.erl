-module(get_users).
-export([init/2]).

init(Req0, Opts) ->
  Method = cowboy_req:method(Req0),

  Token = cowboy_req:header(<<"authorization">>, Req0),

  case Token of
    undefined ->
      {ok, cowboy_req:reply(403, #{<<"content-type">> => <<"application/json; charset=utf-8">>},
        jsx:encode([{<<"result">>, <<"failure">>}, {<<"error_msg">>, <<"No access token">>}]), Req0), Opts} ;
    [] ->

      {ok, cowboy_req:reply(200, #{<<"content-type">> => <<"application/json; charset=utf-8">>},
        jsx:encode([{<<"result">>, <<"failure">>}, {<<"error_msg">>, <<"No access token">>}]), Req0), Opts} ;

    _ ->
     echo(Method, Token, Req0)
      end,
  {ok, Req0, Opts}.

echo(<<"GET">>, undefined, Req) ->
  cowboy_req:reply(400, #{}, <<"Missing echo parameter.">>, Req);


echo(<<"GET">>, Token, Req) ->

  Usrs = ets:match(tokens, {'$1',Token}),

  case Usrs of
   []   ->
            cowboy_req:reply(403, #{<<"content-type">> => <<"text/plain; charset=utf-8">>}, jsx:encode([{<<"result">>, <<"failure">>}, {<<"error_msg">>, <<"Invalid token">>}]), Req);
   _ ->

%%        get users list

%%    UsrList = [Usr || ],


     cowboy_req:reply(403, #{<<"content-type">> => <<"application/json; charset=utf-8">>}, jsx:encode([{<<"result">>, <<"success">>}, {<<"users">>, [Usr || [{Usr, Pass}] <- ets:match(users, '$1')]}]), Req)

  end;

echo(_, _, Req) ->
  %% Method not allowed.
  cowboy_req:reply(405, Req).



