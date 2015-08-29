#!/usr/bin/env perl

use v5.22;
use warnings;
use DDP use_prototypes => 0, colored => 1;
use Marpa::R2;
use Term::ANSIColor qw<>;

sub COLOR() { 1 }

my $bnf = `cat tokipona.bnf`;

my $grammar = Marpa::R2::Scanless::G->new({ source => \$bnf });

sub next_color {
    state $COLORS = [qw<clear red green yellow blue magenta cyan>];
    my $c = shift // $COLORS->[-1];
    my ($idx) = grep {$c eq $COLORS->[$_]} 0..$#$COLORS;
    return $COLORS->[($idx + 1) % @$COLORS];
}

sub colored {
    return $_[0] if !COLOR;
    return Term::ANSIColor::colored(@_);
}

sub action::eval {
    my ($action_object, @vals) = @_;
    state $n = 0; ++$n;
    state $c; $c = next_color($c);
    my $rule_id = $Marpa::R2::Context::rule;
    my $slg = $Marpa::R2::Context::slg;
    my ( $lhs, @rhs ) =
        map { $slg->symbol_display_form($_) }
        $slg->rule_expand($rule_id);
    my $ret = colored("($lhs ", $c)
            . (join " ", map {ref $_ ? $$_ : colored("'$_'", "$c bold")} @vals)
            . colored(")", $c);
    return \$ret;
}

INPUT:
while (my $input = <>) {
    chomp $input;

    print "\n";
    print colored($input, "bold"), "\n";

    my $rec = Marpa::R2::Scanless::R->new({
        grammar => $grammar,
        semantics_package => 'action',
    });

    eval {
        $rec->read(\$input);
        1;
    }
    or do {
        print "    * malformed input:\n";
        print "$@";
        next INPUT;
    };

    my @results;
    while (defined (my $val = $rec->value)) {
        push @results, $$$val;
    }

    if (!@results) {
        print "    * could not parse\n";
        next INPUT;
    }

    for my $r (@results) {
        print "    * $r\n";
    }
}
