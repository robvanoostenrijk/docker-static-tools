#!/tools/bin/sh
export PATH=/tools/bin:/tools/sbin:$PATH
export TERMINFO_DIRS=/tools/etc/terminfo:/etc/terminfo

if [ ! -z "$1" ]; then
	echo "[i] Populating into volume mapped directory $1."

	if [ -d "$1" ]; then
		cp -rv tools.sh bin etc lib libexec sbin share $1
	else
		echo "[!] Volume mapped directory $1 does not exist."
	fi
else
	echo "[i] Executing shell environment."
	exec /tools/bin/sh
fi
