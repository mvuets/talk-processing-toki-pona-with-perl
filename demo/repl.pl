#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use lib 'lib';
use Parser;

use Term::ANSIColor qw<colored>;


my $interactive = -t STDIN;

INPUT:
while (my $input = <>) {
    chomp $input;

    if (!$interactive) {
        print colored($input, 'bold'), "\n";
    }

    my $res = Parser::parse_sentence($input);
    if (ref $res) {
        for my $j (@$res) {
            print "-   $j\n";
        }
    }
    else {
        print colored("*   $res", 'bold red'), "\n";
    }

    print "\n";
}
