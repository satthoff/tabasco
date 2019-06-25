package TaBasCo::Configuration;

use strict;
use Carp;
use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;
   require Data;
   require ClearCase::BrType;

   @ISA = qw(Exporter Data ClearCase::BrType );

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
       Tasks => { CALCULATE => \&loadTasks },
       Releases => { CALCULATE => \&loadReleases },
       ConfigSpec => { CALCULATE => \&loadConfigSpec }
       );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'ClearCase::BrType'
      );
} # sub BEGIN()


sub _init {
   my $self = shift;

   $self->SUPER::_init( -vob => $TaBasCo::Common::Config::myVob, @_ );
   return $self;
} # _init

sub create {
    my $self = shift;

    my ( $tasks, $releases, @other ) = $self->rearrange(
	[ 'TASKS', 'RELEASES' ],
	@_ );

    # check tasks existence

    # check releases existence

    $self->SUPER::create();

    # register the new config as a known config
    $self->createHyperlinkFromObject(
	-hltype => ClearCase::HlType->new( -name => $TaBasCo::Common::Config::configLink, -vob => $self->getVob() ),
	-object => $self->getVob()->getMyReplica()
	);

    # declare all tasks as member of the config

    # declare all releases as member of the config

    return $self;
}

sub exists {
    my $self = shift;

    if( $self->SUPER::exists() ) {
    }
    return 0;
}

sub loadConfigSpec  {
    my $self = shift;

    my @config_spec = ();

    return $self->setConfigSpec( \@config_spec );
}

sub loadTasks  {
    my $self = shift;

    my @tasks = ();

    return $self->setTasks( \@tasks );
}

sub loadReleases  {
    my $self = shift;

    my @releases = ();

    return $self->setReleases( \@releases );
}
1;

__END__

=head1 EXAMPLES

=head1 AUTHOR INFORMATION

 Copyright (C) 2016 Uwe Satthoff

=head1 BUGS

 Address bug reports and comments to:
  satthoff@icloud.com

=head1 SEE ALSO

=cut


