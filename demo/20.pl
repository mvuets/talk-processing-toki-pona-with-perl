use v5.20;
use warnings;
use Data::Dumper;
use Marpa::R2;

my $bnf = q{
    :default ::= action => [name, values]

    S ::= 'mi' ' ' 'moku'
};

my $grammar = Marpa::R2::Scanless::G->new({
    source => \$bnf,
});

my $input = 'mi moku';
my $result = $grammar->parse(\$input);
print Dumper($result);
