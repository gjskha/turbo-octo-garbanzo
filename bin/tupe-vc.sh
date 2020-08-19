# get:  extract file from history
function get() {
	
	PATH=/bin:/usr/bin
	
	VERSION=0
	while test "$1" != ""
	do
		case "$1" in
			-i)	INPUT=$2; shift ;;
			-o)	OUTPUT=$2; shift ;;
			-[0-9])	VERSION=$1 ;;
			-*)	echo "get: Unknown argument $i" 1>&2; exit 1 ;;
			*)	case "$OUTPUT" in
				"")	OUTPUT=$1 ;;
				*)	INPUT=$1.H ;;
				esac
		esac
		shift
	done
	OUTPUT=${OUTPUT?"Usage: get [-o outfile] [-i file.H] file"}
	INPUT=${INPUT-$OUTPUT.H}
	test -r $INPUT || { echo "get: no file $INPUT" 1>&2; exit 1; }
	trap 'rm -f /tmp/get.[ab]$$; exit 1' 1 2 15
	# split into current version and editing commands
	sed <$INPUT -n '1,/^@@@/w /tmp/get.a'$$'
	                /^@@@/,$w /tmp/get.b'$$
	# perform the edits
	awk </tmp/get.b$$ '
		/^@@@/	{ count++ }
		!/^@@@/ && count > 0 && count <= - '$VERSION'
		END	{ print "$d"; print "w", "'$OUTPUT'" }
	' | ed - /tmp/get.a$$
	rm -f /tmp/get.[ab]$$
	
}

# put:  install file into history
function put() {

	PATH=/bin:/usr/bin
	
	case $# in
		1)	HIST=$1.H ;;
		*)	echo 'Usage: put file' 1>&2; exit 1 ;;
	esac
	if test ! -r $1
	then
		echo "put: can't open $1" 1>&2
		exit 1
	fi
	trap 'rm -f /tmp/put.[ab]$$; exit 1' 1 2 15
	echo -n 'Summary: '
	read Summary
	
	if get -o /tmp/put.a$$ $1		# previous version
	then			# merge pieces
		cp $1 /tmp/put.b$$		# current version
		echo "@@@ `getname` `date` $Summary" >>/tmp/put.b$$
		diff -e $1 /tmp/put.a$$ >>/tmp/put.b$$	# latest diffs
		sed -n '/^@@@/,$p' <$HIST >>/tmp/put.b$$ # old diffs
		overwrite $HIST	cat /tmp/put.b$$	# put it back
	else			# make a new one
		echo "put: creating $HIST"
		cp $1 $HIST
		echo "@@@ `getname` `date` $Summary" >>$HIST
	fi
	rm -f /tmp/put.[ab]$$

}

# overwrite:  copy standard input to output after EOF
function overwrite() {
	
	opath=$PATH
	PATH=/bin:/usr/bin
	
	case $# in
	0|1)	echo 'Usage: overwrite file cmd [args]' 1>&2; exit 2
	esac
	
	file=$1; shift
	new=/tmp/overwr1.$$; old=/tmp/overwr2.$$
	trap 'rm -f $new $old; exit 1' 1 2 15	# clean up files
	
	if PATH=$opath "$@" >$new		# collect input
	then
		cp $file $old	# save original file
		trap '' 1 2 15	# we are committed; ignore signals
		cp $new $file
	else
		echo "overwrite: $1 failed, $file unchanged" 1>&2
		exit 1
	fi
	rm -f $new $old
	
}
