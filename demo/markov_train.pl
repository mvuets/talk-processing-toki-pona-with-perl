#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use lib 'lib';
use Parser;

use File::Find;
use Getopt::Long;
use Sereal qw<encode_sereal>;
use String::Markov;
use Term::ANSIColor qw<colored>;


my $out;
my $corpus = 'corpus';
my $order = 2;

sub usage {
    <<"END_USAGE";
Usage: $0 --out=<file>|-
           [--corpus=<dir:$corpus>] [--order=<n:2>]
END_USAGE
}

GetOptions(
    'out=s'         => \$out,
    'corpus=s'      => \$corpus,
    'order=i'       => \$order,
    'help|h'        => sub { print usage(); exit; },
) or die usage();
die "--out is missing\n" if !defined $out;

my $CORPUS_FILE_PATTERN = qr/\.txt$/;
my $PUNCTUATION = '(?:' . join( '|', qw<\. \! \?> ) . ')';

my $mark = String::Markov->new(
    order => $order,
    split_sep => qr{\s+},
    join_sep => ' '
);

find({wanted => \&on_file, no_chdir => 1}, $corpus);

my $mark_data = encode_sereal($mark);
my $out_fh;
if ($out eq '-') {
    $out_fh = \*STDOUT;
}
else {
    open $out_fh, '>', $out;
}
print $out_fh $mark_data;


sub on_file {
    my $file = $_;
    return if !-f $file;
    return if $file !~ $CORPUS_FILE_PATTERN;

    print STDERR "# file $file\n";

    my $text = do { open my $fh, '<', $file; join '', <$fh> };
    $text =~ s/\n/ /g;

    my $ok = 0;
    my $bad = 0;
    my @sent = split_sentences($text);
    for my $s (@sent) {
        $s =~ s/$PUNCTUATION$//;
        my $res = Parser::parse_sentence($s);
        if (ref $res) {
            $mark->add_sample($s);
            $ok++;
        }
        else {
            $bad++;
        }
    }
    print STDERR "#   ok: $ok; bad: $bad\n";
}

# Stolen from Text::Sentence and adapted
sub split_sentences {
    my $text = shift;

    return () unless $text;

    # capital letter is a character set; to account for local, this includes
    # all characters for which lc is different from that character

    my $capital_letter = '';


    # this needs to be alternation, not character class, because of
    # multibyte characters

    my $opt_start_quote = q/['"]?/; # "'
    my $opt_close_quote = q/['"]?/; # "'

    # these are distinguished because (eventually!) I would like to do
    # locale stuff on quote characters

    my $opt_start_bracket = q/[[({]?/; # }{
    my $opt_close_bracket = q/[\])}]?/;

    # return $text if there is no punctuation ...

    return $text unless $text =~ /$PUNCTUATION/;

    my @sentences = $text =~ /
    (
                                # sentences start with ...
        $opt_start_quote        # an optional start quote
        $opt_start_bracket      # an optional start bracket
        $capital_letter         # a capital letter ...
        .+?                     # at least some (non-greedy) anything ...
        $PUNCTUATION            # ... followed by any one of !?.
        $opt_close_quote        # an optional close quote
        $opt_close_bracket      # and an optional close bracket
    )
    (?=                         # with lookahead that it is followed by ...
        (?:                     # either ...
            \s+                 # some whitespace ...
            $opt_start_quote    # an optional start quote
            $opt_start_bracket  # an optional start bracket
            $capital_letter     # an uppercase word character (for locale
                                # sensitive matching)
        |               # or ...
            \n\n        # a couple (or more) of CRs
        |               # or ...
            \s*$        # optional whitespace, followed by end of string
        )
    )
    /gxs
    ;
    return @sentences if @sentences;
    return ( $text );
}
