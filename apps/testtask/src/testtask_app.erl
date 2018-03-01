-module(testtask_app).
-behaviour(application).
-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->

    sync:go(),
    inets:start(),
    ssl:start(),

    Dispatch = cowboy_router:compile([
        {'_', [
            {"/user/registration",registration,[]},
            {"/user/auth",authorize,[]},
            {"/user/:name",chpass,[]},
            {"/user/",get_users,[]}
            ]}]),

      cowboy:start_clear(http, [{port, 8383}],
                               #{env => #{dispatch => Dispatch}}),

    testtask_sup:start_link().

stop(_State) ->
    ok.
