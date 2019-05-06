#!/bin/bash
# Don't set -e because we want to login even if sourcing the profile fails.

function pathprepend {
	if [ -d $1 ]; then
		p="${1//\//\\\/}"
		if [ "${PATH//${p}/''}" = "$PATH" ]; then
			export PATH=$1:$PATH
		fi
	fi
}

function pathappend {
	if [ -d $1 ]; then
		p="${1//\//\\\/}"
		if [ "${PATH//${p}/''}" = "$PATH" ]; then
			export PATH="$PATH:$1"
		fi
	fi
}

function manprepend {
	if [ -d $1 ]; then
		p="${1//\//\\\/}"
		if [ "${MANPATH//${p}/''}" = "$PATH" ]; then
			export MANPATH="$1:$MANPATH"
		fi
	fi
}

function manappend {
	if [ -d $1 ]; then
		p="${1//\//\\\/}"
		if [ "${MANPATH//${p}/''}" = "$PATH" ]; then
			export MANPATH="$MANPATH:$1"
		fi
	fi
}

function setarch {
	export ARCH="$(uname -m \
		| sed 's/^..86$$/386/; s/^.86$$/386/; s/x86_64/amd64/; s/arm.*/arm/')"
	export OS="`uname | tr A-Z a-z | sed 's/mingw/windows/; s/.*windows.*/windows/'`"
	
	# Even on 64-bit platform, darwin uname -m prints i386.
	# Check for amd64 with sysctl instead.
	if [ "$OS" = darwin ]; then
		export ARCH="`if sysctl machdep.cpu.extfeatures 2>&1 | grep EM64T >/dev/null; then echo amd64; else uname -m | sed 's/i386/386/'; fi`"
	fi
	# Solaris is equally untrustworthy.
	if [ "$OS" = sunos ]; then
		export ARCH=`isainfo -n | sed 's/^..86$$/386/; s/^.86$$/386/'`
	fi
	# Don't use hostname -s, some systems don't support -s; 
	# also, some Linux distros don't have hostname.
	if [ -x /bin/hostname ]; then
		export H="`/bin/hostname | sed 's/\..*$//'`"
	else
		export H=$OS
	fi
}

function setprompt {
	PS1="\h:\W\$ "
}

function setpython {
	export PYTHONDONTWRITEBYTECODE=1
}

function sethistory {
	# append to the history file, don't overwrite it
	shopt -s histappend
	# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
	export HISTSIZE=-1
	export HISTFILESIZE=-1
	export HISTCONTROL=ignoredups:ignorespace
}

function setbashmisc {
	# check the window size after each command and, if necessary,
	# update the values of LINES and COLUMNS.
	shopt -s checkwinsize
	
	# Notify immediatly on bg job completion
	set -o notify
	
	# enable programmable completion features (you don't need to enable
	# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
	# sources /etc/bash.bashrc).
	if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
		. /etc/bash_completion
	fi
}

function sethomebrew {
	pathprepend /usr/local/bin
	# for gnu utilities installed by homebrew
	pathprepend /usr/local/opt/coreutils/libexec/gnubin
	manprepend /usr/local/opt/coreutils/libexec/gnuman
}

function setlein {
	pathappend $HOME/.lein/bin
}

function setbin {
	pathprepend $HOME/bin
}

function setgo {	
	export GOPATH="$HOME"
	goroots="
		$GOPATH
		/usr/local/go
	"
	for goroot in $goroots; do
		if [ -d $goroot/bin ]; then
			pathappend "$goroot/bin"
			break
		fi
	done
}

function setplan9 {
	#
	#	PLAN 9
	#
	plan9s="
		$HOME/plan9
		/usr/local/plan9
	"
	for i in $plan9s; do
		if [ -f $i/include/u.h ]; then
			export PLAN9=$i
			break
		fi
	done
	if [ -n "$PLAN9" ]; then
		pathappend "$PLAN9/bin"
		if [ -z "$DISPLAY" ]; then
			display=:0
		else
			display=$DISPLAY
		fi
		
		export NAMESPACE=/tmp/ns.$USER.$display
		mkdir -p $NAMESPACE
		
		export acmeshell=`which bash`
		export pfont="/lib/font/bit/lucsans/euro.8.font"
		export rpfont="/mnt/font/LucidaGrande/25a/font"
		export ffont="/usr/local/plan9/font/pelm/unicode.9.font"
		export rffont="/mnt/font/Menlo-Regular/25a/font"
		function _acme() {
			acme -a -f $pfont,$rpfont -F $ffont,$rffont $*
		}
		_rc() {
			PATH=.:$PLAN9/bin:$bin rc $*
		}
		alias rc=_rc
		alias acme=_acme
		alias sam='sam -a'
		if [ "$termprog" = 9term ] \
		|| [ "$termprog" = win ]; then
			# Keep the label up to date, so plumber works
			_cd () {
				\cd "$@" &&
				case $- in
				*i*)
					awd
				esac
			}
			alias cd=_cd
			cd .
		fi
		# Let gs find the plan9port document fonts.
		export GS_FONTPATH=$PLAN9/postscript/font
	
		# Equivalent variables for rc(1).
		export home=$HOME
		export user=$USER
		export prompt="$H% "

		# If running in 9term or acme, make the environment
		# more Plan9 like.
		if [ "$TERM" = 9term -o "$TERM" = dumb ]; then	
			# Disable readline
			set +o emacs
			set +o vi
			# Make man work in 9term and acme's win,
			export PAGER=`which nobs` # Solaris needs full path
			# Set prompt so we can execute whole line
			# without $PS1 interfering.
			PS1='$(printf "%s" ": ${H}:`basename ${PWD}`; ")'
		fi
		
		# Browsers, in order of preference.
		browsers="
			chromium-browser
			google-chrome
			opera
			firefox
		"
		# Try to set BROWSER (used by the plumber) On darwin, this will fail. 
		# That's fine, we'll use web(1)'s default.
		for i in $browsers; do
			if [ -x "`which $i 2>/dev/null`" ] ; then
				export BROWSER="$i"
			fi
		done
	
		alias lc='9 lc'
	else
		# If we don't have plan9port, perhaps we might have 9base. If we do,
		# we add to the $PATH so sam -r host works.
		pathappend "/usr/local/9/bin"
	fi
}

function setssh {

	# ensure SSH agent
	SSH_ENV="$HOME/.ssh/environment"
	
	ssh_dir="$(dirname "$SSH_ENV")"
	if [[ ! -d "$ssh_dir" ]]; then
		if [[ ! -e "$ssh_dir" ]]; then
			mkdir -p -m 0700 "$ssh_dir"
		else
			echo "cannot start SSH agent: '$ssh_dir' is not a directory" >&2
			return
		fi
	fi
	
	function start_ssh_agent {
		/usr/bin/ssh-agent | grep -v ^echo > "$SSH_ENV"
		chmod 0600 "$SSH_ENV"
		. "$SSH_ENV" > /dev/null
		/usr/bin/ssh-add
	}
	
	if [[ -f "$SSH_ENV" ]]; then
		. "$SSH_ENV" > /dev/null
		ps -ef | grep $SSH_AGENT_PID | grep ssh-agent$ > /dev/null \
			|| start_ssh_agent
	else
		start_ssh_agent
	fi

}

function setmisc {

	# ALIASES
	alias l='ls -F'
	alias ls='ls -F'
	alias ll='ls -l'
	alias la='ls -lA'

	pathappend "/Users/elliot/kl/zookeeper/bin"
	
	function mountain {
		say -v 'Cellos' "di di di di dum dum dum di di di dum dum dum di di di di do do do di di do do di di di do do";
	}
	function badnews {
		say -v 'Bad News' "di di di di dum dum dum di di di dum dum dum di di di di do do do di di do do di di di do do dum dum dum dum";
	}
	function graduation {
		say -v 'Good' "di di di di dum dum dum di di di dum dum dum di di di di do do do di di do do di di di do do dum dum dum dum";
	}

}

function extract {
	if [ -f $1 ]; then
		case $1 in
		*.tar.bz2) tar -jxvf $1 ;;
		*.tar.gz) tar -zxvf $1 ;;
		*.bz2) bzip2 -d $1 ;;
		*.gz) gunzip -d $1 ;;
		*.tar) tar -xvf $1 ;;
		*.tgz) tar -zxvf $1 ;;
		*.zip) unzip $1 ;;
		*.Z) uncompress $1 ;;
		*.rar) unrar x $1 ;;
		*) echo "'$1' Error. Unsupported filetype." ;;
		esac
	else
		echo "'$1' is not a valid file"
	fi
}

function printpath {
	echo $PATH | awk -F':' '{
		for (i=1;i<NF;i++) {
			print $i;
		}
	}'
}

function delmerged {
	BRANCH=`[ ! -z "$1" ] && echo -n "$1" || echo -n "master"`
	git branch --merged "$BRANCH" | grep -v "\* $BRANCH" | xargs -n 1 git branch -d
}

setarch
setpython
setprompt
sethistory
setbashmisc
sethomebrew
setbin
setlein
setgo
setplan9
setssh
setmisc
