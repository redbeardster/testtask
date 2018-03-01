-module(etsmgr).
-behaviour(gen_server).
-define(SERVER, ?MODULE).

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-export([is_user/1, chpass/2, adduser/2, random_string/1]).
-export([add_token/1]).

random_string(Len) ->
  rand:seed(exs1024s),
  Chrs = list_to_tuple("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"),
  ChrsSize = size(Chrs),
  F = fun(_, R) -> [element(rand:uniform(ChrsSize), Chrs) | R] end,
  lists:foldl(F, "", lists:seq(1, Len)).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

get_token(User) ->
  gen_server:call(?SERVER, {get_token, User}).

add_token(User) ->
  gen_server:call(?SERVER, {add_token, User}).

is_user(User) ->
  gen_server:call(?SERVER, {is_user, User}).

adduser(User,Pass) ->
  gen_server:call(?SERVER, {adduser, User, Pass}).


chpass(User, NewPass)->
  gen_server:call(?SERVER, {chpass, User, NewPass}).


init(Args) ->
             ets:new(users, [set, protected, named_table]),
             ets:new(tokens, [set, protected, named_table]),
            {ok, Args}.

handle_call({chpass, User, NewPass}, _From, State) ->

  ets:delete(users, User),
  ets:insert_new(users, {User, NewPass}),

  {reply, ok, State};

handle_call({add_token, User}, _From, State) ->

  {reply, ets:insert(tokens, {User, list_to_binary(random_string(32))}), State};


handle_call({adduser, User, Pass}, _From, State) ->

    {reply, ets:insert_new(users, {User, Pass}), State};

handle_call({is_user, User}, _From, State) ->

  {reply, ets:lookup(users, User), State};


handle_call(_Request, _From, State) ->
    {reply, ok, State}.


handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
