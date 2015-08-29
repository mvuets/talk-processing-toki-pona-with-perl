use v5.20;
use warnings;
use Marpa::R2;

my $bnf = q{
    :default ::= action => Action::eval

    S ::= Subject Predicate
    Subject ::= 'mi'
    Predicate ::= 'moku'

    :discard ~ WS
    WS ~ [\s]+
};

sub Action::eval {
    my (undef, @vals) = @_;
    my $slg = $Marpa::R2::Context::slg;
    my ($lhs, @rhs) = map { $slg->symbol_display_form($_) }
        $slg->rule_expand($Marpa::R2::Context::rule);
    my $ret = "($lhs "
            . (join " ", map {ref $_ ? $$_ : "'$_'"} @vals)
            . ")";
    return \$ret;
}

my $grammar = Marpa::R2::Scanless::G->new({
    source => \$bnf,
});

my $input = 'mi moku';
my $result = $grammar->parse(\$input);
say $$$result;
