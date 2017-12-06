# For example, add to .zshrc:
#
#     get_ssh_agent $HOME/.ssh/environment

start_ssh_agent() {
  local ssh_env="$1"

  echo "Initializing new SSH agent..."
  ssh-agent | sed 's/^echo/#echo/' > $ssh_env
  echo succeeded
  chmod 600 $ssh_env
  . $ssh_env > /dev/null
  ssh-add
}

test_identities() {
  ssh-add -l | grep "The agent has no identities" > /dev/null
  if [ $? -eq 0 ]; then
    ssh-add
    if [ $? -eq 2 ];then
      # $SSH_AUTH_SOCK is broken, thus start a new proper agent.
      start_ssh_agent
    fi
  fi
}

get_ssh_agent() {
  local ssh_env="$1"

  # Check for running ssh-agent with proper $SSH_AGENT_PID
  if [ -n "$SSH_AGENT_PID" ]; then
    ps -ef | grep "$SSH_AGENT_PID" | grep ssh-agent > /dev/null
    if [ $? -eq 0 ]; then
      test_identities
    fi
  else
    # $SSH_AGENT_PID is not properly set, try to load one from $ssh_env.
    if [ -f $ssh_env ]; then
      . $ssh_env > /dev/null
    fi
    ps -ef | grep "$SSH_AGENT_PID" | grep ssh-agent > /dev/null
    if [ $? -eq 0 ]; then
      test_identities
    else
      start_ssh_agent $ssh_env
    fi
  fi
}
