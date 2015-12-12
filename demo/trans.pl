#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use lib 'lib';
use Dictionary;

use Term::ANSIColor qw<colored>;


my $interactive = -t STDIN;
my $dict = Dictionary::dict();

INPUT:
while (my $input = <>) {
    chomp $input;

    if (!$interactive) {
        print colored($input, 'bold'), "\n";
    }

    my @words = grep length, split / +/, $input;

    for my $w (@words) {
        my $def = $dict->{$w};
        if (!$def) {
            printf "%24s\n", $w;
        }
        else {
            $w = "$w -";
            for my $d (@$def) {
                my ($pos, $trans) = @$d;
                printf "%24s %s %s\n",
                    colored($w, 'bold'),
                    colored($pos, 'green'),
                    $trans;
                $w = '';
            }
        }
    }

    print "\n";
}
