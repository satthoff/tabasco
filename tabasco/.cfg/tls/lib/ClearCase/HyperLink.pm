package ClearCase::HyperLink;

use strict;
use Carp;
use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;
   require ClearCase::Element;

   @ISA = qw(Exporter ClearCase::Element);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
      Target   => undef,
      HlType   => undef
      );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => "ClearCase::Element"
      );


} # sub BEGIN()

sub new($$$)
{
   my ( $proto, $hltype, $base, $target ) = @_;
   my $class = ref ($proto) || $proto;
   my $self  = $class->SUPER::_new( $base );
   bless $self, $class;

   # initialize
   $self->setTarget( $target );
   $self->setHlType( $hltype );

   return $self;
} # new ()

1;

__END__

=head1 EXAMPLES

=head1 AUTHOR INFORMATION

 Copyright (C) 2007 Uwe Satthoff

=head1 BUGS

 Address bug reports and comments to:
   uwe@satthoff.eu

=head1 SEE ALSO

=cut

##############################################################################

