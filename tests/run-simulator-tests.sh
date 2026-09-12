#!/usr/bin/env bash
set -euo pipefail

: "${CONNECT_IQ_HOME:?CONNECT_IQ_HOME must be set}"

if (( $# < 1 )); then
    printf 'Usage: %s command [args...]\n' "$0" >&2
    exit 2
fi

for command_name in timeout xvfb-run dbus-run-session tee; do
    command_path="$(command -v "$command_name" || true)"
    if [[ -z "$command_path" ]]; then
        echo "::error::Required command not found: $command_name." >&2
        exit 1
    fi
    echo "::debug::Using $command_name at $command_path"
done

for sdk_executable in simulator monkeydo; do
    executable_path="${CONNECT_IQ_HOME}/bin/${sdk_executable}"
    if [[ ! -x "$executable_path" ]]; then
        echo "::error::ConnectIQ executable is missing or not executable: $executable_path." >&2
        exit 1
    fi
done

printf '::debug::Simulator test configuration: SDK=%q command=' "$CONNECT_IQ_HOME"
printf ' %q' "$@"
printf '\n'

# Keep simulator, D-Bus, and the test command inside the same virtual display session.
exec timeout --signal=TERM --kill-after=10s 540s \
    xvfb-run -a -s "-screen 0 1280x1024x24" dbus-run-session -- \
    bash -euo pipefail -c '
        log_dir="$(mktemp -d)"
        simulator_pid=""
        cleanup() {
            if [[ -n "$simulator_pid" ]]; then
                echo "::debug::Stopping simulator PID $simulator_pid"
                kill "$simulator_pid" 2>/dev/null || true
                if wait "$simulator_pid" 2>/dev/null; then
                    simulator_status=0
                else
                    simulator_status=$?
                fi
                echo "::debug::Simulator wait status after cleanup: $simulator_status"
            fi
            if [[ -s "$log_dir/simulator.log" ]]; then
                echo "::group::ConnectIQ simulator log" >&2
                cat "$log_dir/simulator.log" >&2
                echo "::endgroup::" >&2
            else
                echo "::debug::ConnectIQ simulator produced no log output"
            fi
            rm -rf "$log_dir"
        }
        trap cleanup EXIT
        trap "exit 143" TERM
        trap "exit 130" INT

        echo "::debug::Starting $CONNECT_IQ_HOME/bin/simulator"
        "$CONNECT_IQ_HOME/bin/simulator" >"$log_dir/simulator.log" 2>&1 &
        simulator_pid=$!
        echo "::debug::Simulator started with PID $simulator_pid"

        # The native simulator serves MonkeyDo on TCP 1234.
        ready=false
        for (( attempt=0; attempt<60; attempt++ )); do
            if ! kill -0 "$simulator_pid" 2>/dev/null; then
                echo "::error::Simulator PID $simulator_pid exited before becoming ready." >&2
                exit 1
            fi
            if (: > /dev/tcp/127.0.0.1/1234) 2>/dev/null; then
                ready=true
                echo "::debug::Simulator became ready after $((attempt + 1)) probe(s)"
                break
            fi
            sleep 0.5
        done
        if [[ "$ready" != true ]]; then
            echo "::error::Simulator did not become ready on 127.0.0.1:1234 within 30 seconds." >&2
            exit 1
        fi

        "$@"
    ' bash "$@"
