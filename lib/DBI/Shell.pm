package DBI::Shell;

=head1 NAME

DBI::Shell - Interactive command shell for the DBI

=head1 SYNOPSIS

  perl -MDBI::Shell -e shell [<DBI data source> [<user> [<password>]]]

or

  dbish [<DBI data source> [<user> [<password>]]]

=head1 DESCRIPTION

The DBI::Shell module (and dbish command, if installed) provide a
simple but effective command line interface for the Perl DBI module.

DBI::Shell is very new, very experimental and very subject to change.
Your milage I<will> vary. Interfaces I<will> change with each release.

=cut

###
###	See TO DO section in the docs at the end.
###


BEGIN { require 5.004 }
BEGIN { $^W = 1 }

use strict;
use vars qw(@ISA @EXPORT $VERSION $SHELL);
use Exporter ();
use Carp;

@ISA = qw(Exporter);
@EXPORT = qw(shell);
$VERSION = substr(q$Revision: 10.1 $, 10);


sub shell {
    my @args = @_ ? @_ : @ARGV;
    $SHELL = DBI::Shell::Std->new(@args);
    $SHELL->load_plugins;
    $SHELL->run;
}


# -------------------------------------------------------------
package DBI::Shell::Std;

use vars qw(@ISA);
@ISA = qw(DBI::Shell::Base);

# XXX this package might be used to override commands etc.


# -------------------------------------------------------------
package DBI::Shell::Base;

use Carp;
use Text::Abbrev ();
use Term::ReadLine;
use Getopt::Long;
use Data::Dumper;

use DBI 0.93 qw(:sql_types :utils);


sub usage {
    print <<USAGE;
Usage: perl -MDBI::Shell -e shell [<DBI data source> [<user> [<password>]]]
USAGE
}


sub add_option {
    my ($sh, $opt, $default) = @_;
    (my $opt_name = $opt) =~ s/[|=].*//;
    croak "Can't add_option '$opt_name', already defined"
	if exists $sh->{$opt_name};
    $sh->{options}->{$opt_name} = $opt;
    $sh->{$opt_name} = $default;
}


sub load_plugins {
    my ($sh) = @_;
    my @pi;
    foreach my $where (qw(DBI/Shell DBI_Shell)) {
	my $mod = $where; $mod =~ s!/!::!g;
	my @dir = map { -d "$_/$where" ? ("$_/$where") : () } @INC;
	foreach my $dir (@dir) {
	    opendir DIR, $dir or warn "Unable to read $dir: $!\n";
	    push @pi, map { "$mod::$_" } grep { /\.pm/ } readdir DIR;
	    closedir DIR;
	}
    }
    print "Loading plugins:\n"; # if @pi;
    local $DBI::Shell::SHELL = $sh; # publish the current shell
    foreach my $pi (@pi) {
	print "  $pi\n";
	eval qq{ use $pi };
	warn "Failed: $@" if $@;
    }
}


sub new {
    my ($class, @args) = @_;
    my $sh = bless {}, $class;

    #
    # Setup Term
    #
    $sh->{term} = new Term::ReadLine($class);

    #
    # Set default configuration options
    #
    $sh->add_option('prompt=s'		=> 'dbi> ');
    $sh->add_option('command_prefix=s'	=> '/');
    $sh->add_option('chistory_size=i'	=> 50);
    $sh->add_option('rhistory_size=i'	=> 50);
    $sh->add_option('rhistory_head=i'	=>  5);
    $sh->add_option('rhistory_tail=i'	=>  5);
    $sh->add_option('editor|ed=s'	=>
		    $ENV{VISUAL} || $ENV{EDITOR} || 'vi');
    # defaults for each new database connect:
    $sh->add_option('init_trace|trace=i'	   => 0);
    $sh->add_option('init_autocommit|autocommit=i' => 1);
    $sh->add_option('debug|d=i'			   => $ENV{DBISH_DEBUG} || 0);


    #
    # Install default commands
    #
    # The sub is passed a reference to the shell and the @ARGV-style
    # args it was invoked with.
    #
    $sh->{commands} = {

    'help' => {
	    hint => "display this list of commands",
    },
    'quit' => {
	    hint => "exit",
    },
    'exit' => {
	    hint => "exit",
    },
    'trace' => {
	    hint => "set DBI trace level for current database",
    },
    'connect' => {
	    hint => "connect to another data source/DSN",
    },

    # --- execute commands
    'go' => {
	    hint => "execute the current statement",
    },
    'do' => {
	    hint => "execute the current (non-select) statement",
    },
    'perl' => {
	    hint => "evaluate the current statement as perl code",
    },
    'commit' => {
	    hint => "commit changes to the database",
    },
    'rollback' => {
	    hint => "rollback changes to the database",
    },
    # --- information commands
    'table_info' => {
	    hint => "display tables that exist in current database",
    },
    'type_info' => {
	    hint => "display data types supported by current server",
    },
    'driver_info' => {
	    hint => "display available DBI drivers",
    },

    # --- statement/history management commands
    'clear' => {
	    hint => "erase the current statement",
    },
    'redo' => {
	    hint => "re-execute the previously executed statement",
    },
    'get' => {
	    hint => "make a previous statement current again",
    },
    'current' => {
	    hint => "display current statement",
    },
    'edit' => {
	    hint => "edit current statement in an external editor",
    },
    'chistory' => {
	    hint => "display command history",
    },
    'rhistory' => {
	    hint => "display result history",
    },
    'history' => {
	    hint => "display combined command and result history",
    },

    };


    # Source config file which may override the defaults.
    # Default is $ENV{HOME}/.dbish_config.
    # Can be overridden with $ENV{DBISH_CONFIG}.
    # Make $ENV{DBISH_CONFIG} empty to prevent sourcing config file.
    # XXX all this will change
    my $homedir = $ENV{HOME}				# unix
		|| "$ENV{HOMEDRIVE}$ENV{HOMEPATH}";	# NT
    $sh->{config_file} = $ENV{DBISH_CONFIG} || "$homedir/.dbish_config";
    if ($sh->{config_file} && -f $sh->{config_file}) {
	require $sh->{config_file};
    }
    
    #
    # Handle command line parameters
    #
    # data_source and user command line parameters overrides both 
    # environment and config settings.
    #
    my %opt = ();
    local (@ARGV) = @args;
    my @options = values %{ $sh->{options} };
    unless (GetOptions(\%opt, 'help|h', @options)) {
	$class->usage;
	croak "DBI::Shell aborted.\n";
    }
    @args = @ARGV;	# args with any options removed

    if ($opt{help}) {
	$class->usage;
	return;
    }

    $sh->{data_source}	= shift(@args) || $ENV{DBI_DSN}  || '';
    $sh->{user}		= shift(@args) || $ENV{DBI_USER} || '';
    $sh->{password}	= shift(@args) || $ENV{DBI_PASS} || undef;

    $sh->{chistory} = [];	# command history
    $sh->{rhistory} = [];	# result  history

    print "DBI::Shell $DBI::Shell::VERSION for DBI $DBI::VERSION\n";

    return $sh;
}


sub run {
    my $sh = shift;

    print "\n";
    print "WARNING: The DBI::Shell interface and functionality are\n";
    print "=======  very likely to change in subsequent versions!\n";
    print "\n";

    # Use valid "dbi:driver:..." to connect with source.
    $sh->do_connect( $sh->{data_source}, $sh->{user}, $sh->{password});

    #
    # Main loop
    #
    $sh->{'abbrev'} = Text::Abbrev::abbrev(keys %{$sh->{commands}});
    $sh->{current_buffer} = '';
    my $current_line = '';

    while (1) {
	my $pre = $sh->{command_prefix};

	$current_line = $sh->{term}->readline($sh->prompt());
	$current_line = "/quit" unless defined $current_line;

	#
	# First, check for installed alias
	#
	# TODO
	if (0) {

	}
	#
	# Then check for command
	#
	elsif ( $current_line =~ /
		^(.*?)
		$pre
		(?:(\w*)([^\|>]*))?
		((?:\||>>?).+)?
		$
	/x) {
	    my ($stmt, $cmd, $args_string, $output) = ($1, $2, $3, $4||''); 

	    $sh->{current_buffer} .= "$stmt\n" if length $stmt;

	    $cmd = 'go' if $cmd eq '';
	    my @args = split ' ', $args_string||'';

	    warn("command='$cmd' args='$args_string' output='$output'") 
		    if $sh->{debug};

	    my $command = $sh->{'abbrev'}->{$cmd}; # expand abbreviation
	    if ($command) {
		$sh->run_command($command, $output, @args);
	    }
	    else {
		print "Command '$cmd' not recognised ",
		    "(enter ${pre}help for help).\n";
	    }
	}
	elsif ($current_line ne "") {
	    $sh->{current_buffer} .= $current_line . "\n";
	    # print whole buffer here so user can see it as
	    # it grows (and new users might guess that unrecognised
	    # inputs are treated as commands)
	    $sh->run_command('list', undef,
		"(enter '$pre' to execute or '${pre}help' for help)");
	}
    }
}
	



#
# Internal subs
#

sub run_command {
    my ($sh, $command, $output, @args) = @_;
    return unless $command;
	local(*STDOUT) if $output;
	local(*OUTPUT) if $output;
	if($output) {
		if(open(OUTPUT, $output)) {
			*STDOUT = *OUTPUT;
		} else {
			$sh->err("Couldn't open output '$output'");
			$sh->run_command('list', undef, '');
		}
	}
    eval {
	my $code = "do_$command";
	$sh->$code(@args);
    };
	close OUTPUT if $output;
    $sh->err("$command failed: $@") if $@;
}

sub err {
    my ($sh, $msg, $die) = @_;
    $msg = "DBI::Shell: $msg\n";
    die $msg if $die;
    print $msg;
}


sub print_list {
    my ($sh, $list_ref) = @_;
    for(my $i = 0; $i < @$list_ref; $i++) {
	print "$i:  $$list_ref[$i]\n";
    }
}


sub print_buffer {
    my ($sh, $buffer) = @_;
    print $sh->prompt(), $buffer, "\n";
}


sub get_data_source {
    my ($sh, $dsn, @args) = @_;
    my $driver;

    if ($dsn) {
	if ($dsn =~ m/^dbi:.*:/i) {	# has second colon
	    return $dsn;		# assumed to be full DSN
	}
	elsif ($dsn =~ m/^dbi:([^:]*)/i) {
	    $driver = $1		# use DriverName part
	}
	else {
	    print "Ignored unrecognised DBI DSN '$dsn'.\n";
	}
    }

    print "\n";
    while (!$driver) {
	print "Available DBI drivers:\n";
	my @drivers = DBI->available_drivers;
	for( my $cnt = 0; $cnt <= $#drivers; $cnt++ ) {
	    printf "%2d: dbi:%s\n", $cnt+1, $drivers[$cnt];
	} 
	$driver = $sh->{term}->readline(
		"Enter driver name or number, or full 'dbi:...:...' DSN: ");
	exit unless defined $driver;	# detect ^D / EOF
	print "\n";

	return $driver if $driver =~ /^dbi:.*:/i; # second colon entered

	if ( $driver =~ /^\s*(\d+)/ ) {
	    $driver = $drivers[$1-1];
	} else {
	    $driver = $1;
	    $driver =~ s/^dbi://i if $driver # incase they entered 'dbi:Name'
	}
	# XXX try to install $driver (if true)
	# unset $driver if install fails.
    }

    my $source;
    while (!defined $source) {
	my $prompt;
	my @data_sources = DBI->data_sources($driver);
	if (@data_sources) {
	    print "Enter data source to connect to: \n";
	    for( my $cnt = 0; $cnt <= $#data_sources; $cnt++ ) {
		printf "%2d: %s\n", $cnt+1, $data_sources[$cnt];
	    } 
	    $prompt = "Enter data source or number,";
	}
	else {
	    print "(The data_sources method returned nothing.)\n";
	    $prompt = "Enter data source";
	}
	$source = $sh->{term}->readline(
		"$prompt or full 'dbi:...:...' DSN: ");
	return if !defined $source;	# detect ^D / EOF
	if ($source =~ /^\s*(\d+)/) {
	    $source = $data_sources[$1-1]
	}
	elsif ($source =~ /^dbi:([^:]+)$/) { # no second colon
	    $driver = $1;		     # possibly new driver
	    $source = undef;
	}
	print "\n";
    }

    return $source;
}


sub prompt_for_password {
    my ($sh) = @_;
    local $| = 1;
    print "Password for $sh->{user}: ";
    # XXX this may be a problem for NT.
    system "stty -echo" unless $^O eq 'MSWin32';
    chop($sh->{password} = <STDIN>);
    system "stty echo" unless $^O eq 'MSWin32';
    print "\n";
}

sub prompt {
    my ($sh) = @_;
    return "(not connected)> " unless $sh->{dbh};
    return "$sh->{user}\@$sh->{data_source}> ";
}


sub push_chistory {
    my ($sh, $cmd) = @_;
    $cmd = $sh->{current_buffer} unless defined $cmd;
    $sh->{prev_buffer} = $cmd;
    my $chist = $sh->{chistory};
    shift @$chist if @$chist >= $sh->{chistory_size};
    push @$chist, $cmd;
}


#
# Result handler methods
#

sub show_header {
    my ($sh, $cols) = @_;
    print join(',', @$cols), "\n";
}

sub show_row {
    my ($sh, $rowref) = @_;
	my @row = @$rowref;
	# XXX note that neat/neat_list output is *not* ``safe''
	# in the sense the it does not escape any chars and
	# may truncate the string and may translate non-printable chars.
	# We only deal with simple escaping here.
	foreach(@row) {
		next unless defined;
		s/'/\\'/g;
		s/\n/ /g;
	}
    print neat_list(\@row, 9999, ","),"\n";
}

sub show_trailer {
    my ($sh) = @_;
    my $rows = $sh->{sth}->rows;
    $rows = "unknown number of" if $rows == -1;
    print "[$rows rows of $sh->{sth}->{NUM_OF_FIELDS} fields returned]\n";
}



#
# Command methods
#

sub do_help {
    my ($sh, @args) = @_;
    my $pre = $sh->{command_prefix};
    my $commands = $sh->{commands};
    print "Defined commands, in alphabetical order:\n";
    foreach my $cmd (sort keys %$commands) {
	my $hint = $commands->{$cmd}->{hint} || '';
	printf "  %s%-10s %s\n", $pre, $cmd, $hint;
    }
    print "Commands can be abbreviated.\n";
}


sub do_go {
    my ($sh, @args) = @_;

    return if $sh->{current_buffer} eq '';

    $sh->{prev_buffer} = $sh->{current_buffer};

    $sh->push_chistory;
    
    eval {
	#
	# Shortcut - if not select, do()	XXX needs more thought
	#
	if ($sh->{current_buffer} !~ /^\s*select\s/i) {
	    $sh->run_command('do');
	    return;
	}

	my $sth = $sh->{dbh}->prepare($sh->{current_buffer});

	$sh->sth_go($sth, 1);
    };
    if ($@) {
	my $err = $@;
	$err =~ s: at \S*DBI/Shell.pm line \d+(,.*?chunk \d+)?::
		if !$sh->{debug} && $err =~ /^DBD::\w+::\w+ \w+/;
	print "$err";
    }

    # There need to be a better way, maybe clearing the
    # buffer when the next non command is typed.
    # Or sprinkle <$sh->{current_buffer} ||= $sh->{prev_buffer};>
    # around in the code.
    $sh->{current_buffer} = '';
}


sub sth_go {
    my ($sh, $sth, $execute) = @_;

    if ($execute || !$sth->{Active}) {
	my @params;
	my $params = $sth->{NUM_OF_PARAMS};
	print "Statement has $params parameters:\n" if $params;
	foreach(1..$params) {
	    my $val = $sh->{term}->readline("Parameter $_ value: ");
	    push @params, $val;
	}
	$sth->execute(@params);
    }
	
    $sh->{sth} = $sth;
    $sh->show_header($sth->{NAME});

    #
    # Remove oldest result from history if reached limit
    #
    my $rhist = $sh->{rhistory};
    shift @$rhist if @$rhist >= $sh->{rhistory_size};
    push @$rhist, [];

    #
    # Keep a buffer of $sh->{rhistory_tail} many rows,
    # when done with result add those to rhistory buffer.
    # Could use $sth->rows(), but not all DBD's support it.
    #
    my @rtail;
    my $i = 0;
    while (my $rowref = $sth->fetchrow_arrayref()) {
	$i++;

	$sh->show_row($rowref);

	if ($i <= $sh->{rhistory_head}) {
	    push @{$rhist->[-1]}, [@$rowref];
	}
	else {
	    shift @rtail if @rtail == $sh->{rhistory_tail};
	    push @rtail, [@$rowref];
	}

    }
    $sh->show_trailer($i);

    if (@rtail) {
	my $rows = $i;
	my $ommitted = $i - $sh->{rhistory_head} - @rtail;
	push @{$rhist->[-1]},
	    [ "[...$ommitted rows out of $rows ommitted...]"];
	foreach my $rowref (@rtail) {
	    push @{$rhist->[-1]}, $rowref;
	}
    }

    $sh->{sth} = undef;
    $sth->finish();
}


sub do_do {
    my ($sh, @args) = @_;
    $sh->push_chistory;
    my $rv = $sh->{dbh}->do($sh->{current_buffer});
    print "[$rv row" . ($rv==1 ? "" : "s") . " affected]\n"
	if defined $rv;

    # XXX I question setting the buffer to '' here.
    # I may want to edit my line without having to scroll back.
    $sh->{current_buffer} = '';
}


sub do_disconnect {
    my ($sh, @args) = @_;
    return unless $sh->{dbh};
    print "Disconnecting from $sh->{data_source}.\n";
    eval {
	$sh->{sth}->finish if $sh->{sth};
	$sh->{dbh}->rollback unless $sh->{dbh}->{AutoCommit};
	$sh->{dbh}->disconnect;
    };
    warn "Error during disconnect: $@" if $@;
    $sh->{sth} = undef;
    $sh->{dbh} = undef;
}


sub do_connect {
    my ($sh, $dsn, @args) = @_;

    $dsn = $sh->get_data_source($dsn, @args);
    return unless $dsn;

    $sh->do_disconnect if $sh->{dbh};

    $sh->{data_source} = $dsn;
    print "Connecting to '$sh->{data_source}' as '$sh->{user}'...\n";
    if ($sh->{user} and !defined $sh->{password}) {
	$sh->prompt_for_password();
    }
    $sh->{dbh} = DBI->connect(
	$sh->{data_source}, $sh->{user}, $sh->{password}, {
	    AutoCommit => $sh->{init_autocommit},
	    PrintError => 0,
	    RaiseError => 1,
    });
    $sh->{dbh}->trace($sh->{init_trace}) if $sh->{init_trace};
}


sub do_list {
    my ($sh, $msg, @args) = @_;
    $msg = $msg ? " $msg" : "";
    print "Current statement buffer$msg:\n" . $sh->{current_buffer};
}


sub do_trace {
    shift->{dbh}->trace(@_);
}

sub do_commit {
    shift->{dbh}->commit(@_);
}

sub do_rollback {
    shift->{dbh}->rollback(@_);
}


sub do_quit {
    my ($sh, @args) = @_;
    $sh->do_disconnect if $sh->{dbh};
    undef $sh->{term};
    exit 0;
}

# Until the alias command is working each command requires definition.
sub do_exit { shift->do_quit(@_); }

sub do_clear {
    my ($sh, @args) = @_;
    $sh->{current_buffer} = '';
}


sub do_redo {
    my ($sh, @args) = @_;
    $sh->{current_buffer} = $sh->{prev_buffer} || '';
    $sh->run_command('go') if $sh->{current_buffer};
}


sub do_chistory {
    my ($sh, @args) = @_;
    $sh->print_list($sh->{chistory});
}

sub do_history {
    my ($sh, @args) = @_;
    for(my $i = 0; $i < @{$sh->{chistory}}; $i++) {
	print $i, ":\n", $sh->{chistory}->[$i], "--------\n";
	foreach my $rowref (@{$sh->{rhistory}[$i]}) {
	    print "    ", join(", ", @$rowref), "\n";
	}
    }
}

sub do_rhistory {
    my ($sh, @args) = @_;
    for(my $i = 0; $i < @{$sh->{rhistory}}; $i++) {
	print $i, ":\n";
	foreach my $rowref (@{$sh->{rhistory}[$i]}) {
	    print "    ", join(", ", @$rowref), "\n";
	}
    }
}


sub do_get {
    my ($sh, $num, @args) = @_;
    if ($num !~ /^\d+$/) {
	$sh->err("Not a number: $num");
	return;
    }
    $sh->{current_buffer} = $sh->{chistory}->[$num];
    $sh->print_buffer($sh->{current_buffer});
}


sub do_perl {
    my ($sh, @args) = @_;
	$DBI::Shell::eval::dbh = $sh->{dbh};
    eval "package DBI::Shell::eval; $sh->{current_buffer}";
    if ($@) { $sh->err("Perl failed: $@") }
    $sh->run_command('clear');
}


sub do_edit {
    my ($sh, @args) = @_;

    $sh->run_command('get', '', $&) if @args and $args[0] =~ /^\d+$/;
    $sh->{current_buffer} ||= $sh->{prev_buffer};
	    
    # Find an area to write a temp file into.
    my $tmp_dir = $ENV{DBI_SHELL_TMP} || # Give people the choice.
	    $ENV{TMP}  ||            # Is TMP set?
	    $ENV{TEMP} ||            # How about TEMP?
	    $ENV{HOME} ||            # Look for HOME?
	    $ENV{HOMEDRIVE} . $ENV{HOMEPATH} || # Last env checked.
	    ".";       # fallback: try to write in current directory.
    my $tmp_file = "$tmp_dir/dbish$$.sql";

    local (*FH);
    open(FH, ">$tmp_file") ||
	    $sh->err("Can't create $tmp_file: $!\n", 1);
    print FH $sh->{current_buffer};
    close(FH) || $sh->err("Can't write $tmp_file: $!\n", 1);

    my $command = "$sh->{editor} $tmp_file";
    system($command) || print "Edit command '$command' failed ($?).\n";

    # Read changes back in (editor may have deleted and rewritten file)
    open(FH, "<$tmp_file") || $sh->err("Can't open $tmp_file: $!\n");
    $sh->{current_buffer} = join "", <FH>;
    close(FH);
    unlink $tmp_file;

    $sh->run_command('list');
}


sub do_driver_info {
    my ($sh, @args) = @_;
    print "Available drivers:";
    my @drivers = DBI->available_drivers;
    print join("\n\t", '',@drivers), "\n";
    print "\n";
}


sub do_type_info {
    my ($sh, @args) = @_;
    my $dbh = $sh->{dbh};
    my $ti = $dbh->type_info_all;
    my $ti_cols = shift @$ti;
    my @names = sort { $ti_cols->{$a} <=> $ti_cols->{$b} } keys %$ti_cols;
    my $sth = $sh->prepare_from_data("type_info", $ti, \@names);
    $sh->sth_go($sth, 0);
}


sub prepare_from_data {
    my ($sh, $statement, $data, $names) = @_;
    my $sponge = DBI->connect("dbi:Sponge:","","",{ RaiseError => 1 });
    my $sth = $sponge->prepare($statement, { rows=>$data, NAME=>$names });
    return $sth;
}


sub do_table_info {
    my ($sh, @args) = @_;
    my $dbh = $sh->{dbh};
    my $sth = $dbh->table_info(@args);
    unless(ref $sth) {
	print "Driver has not implemented the table_info() method, ",
		"trying tables()\n";
	my @tables = $dbh->tables(@args); # else try list context
	unless (@tables) {
	    print "No tables exist ",
		  "(or driver hasn't implemented the tables method)\n";
	    return;
	}
	$sth = $sh->prepare_from_data("tables",
		[ map { [ $_ ] } @tables ],
		[ "TABLE_NAME" ]
	);
    }
    $sh->sth_go($sth, 0);
}


1;
__END__

=head1 TO DO

Proper docs - but not yet, too much is changing.

Commands:
	load (query?) from file
	save (query?) to file

Use Data::ShowTable if available.

Define DBI::Shell plug-in semantics.
	Implement import/export as plug-in module

Batch mode

Completion hooks

Set/Get DBI::Shell options

Set/Get DBI handle attributes

Portability

=head1 COMMANDS

Many commands - few documented, yet!

=over 4

=item help

  /help

=item connect

  /connect               (pick from available drivers and sources)
  /connect dbi:Oracle    (pick source from based on driver)
  /connect dbi:YourDriver:YourSource i.e. dbi:Oracle:mysid

=back

=head1 AUTHORS and ACKNOWLEDGEMENTS

The DBI::Shell has a long lineage.

It started life around 1994-1997 as the pmsql script written by Andreas
König. Jochen Wiedmann picked it up and ran with it (adding much along
the way) as I<dbimon>, bundled with his DBD::mSQL driver modules. In
1998, around the time I wanted to bundle a shell with the DBI, Adam
Marks was working on a dbish modeled after the Sybase sqsh utility.

Wanting to start from a cleaner slate than the feature-full but complex
dbimon, I worked with Adam to create a fairly open modular and very
configurable DBI::Shell module. Along the way Tom Lowery chipped in
ideas and patches. As we go further along more useful code from
Jochen's dbimon is bound to find it's way back in.

=head1 COPYRIGHT

The DBI::Shell module is Copyright (c) 1998 Tim Bunce. England.
All rights reserved. Portions are Copyright by Jochen Wiedmann,
Adam Marks and Tom Lowery.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
