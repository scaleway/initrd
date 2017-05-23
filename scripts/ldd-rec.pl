#!/usr/bin/perl -w

# http://lists.fedoraproject.org/pipermail/users/2007-May/344612.html

# recursive ldd: calls ldd, parses its output, recalls ldd on each
# output library until all dependencies are resolved.

my @check_queue = ();# libs to check
my %checked_libs = ();# libs already checked.
my %result = ();# result
my $lib;# current dependency library

$ENV{"LC_CTYPE"}="C";# we match against English output of ldd

push @check_queue, @ARGV;

while (@check_queue) {
    my $to_check = pop @check_queue;
    if (exists $checked_libs{$to_check}) {
        next;
    } else {
        $checked_libs{$to_check} = 1;
    }

    my @libraries = `ldd $to_check`;
    foreach my $line (@libraries) {
        chomp $line;
        if ($line =~ / => (\S+) \(/   # mapped libraries
            or $line =~ /(\S+) \(/) {          # directly resolved libraries
            $lib = $1;
            $result{$lib} = 1;
            push @check_queue, $lib;
        } elsif ($line eq "\tstatically linked" # no library
                      or $line eq"\tnot a dynamic executable"
#     or $line =~ /^.*:$/
                 or $line =~ /linux-gate.so.1/) {  # http://www.trilithium.com/johan/2005/08/linux-gate/
            next;
        } elsif ($line =~ /not found/) {
            print STDERR "$to_check: $line\n";
        } else {
            print STDERR "no match for '$line'\n";
        }
    }
}

#print "Dependencies:\n";
for (sort keys %result) {
    print $_, "\n";
}

exit 0;
