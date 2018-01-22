package TaBasCo::Release;

use strict;
use Carp;

use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;

   @ISA = qw(  Exporter Data ClearCase::Version );

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   require Data;

   %DATA = (
	    Task => { CALCULATE => \&loadTask },
	    Name => { CALCULATE => \&loadName },
	    Previous => { CALCULATE => \&loadPrevious }
	   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => "ClearCase::Version"
      );

} # sub BEGIN()

sub load {
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self  = {};
    bless $self, $class;

    Debug( [ '', 'BEGIN: ' . __PACKAGE__ . '::new' ] );

    my ( $name, @other ) = $self->rearrange(
	[ 'NAME' ],
	@_ );

    ClearCase::find(
	-pathname => TaBasCo::Config::getConfigElement()->getElement(),
	-version => 'lbtype(' . $name . ')',
	-print => 1
	);
    my @versions = ClearCase::Common::Cleartool::getOutput();
    return undef unless( @versions );
    my $latestVersion = $versions[$#versions];

    my $theRelease = $self->new( -pathname => $latestVersion );
    return $theRelease;
}

sub applyName
  {
    my $self = shift;
    my $name = shift;

    $self->SUPER::mklabel( -name => $name, -replace => 1 );
    $self->setName( $name );
    return $self;
  }

sub pathVisible
  {
    my $self = shift;
    my $path = shift;
    my $view = shift;

    Transaction::start( -comment => "set correct config spec to check path existence in release " . $self->getName() );
    my $cspecFile = $self->getVXPN();
    open FD, "$cspecFile";
    my @cspec = <FD>;
    close FD;
    grep chomp, @cspec;
    # delete all carrige return from contents,
    # which will be added by changes edited on Windows
    grep s/\r//g, @cspec;
    $view->setConfigSpec( \@cspec );
    my $ret = ( -e $path );
    Debug( [  __PACKAGE__ . "::pathVisible >$path<" ] );
    if( $ret )
      {
	Debug( [ '    path is visible' ] );
      }
    else
      {
	Debug( [ '    path is NOT visible' ] );
      }
    Transaction::rollback(); # reset the config spec
    return $ret;
  }

sub createFloatingRelease
  {
    my $task = shift;

    my $floatingLabel = uc( $task->getName() . $TaBasCo::Config::nextLabelExtension );
    my $lbtype = ClearCase::InitLbType( -name => $floatingLabel, -vob => $task->getVob() );
    $lbtype->create();
    return $lbtype;
  }

sub renameFloatingRelease
  {
    my $task = shift;
    my $name = shift;

    my $floatingLabel = uc( $task->getName() . $TaBasCo::Config::nextLabelExtension );
    my $lbtype = ClearCase::InitLbType( name => $floatingLabel, -vob => $task->getVob() );
    $lbtype->rename( $name );
  }

sub loadName
  {
    my $self = shift;

    my @labels = $self->getLabels();
    my @names = grep !m/^${TaBasCo::Config::cspecLabel}$/, @labels;
    return undef unless( @names );
    return undef unless( $#names == 0 );
    return $self->setName( $names[0] );
  }

sub loadPrevious
  {
    my $self = shift;

    my $pv = $self->getPreviousVersion();
    return undef unless( $pv );
    while( $pv )
      {
         my $name = $pv->getName();
         return $self->setPrevious( $pv ) if( $name );
         $pv = $pv->getPreviousVersion()
      }
    return undef;
  }


sub loadTask
  {
    my $self = shift;

    Debug( [ '', 'BEGIN: ' . __PACKAGE__ . '::loadTask' ] );
    return $self->setTask( TaBasCo::Task->new(  -pathname => $self->getMyBranch()->getVXPN() ) );
  }

1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2010  Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: uwe@satthoff.eu


=head1 SEE ALSO

=cut
