package ClearCase::Label;

use strict;
use Carp;
use Log;

use File::Basename;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;
   require Data;

   @ISA = qw(Exporter Data);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
       Version => undef,
       Name => undef
       );

   Data::init(
       PACKAGE => __PACKAGE__,
       SUPER => 'Data'
      );

} # sub BEGIN()

sub new() {
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self  = {};
    bless $self, $class;

    my ( $name, $replace, $version, $alreadyAttached, @other ) = $self->rearrange(
	[ 'NAME', 'REPLACE', 'VERSION', 'ALREADYATTACHED' ],
	@_ );
    confess @other if @other;

    if( $replace ) {
	$replace = 1;
    } else {
	$replace = 0;
    }

    $self->setName( $name );
    $self->setVersion( $version );

    my @labels = ();
    unless( $alreadyAttached ) {
	ClearCase::describe(
	    -argv => $version->getVXPN(),
	    -fmt => '%Nl'
	    );
	my $l = ClearCase::getOutputLine();
	chomp $l;
	@labels = split /\s+/, $l;
    } else {
	push @labels, $name;
    }

    if( grep !m/^${name}$/, @labels or $replace ) {
	clearcase::mklabel(
	    -argv    => $version->getVXPN(),
	    -label   => $name,
	    -replace => $replace
	    );
	return undef if( ClearCase::getRC() != 0 );
    }
    return $self;
}

1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2007 Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com

=head1 SEE ALSO

=cut
