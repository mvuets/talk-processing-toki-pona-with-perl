use strict;
use warnings;
use Data::Dumper;
use Marpa::R2;

my $bnf = q{
};

my $grammar = Marpa::R2::Scanless::G->new({
    source => \$bnf,
});

my $input = 'mi moku';
my $result = $grammar->parse(\$input);
print Dumper($result);
