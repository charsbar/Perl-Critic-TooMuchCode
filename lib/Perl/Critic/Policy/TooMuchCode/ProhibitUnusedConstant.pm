package Perl::Critic::Policy::TooMuchCode::ProhibitUnusedConstant;

use strict;
use warnings;
use Perl::Critic::Utils;
use PPIx::Utils::Traversal qw(get_constant_name_elements_from_declaring_statement);
use parent 'Perl::Critic::Policy';


sub default_themes       { return qw( maintenance )     }
sub applies_to           { return 'PPI::Document' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my %defined_constants;
    my %used;

    my $include_statements = $elem->find(sub { $_[1]->isa('PPI::Statement::Include') }) || [];
    for my $st (@$include_statements) {
        next unless $st->schild(0) eq "use" && $st->module eq "constant";
        my @constants = get_constant_name_elements_from_declaring_statement( $st );
        for my $tok (@constants) {
            push @{ $defined_constants{"$tok"} }, $tok;
        }
    }

    for my $el_word (@{ $elem->find( sub { $_[1]->isa("PPI::Token::Word") }) ||[]}) {
        my $st = $el_word;
        while ($st) {
            last if ($st->isa("PPI::Statement::Include"));
            $st = $st->parent;
        }
        next if $st;
        $used{"$el_word"}++;
    }

    my @violations;
    my @to_report = grep { !$used{$_} } (sort keys %defined_constants);
    for my $tok (@to_report) {
        for my $el (@{ $defined_constants{$tok} }) {
            push @violations, $self->violation( "Unused constant", "A constant <$tok> is defined but not used.", $el );
        }
    }

    return @violations;
}

1;

=encoding utf-8

=head1 NAME

TooMuchCode::ProhibitUnusedConstant -- Find unused constants.

=head1 DESCRIPTION

This policy finds constant declaration by "constant" pragma, and further look for their exists in the rest code.
(The scope of searching is with the same file.)

It identifyes constants defined in two simple forms, such as:

    use constant PI => 3.14;

... and

    use constant { PI => 3.14, TAU => 6.28 };

=cut
