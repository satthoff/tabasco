package IF_template::Class;

use strict;
use Carp;

use IF_template::Common::Config;
use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;

   @ISA = qw(Exporter);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
	Topic => { CALCULATE => \&loadTopic }
      );

   require Data;
   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => undef
      );

} # sub BEGIN()

sub new {
   my $proto = shift;
   my $class = ref( $proto ) || $proto;
   my $self  = {};
   bless( $self, $class );

   my ( $topic, @other ) = $self->rearrange(
      [ 'TOPIC' ],
      @_ );

   $self->setTopic( $topic ) if( $topic );
   return $self;
} # new

sub loadLatestVersion {
    my $self = shift;

    my $some = 'X';
    return $self->setTopic( $some );
}
1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2006 Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com

=head1 SEE ALSO

=cut
