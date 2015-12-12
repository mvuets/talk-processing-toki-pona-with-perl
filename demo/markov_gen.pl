#!/usr/bin/env perl

use strict;
use warnings;
use autodie;
use lib 'lib';

use Getopt::Long;
use Sereal qw<decode_sereal>;
use String::Markov;


my $in;
my $n = 1;

sub usage {
    <<"END_USAGE";
Usage: $0 --in=<file>|- [-n=<n:1>]
END_USAGE
}

GetOptions(
    'in=s'          => \$in,
    'n=i'           => \$n,
    'help|h'        => sub { print usage(); exit; },
) or die usage();
die "--in is missing\n" if !defined $in;

my $in_fh;
if ($in eq '-') {
    $in_fh = \*STDIN;
}
else {
    open $in_fh, '<', $in;
}

my $mark_data = do { join '', <$in_fh> };
my $mark = decode_sereal($mark_data);
print $mark->generate_sample . "\n" for 1 .. $n;
