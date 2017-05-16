::@echo off
:: LSB Tags
:::: BEGIN INIT INFO
:: Provides:          jetty
:: Required-Start:    $local_fs $network
:: Required-Stop:     $local_fs $network
:: Default-Start:     2 3 4 5
:: Default-Stop:      0 1 6
:: Short-Description: Jetty start script.
:: Description:       Start Jetty web server.
:::: END INIT INFO

:: Startup script for jetty under windows systems.

if "%OS%" == "Windows_NT" setlocal

::::::::::::::::::::::::::::::::::::::::::::::::::
:: Set the name which is used by other variables.
:: Defaults to the file name without extension.
::::::::::::::::::::::::::::::::::::::::::::::::::
set T_NAME=%0%
set NAME=%T_NAME:.bat=%

:: To get the service to restart correctly on reboot, uncomment below (3 lines):
:: ========================
:: chkconfig: 3 99 99
:: description: Jetty 9 webserver
:: processname: jetty
:: ========================

:: Configuration files
::
:: /etc/default/$NAME
::   If it exists, this is read at the start of script. It may perform any
::   sequence of shell commands, like setting relevant environment variables.
::
:: $HOME/.$NAMErc (e.g. $HOME/.jettyrc)
::   If it exists, this is read at the start of script. It may perform any
::   sequence of shell commands, like setting relevant environment variables.
::
:: /etc/$NAME.conf
::   If found, and no configurations were given on the command line,
::   the file will be used as this script's configuration.
::   Each line in the file may contain:
::     - A comment denoted by the pound (#) sign as first non-blank character.
::     - The path to a regular file, which will be passed to jetty as a
::       config.xml file.
::     - The path to a directory. Each *.xml file in the directory will be
::       passed to jetty as a config.xml file.
::     - All other lines will be passed, as-is to the start.jar
::
::   The files will be checked for existence before being passed to jetty.
::
:: Configuration variables
::
:: JAVA
::   Command to invoke Java. If not set, java (from the PATH) will be used.
::
:: JAVA_OPTIONS
::   Extra options to pass to the JVM
::
:: JETTY_HOME
::   Where Jetty is installed. If not set, the script will try go
::   guess it by looking at the invocation path for the script
::   The java system property "jetty.home" will be
::   set to this value for use by configure.xml files, f.e.:
::
::    <Arg><Property name="jetty.home" default="."/>/webapps/jetty.war</Arg>
::
:: JETTY_BASE
::   Where your Jetty base directory is.  If not set, the value from
::   $JETTY_HOME will be used.
::
:: JETTY_RUN
::   Where the $NAME.pid file should be stored. It defaults to the
::   first available of /var/run, /usr/var/run, JETTY_BASE and /tmp
::   if not set.
::
:: JETTY_PID
::   The Jetty PID file, defaults to $JETTY_RUN/$NAME.pid
::
:: JETTY_ARGS
::   The default arguments to pass to jetty.
::   For example
::      JETTY_ARGS=jetty.http.port=8080 jetty.ssl.port=8443
::
:: JETTY_USER
::   if set, then used as a username to run the server as
::
:: JETTY_SHELL
::   If set, then used as the shell by su when starting the server.  Will have
::   no effect if start-stop-daemon exists.  Useful when JETTY_USER does not
::   have shell access, e.g. /bin/false
::

if not "%1" == "" goto ok_args
echo " Usage: %0% [-d] {start|stop|run|restart|check|supervise} [ CONFIGS ... ] "
goto end
:ok_args

::::::::::::::::::::::::::::::::::::::::::::::::::
::# Get the action & configs
::::::::::::::::::::::::::::::::::::::::::::::::::
set CONFIGS=
set NO_START=0
set DEBUG=0

:loop 
if "%1"=="" goto ok_chk_debug
if not "%1" == "-d" goto ok_step
set DEBUG=1
:ok_step
shift
goto loop

:ok_chk_debug
set ACTION=%1
shift


::::::::::::::::::::::::::::::::::::::::::::::::::
:: Read any configuration files
::::::::::::::::::::::::::::::::::::::::::::::::::
set ETC=%HOMEPATH%

if not exist "%HOMEPATH%\.%NAME%rc" goto ok_chk_rc
if not "%DEBUG%" == "1" goto skip_debug_0
echo "Reading %HOMEPATH%\.%NAME%rc.."
:skip_debug_0
call "%HOMEPATH%\.%NAME%rc"
:ok_chk_rc

::::::::::::::::::::::::::::::::::::::::::::::::::
:: Set tmp if not already set.
::::::::::::::::::::::::::::::::::::::::::::::::::
set TMPDIR=%tmp%

::::::::::::::::::::::::::::::::::::::::::::::::::
:: Jetty's hallmark
::::::::::::::::::::::::::::::::::::::::::::::::::
set JETTY_INSTALL_TRACE_FILE="start.jar"


::::::::::::::::::::::::::::::::::::::::::::::::::
:: Try to determine JETTY_HOME if not set
::::::::::::::::::::::::::::::::::::::::::::::::::
if not "%JETTY_HOME%" == "" goto ok_home
set JETTY_HOME=%cd:\bin=%
:ok_home

goto end
::::::::::::::::::::::::::::::::::::::::::::::::::
:: No JETTY_HOME yet? We're out of luck!
::::::::::::::::::::::::::::::::::::::::::::::::::
if not "%JETTY_HOME%" == "" goto ok_chk_home
echo "** ERROR: JETTY_HOME not set, you need to set it or install in a standard location"
:ok_chk_home


::::::::::::::::::::::::::::::::::::::::::::::::::
:: Set JETTY_BASE
::::::::::::::::::::::::::::::::::::::::::::::::::
if not "%JETTY_BASE%" == "" goto ok_chk_base
set JETTY_BASE=%JETTY_BASE%
:ok_chk_base


::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Check that jetty is where we think it is
::::::::::::::::::::::::::::::::::::::::::::::::::::
if not exist "%JETTY_HOME%\%$JETTY_INSTALL_TRACE_FILE%"
echo "** ERROR: Oops! Jetty doesn't appear to be installed in %JETTY_HOME%"
echo "** ERROR:  %JETTY_HOME%\%$JETTY_INSTALL_TRACE_FILE% is not readable!"


::::::::::::::::::::::::::::::::::::::::::::::::::
:: Try to find this script's configuration file,
:: but only if no configurations were given on the
:: command line.
::::::::::::::::::::::::::::::::::::::::::::::::::
if not "%JETTY_CONF%" == "" goto ok_chk_conf
if not exist "%ETC%\%NAME%.conf" goto chk_base_conf
set JETTY_CONF="%ETC%\%NAME%.conf"
goto ok_chk_conf
:chk_base_conf
if not exist "%JETTY_BASE%\etc\jetty.conf" goto chk_home_conf
set JETTY_CONF="%JETTY_BASE%\etc\jetty.conf"
goto ok_chk_conf
:chk_home_conf
if not exist "%JETTY_HOME%\etc\jetty.conf" goto ok_chk_conf
set JETTY_CONF="%JETTY_HOME%\etc\jetty.conf"
:ok_chk_conf

::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Find a location for the pid file
::::::::::::::::::::::::::::::::::::::::::::::::::::
if "%JETTY_RUN%" == "" goto ok_chk_run
if not exist "%JETTY_BASE%\NUL" goto set_run_tmp
JETTY_RUN="%JETTY_BASE%\jetty"
:set_run_tmp
JETTY_RUN="%TMPDIR%\jetty"
if not exist %JETTY_RUN%\NUL mkdir %JETTY_RUN%
:ok_chk_run

::::::::::::::::::::::::::::::::::::::::::::::::::::
:: define start log location
::::::::::::::::::::::::::::::::::::::::::::::::::::
if not "%JETTY_START_LOG%" == "" goto ok_chk_log
JETTY_START_LOG="%JETTY_RUN%\%NAME%-start.log"
:ok_chk_log

::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Find a pid and state file
::::::::::::::::::::::::::::::::::::::::::::::::::::
if "%JETTY_PID%" == "" set JETTY_PID="%JETTY_RUN%\%NAME%.pid"
if "%JETTY_STATE%" == "" set JETTY_STATE="%JETTY_BASE%\%NAME%.state"
if "%JETTY_ARGS%" == "" set JETTY_ARGS=""
set JETTY_ARGS=%JETTY_ARGS% "jetty.state=$JETTY_STATE"

::::::::::::::::::::::::::::::::::::::::::::::::::
:: Get the list of config.xml files from jetty.conf
::::::::::::::::::::::::::::::::::::::::::::::::::
if exist "%JETTY_CONF%
::then
::  while read -r CONF
::  do
::    if expr "$CONF" : '#' >/dev/null ; then
::      continue
::    fi
::
::    if [ -d "$CONF" ]
::    then
::      # assume it's a directory with configure.xml files
::      # for example: /etc/jetty.d/
::      # sort the files before adding them to the list of JETTY_ARGS
::      for XMLFILE in "$CONF/"*.xml
::      do
::        if [ -r "$XMLFILE" ] && [ -f "$XMLFILE" ]
::        then
::          JETTY_ARGS=(${JETTY_ARGS[*]} "$XMLFILE")
::        else
::          echo "** WARNING: Cannot read '$XMLFILE' specified in '$JETTY_CONF'"
::        fi
::      done
::    else
::      # assume it's a command line parameter (let start.jar deal with its validity)
::      JETTY_ARGS=(${JETTY_ARGS[*]} "$CONF")
::    fi
::  done < "$JETTY_CONF"
::fi

::::::::::::::::::::::::::::::::::::::::::::::::::
:: Setup JAVA if unset
::::::::::::::::::::::::::::::::::::::::::::::::::
if "%JAVA%" == "" set JAVA=java
if not "%JAVA%" == "" goto ok_chk_java
echo "Cannot find a Java JDK. Please set either set JAVA or put java (>=1.5) in your PATH."
goto end
:ok_chk_java

::::::::::::::::::::::::::::::::::::::::::::::::::::
:: See if Deprecated JETTY_LOGS is defined
::::::::::::::::::::::::::::::::::::::::::::::::::::
if not "$JETTY_LOGS" == "" echo "** WARNING: JETTY_LOGS is Deprecated. Please configure logging within the jetty base." 

::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Are we running on Windows? Could be, with Cygwin/NT.
::::::::::::::::::::::::::::::::::::::::::::::::::::::
set PATH_SEPARATOR=;

::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Add jetty properties to Java VM options.
::::::::::::::::::::::::::::::::::::::::::::::::::::
if "%JAVA_OPTIONS%" == "" set JAVA_OPTIONS=
JAVA_OPTIONS=%JAVA_OPTIONS% "-Djetty.home=$JETTY_HOME" "-Djetty.base=$JETTY_BASE" "-Djava.io.tmpdir=$TMPDIR"

::::::::::::::::::::::::::::::::::::::::::::::::::::
:: This is how the Jetty server will be started
::::::::::::::::::::::::::::::::::::::::::::::::::::

set JETTY_START=%JETTY_HOME%\start.jar
set START_INI=%JETTY_BASE%\start.ini
set START_D=%JETTY_BASE%\start.d
if exist %START_INI% goto ok_start_config
if exist %START_D% goto ok_start_config
echo "Cannot find a start.ini file or a start.d directory in your JETTY_BASE directory: $JETTY_BASE" >&2
goto end 
:ok_start_config
set RUN_ARGS=%JAVA_OPTIONS% -jar %JETTY_START% %JETTY_ARGS%
set RUN_CMD=%JAVA% %RUN_ARGS%

::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Comment these out after you're happy with what
:: the script is doing.
::::::::::::::::::::::::::::::::::::::::::::::::::::::
if not "%DEBUG%" == "1" goto skip_debug_1
echo "JAVA           =  %JAVA%"
echo "JAVA_OPTIONS   =  %JAVA_OPTIONS%"
echo "JETTY_HOME     =  %JETTY_HOME%"
echo "JETTY_BASE     =  %JETTY_BASE%"
echo "START_D        =  %START_D%"
echo "START_INI      =  %START_INI%"
echo "JETTY_START    =  %JETTY_START%"
echo "JETTY_CONF     =  %JETTY_CONF%"
echo "JETTY_ARGS     =  %JETTY_ARGS%"
echo "JETTY_RUN      =  %JETTY_RUN%"
echo "JETTY_PID      =  %JETTY_PID%"
echo "JETTY_START_LOG=  %JETTY_START_LOG%"
echo "JETTY_STATE    =  %JETTY_STATE%"
echo "RUN_CMD        =  %RUN_CMD%"
:skip_debug_1

::::::::::::::::::::::::::::::::::::::::::::::::::
:: Do the action
::::::::::::::::::::::::::::::::::::::::::::::::::
if not "start" == "%ACTION%" goto ok_chk_start
echo "Starting Jetty: "

::    if (( NO_START )); then
::      echo "Not starting ${NAME} - NO_START=1";
::      exit
::    fi
::
::    if [ $UID -eq 0 ] && type start-stop-daemon > /dev/null 2>&1
::    then
::      unset CH_USER
::      if [ -n "$JETTY_USER" ]
::      then
::        CH_USER="-c$JETTY_USER"
::      fi
::
::      start-stop-daemon -S -p"$JETTY_PID" $CH_USER -d"$JETTY_BASE" -b -m -a "$JAVA" -- "${RUN_ARGS[@]}" start-log-file="$JETTY_START_LOG"
::
::    else
::
::      if running $JETTY_PID
::      then
::        echo "Already Running $(cat $JETTY_PID)!"
::        exit 1
::      fi
::
::      if [ -n "$JETTY_USER" ] && [ `whoami` != "$JETTY_USER" ]
::      then
::        unset SU_SHELL
::        if [ "$JETTY_SHELL" ]
::        then
::          SU_SHELL="-s $JETTY_SHELL"
::        fi
::
::        touch "$JETTY_PID"
::        chown "$JETTY_USER" "$JETTY_PID"
::        # FIXME: Broken solution: wordsplitting, pathname expansion, arbitrary command execution, etc.
::        su - "$JETTY_USER" $SU_SHELL -c "
::          exec ${RUN_CMD[*]} start-log-file="$JETTY_START_LOG" > /dev/null &
::          disown \$!
::          echo \$! > '$JETTY_PID'"
::      else
::        "${RUN_CMD[@]}" > /dev/null &
::        disown $!
::        echo $! > "$JETTY_PID"
::      fi
::
::    fi
::
::    if expr "${JETTY_ARGS[*]}" : '.*jetty-started.xml.*' >/dev/null
::    then
::started()
::{
::  # wait for 60s to see "STARTED" in PID file, needs jetty-started.xml as argument
::  for T in 1 2 3 4 5 6 7 9 10 11 12 13 14 15
::  do
::    sleep 4
::    [ -z "$(grep STARTED $1 2>/dev/null)" ] || return 0
::    [ -z "$(grep STOPPED $1 2>/dev/null)" ] || return 1
::    [ -z "$(grep FAILED $1 2>/dev/null)" ] || return 1
::    local PID=$(cat "$2" 2>/dev/null) || return 1
::    kill -0 "$PID" 2>/dev/null || return 1
::    echo -n ". "
::  done
::
::  return 1;
::}
::
::     if started "$JETTY_STATE" "$JETTY_PID"
::     then
::       echo "OK `date`"
::     else
::       echo "FAILED `date`"
::       exit 1
::     fi
::   else
::     echo "ok `date`"
::   fi
::
::   ;;
:ok_chk_nostart
call %RUN_CMD% start-log-file="%JETTY_START_LOG%"
:ok_chk_start
if not "stop" == "%ACTION%" goto ok_chk_stop

::    echo -n "Stopping Jetty: "
::    if [ $UID -eq 0 ] && type start-stop-daemon > /dev/null 2>&1; then
::      start-stop-daemon -K -p"$JETTY_PID" -d"$JETTY_HOME" -a "$JAVA" -s HUP
::
::      TIMEOUT=30
::      while running "$JETTY_PID"; do
::        if (( TIMEOUT-- == 0 )); then
::          start-stop-daemon -K -p"$JETTY_PID" -d"$JETTY_HOME" -a "$JAVA" -s KILL
::        fi
::
::        sleep 1
::      done
::    else
::      if [ ! -f "$JETTY_PID" ] ; then
::        echo "ERROR: no pid found at $JETTY_PID"
::        exit 1
::      fi
::
::      PID=$(cat "$JETTY_PID" 2>/dev/null)
::      if [ -z "$PID" ] ; then
::        echo "ERROR: no pid id found in $JETTY_PID"
::        exit 1
::      fi
::      kill "$PID" 2>/dev/null
::
::      TIMEOUT=30
::      while running $JETTY_PID; do
::        if (( TIMEOUT-- == 0 )); then
::          kill -KILL "$PID" 2>/dev/null
::        fi
::
::        sleep 1
::      done
::    fi
::
::    rm -f "$JETTY_PID"
::    rm -f "$JETTY_STATE"
::    echo OK
::
::    ;;
:ok_chk_stop
if not "restart" == "%ACTION%" goto ok_chk_restart
::JETTY_SH=$0
::> "$JETTY_STATE"
::if [ ! -f $JETTY_SH ]; then
::  if [ ! -f $JETTY_HOME/bin/jetty.sh ]; then
::    echo "$JETTY_HOME/bin/jetty.sh does not exist."
::    exit 1
::  fi
::  JETTY_SH=$JETTY_HOME/bin/jetty.sh
::fi
::
::"$JETTY_SH" stop "$@"
::"$JETTY_SH" start "$@"
::
::;;
:ok_chk_restart 

if not "supervise" == "%ACTION%" goto ok_chk_supervise
::    exec "${RUN_CMD[@]}"
:ok_chk_supervise 

if "run" == "%ACTION%" goto ok_chk_run
if "demo" == "%ACTION%" goto ok_chk_run
goto ok_chk_run_demo
:ok_chk_run

::echo "Running Jetty: "
::running()
::{
::  if [ -f "$1" ]
::  then
::    local PID=$(cat "$1" 2>/dev/null) || return 1
::    kill -0 "$PID" 2>/dev/null
::    return
::  fi
::  rm -f "$1"
::  return 1
::}
::    if running "$JETTY_PID"
::    then
::      echo Already Running $(cat "$JETTY_PID")!
::      exit 1
::    fi
::
::    exec "${RUN_CMD[@]}"
::    ;;

:ok_chk_run_demo

if "check" == "%ACTION%" goto ok_chk_check
if "status" == "%ACTION%" goto ok_chk_check
goto ok_chk_check_status
:ok_chk_check
::    if running "$JETTY_PID"
::    then
::      echo "Jetty running pid=$(< "$JETTY_PID")"
::    else
::      echo "Jetty NOT running"
::    fi
::    echo
::    dumpEnv
::    echo
::
::    if running "$JETTY_PID"
::    then
::      exit 0
::    fi
::    exit 1
:ok_chk_check_status

:end
