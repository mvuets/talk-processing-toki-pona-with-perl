package Parser;

use v5.10;
use strict;
use warnings;

use Marpa::R2;
use Term::ANSIColor qw<>;

our $COLOR = 1;

my $bnf = do { join '', <DATA> };
my $grammar = Marpa::R2::Scanless::G->new({ source => \$bnf });

sub _next_color {
    state $COLORS = [qw<clear red green yellow blue magenta cyan>];
    my $c = shift // $COLORS->[-1];
    my ($idx) = grep {$c eq $COLORS->[$_]} 0..$#$COLORS;
    return $COLORS->[($idx + 1) % @$COLORS];
}

sub _colored {
    return $_[0] if !$COLOR;
    return Term::ANSIColor::colored(@_);
}

sub action::eval {
    my ($action_object, @vals) = @_;
    state $n = 0; ++$n;
    state $c; $c = _next_color($c);
    my $rule_id = $Marpa::R2::Context::rule;
    my $slg = $Marpa::R2::Context::slg;
    my ($lhs, @rhs) =
        map { $slg->symbol_display_form($_) }
        $slg->rule_expand($rule_id);
    my $ret = _colored("($lhs ", $c)
            . (join " ", map {ref $_ ? $$_ : _colored("'$_'", "$c bold")} @vals)
            . _colored(")", $c);
    return \$ret;
}

sub parse_sentence {
    my ($input) = @_;

    my $rec = Marpa::R2::Scanless::R->new({
        grammar => $grammar,
        semantics_package => 'action',
    });

    eval {
        $rec->read(\$input);
        1;
    }
    or do {
        my $ex = "$@";
        $ex =~ s/\s+\Z//;
        return "malformed input: $ex";
    };

    my @results;
    while (defined (my $val = $rec->value)) {
        push @results, $$$val;
    }

    if (!@results) {
        return "could not parse";
    }

    return \@results;
}

__DATA__
# (c) 2012 Zach Tomaszewski 
# http://www2.hawaii.edu/~ztomasze/ics661/
#
# Changelog:
#   -   Merged ale/ali into one structural token
#   -   Defined proper noun rule PropN & Name
#   -   Removed unknown word 'wike'
#
# Todo:
#   -   New official words not included here: alasa, esun, pu, ko, kon, pan
#   -   New unofficial/draft words not included hee: kipisi, kin, namako
#   -   Synonyms:
#       -   a == kin
#       -   ale == ali
#       -   lukin == oko
#       -   sin == namako
#   -   Support tokiponanized proper names
#   -   Fix "Unproductive symbol: CompoundSubj"
#   -   Support complex sentence structure involving punctuation marks

:default ::=
    action => eval
lexeme default =
    latm => 1

S ::= Interjection | VocativeS | Sent | YNAnswer

VocativeS ::= NP o | NP o Comma Sent | NP o Pred | o Pred | Conditional o Pred
YNAnswer ::= V | V ala

Sent ::= SubjPred | Conditional SubjPred | taso SubjPred

Conditional ::= SubjPred la | Context la | NP la

SubjPred ::= mi Pred | sina Pred | NP_NoMiSina li Pred | CompoundSubj li Pred

CompoundSubj ::= NP en CompoundSubj

NP_NoMiSina ::= N_NoMiSina | CompNP
NP ::= N | CompNP
CompNP ::= NMod | NPpi | NP anu NP
NPpi ::= NP pi N Modifier | NP pi PropN
NMod ::= N Modifier | N N | N N Modifier

Modifier ::= Mod | Mod Modifier 
Pred ::= VP | VP li Pred

VP ::= IntransVP | TransVP | VP PrepPh
IntransVP ::= Verb | lon NP | tawa NP | Modal lon NP | Modal tawa NP | Modifier | NP
TransVP ::= Verb DO | Modal Verb DO
DO ::= e NP | e NP DO
Verb ::= V | Modal V | V Mod | YnV | Modal YnV | YnV Mod
YnV ::= V ala V

PrepPh ::= Prep NP | Prep NP PrepPh

Context ::= ante | ken 

Modal ::= PosModal | PosModal ala | YnModal
PosModal ::= kama | ken | wile 
YnModal ::= kama ala kama | ken ala ken | wile ala wile

V ::= anpa | ante | awen | ijo | ike | jaki | jan | jo | kalama | kama | ken
    | kepeken | kule | lape | lawa | lete | lili | lon | lukin | moku | moli
    | musi | mute | nasa | olin | open | pakala | pali | pana | pilin | pimeja
    | pini | poka | pona | seli | sin | sitelen | sona | suli | suwi | tawa
    | telo | toki | tomo | tu | unpa | utala | wan | wawa | weka | wile

N ::= mi | sina | N_NoMiSina

N_NoMiSina ::= PropN | akesi | ala | ale | ante | ijo | ike | ilo | insa | jaki
    | jan | jo | kala | kalama | kama | kasi | ken | kili | kiwen | kule | kute
    | kulupu | lawa | len | lete | lili | linja | lipu | luka | lupa | ma
    | mama | mani | meli | mije | moku | moli | monsi | mun | musi | mute
    | nanpa | nasin | nena | ni | nimi | noka | oko | olin | ona | pakala | pali
    | palisa | pana | pilin | pimeja | pini | pipi | poki | poka | pona | seli
    | selo | seme | sewi | sijelo | sike | sinpin | sitelen | sona | soweli
    | suli | suno | supa | suwi | tan | tawa | telo | tenpo | toki | tomo | tu
    | unpa | uta | utala | walo | wan | waso | wawa | weka | wile

Mod ::= ala | ale | ante | awen | ijo | ike | insa | jaki | jan | jelo | kalama
    | kama | kin | kiwen | kule | kute | kulupu | laso | lape | lawa | lete
    | lili | loje | lukin | mama | meli | mi | mije | moku | moli | monsi | mun
    | musi | mute | nasa | ni | olin | ona | pakala | pali | pimeja | pini | poka
    | pona | sama | seli | seme | sewi | sike | sin | sina | suli | suwi | taso
    | tawa | telo | toki | tomo | tu | unpa | uta | walo | wan | wawa | weka 

Prep ::= kepeken | lon | poka | sama | tan | tawa 

Interjection ::= a | a a | a a a | ala | ike | jaki | mu | o | pakala | pona | toki

PropN ::= jan Name | ma Name | ma tomo Name | toki Name | soweli Name 

Name ~ 'TODO'

:discard ~ whitespace
whitespace ~ [\s]+

Comma ~ ','
a ~ 'a'
akesi ~ 'akesi'
ala ~ 'ala'
ale ~ 'ale' | 'ali'
anpa ~ 'anpa'
ante ~ 'ante'
anu ~ 'anu'
awen ~ 'awen'
e ~ 'e'
en ~ 'en'
ijo ~ 'ijo'
ike ~ 'ike'
ilo ~ 'ilo'
insa ~ 'insa'
jaki ~ 'jaki'
jan ~ 'jan'
jelo ~ 'jelo'
jo ~ 'jo'
kala ~ 'kala'
kalama ~ 'kalama'
kama ~ 'kama'
kasi ~ 'kasi'
ken ~ 'ken'
kepeken ~ 'kepeken'
kili ~ 'kili'
kin ~ 'kin'
kiwen ~ 'kiwen'
kule ~ 'kule'
kulupu ~ 'kulupu'
kute ~ 'kute'
la ~ 'la'
lape ~ 'lape'
laso ~ 'laso'
lawa ~ 'lawa'
len ~ 'len'
lete ~ 'lete'
li ~ 'li'
lili ~ 'lili'
linja ~ 'linja'
lipu ~ 'lipu'
loje ~ 'loje'
lon ~ 'lon'
luka ~ 'luka'
lukin ~ 'lukin'
lupa ~ 'lupa'
ma ~ 'ma'
mama ~ 'mama'
mani ~ 'mani'
meli ~ 'meli'
mije ~ 'mije'
mi ~ 'mi'
moku ~ 'moku'
moli ~ 'moli'
monsi ~ 'monsi'
mu ~ 'mu'
mun ~ 'mun'
musi ~ 'musi'
mute ~ 'mute'
nanpa ~ 'nanpa'
nasa ~ 'nasa'
nasin ~ 'nasin'
nena ~ 'nena'
nimi ~ 'nimi'
ni ~ 'ni'
noka ~ 'noka'
oko ~ 'oko'
olin ~ 'olin'
ona ~ 'ona'
o ~ 'o'
open ~ 'open'
pakala ~ 'pakala'
pali ~ 'pali'
palisa ~ 'palisa'
pana ~ 'pana'
pilin ~ 'pilin'
pimeja ~ 'pimeja'
pini ~ 'pini'
pi ~ 'pi'
pipi ~ 'pipi'
poka ~ 'poka'
poki ~ 'poki'
pona ~ 'pona'
sama ~ 'sama'
seli ~ 'seli'
selo ~ 'selo'
seme ~ 'seme'
sewi ~ 'sewi'
sijelo ~ 'sijelo'
sike ~ 'sike'
sina ~ 'sina'
sinpin ~ 'sinpin'
sin ~ 'sin'
sitelen ~ 'sitelen'
sona ~ 'sona'
soweli ~ 'soweli'
suli ~ 'suli'
suno ~ 'suno'
supa ~ 'supa'
suwi ~ 'suwi'
tan ~ 'tan'
taso ~ 'taso'
tawa ~ 'tawa'
telo ~ 'telo'
tenpo ~ 'tenpo'
toki ~ 'toki'
tomo ~ 'tomo'
tu ~ 'tu'
unpa ~ 'unpa'
utala ~ 'utala'
uta ~ 'uta'
walo ~ 'walo'
wan ~ 'wan'
waso ~ 'waso'
wawa ~ 'wawa'
weka ~ 'weka'
wile ~ 'wile'
