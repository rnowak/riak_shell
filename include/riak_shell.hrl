-define(CONFIGFILE, "../etc/riak_shell.config").
-define(GREENTICK, [9989]).
-define(REDCROSS,  [10060]).

-define(VERSION_NUMBER, "1.4").

-record(command, {
    %% these fields are used to convey information about the
    %% the current execution loop, is the command complete
    %% should this command be written to the log and
    %% does this command return an error
    cmd_error              = false :: boolean(),
    cmd                    = [] :: [char()],
    log_this_cmd           = true :: boolean(),
    response               = [] :: [char()]
}).

-record(state, {
    config                 = [],
    connection             = none,
    cookie                 = riak,
    count                  = 1   :: integer(),
    current_date           = riak_shell_util:datetime(),
    date_log               = off :: on | off,
    debug                  = off :: on | off,
    extensions             = [],
    format                 = "human" :: string(),
    has_connection         = false :: boolean(),
    history                = [],
    logfile                = undefined,
    logging                = off :: on | off,
    show_connection_status = false,
    version                = undefined
}).


%% commands beginning with the implemented SQL keywords listed
%% cannot be used as command names in extensions
%% these keywords are used to select which lexer-parser will be used as well
-define(IMPLEMENTED_SQL_STATEMENTS, [
                                     create,
                                     describe,
                                     explain,
                                     insert,
                                     select,
                                     show
                                    ]).
