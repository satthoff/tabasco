package ClearCase::Command::mkhltype;

# ============================================================================
# standard modules
use strict;                   # restrict unsafe constructs
use Carp;

use Log;

sub BEGIN {
   # =========================================================================
   # global definitions
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);

   # set the version for version checking. All on one line !!!!!
   $VERSION = '0.01';

   # =========================================================================
   # required Moduls
   require Exporter;          # implements default import method for modules
   require Transaction::Command;

   # =========================================================================
   #
   @ISA = qw(Exporter Transaction::Command Data);

   # =========================================================================
   # Exporter

   # symbols to export by default
   # Note: do not export names by default without a very good reason. Use
   # EXPORT_OK instead.  Do not simply export all your public
   # functions/methods/constants.
   @EXPORT = qw(
   );

   # symbols to export on request.
   @EXPORT_OK = qw(
   );

   # define names for sets of symbols.
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
       Name     => undef,
       Vob      => undef,
       Comment  => undef,
       Global   => undef,
       Acquire  => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()


# ============================================================================
# non exported package globals

# ============================================================================
# initialize package globals ( exported )

# ============================================================================
# initialize package globals ( not exported )

# ============================================================================
# file private lexicals


# ============================================================================
# Description

=head1 NAME

checkin - <short description>

=head1 SYNOPSIS

B<checkin.pm> [options]

=head1 DESCRIPTION

<long description>

=head1 USAGE

=head1 METHODS

=cut

# ============================================================================
# Preloaded methods go here.

sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $name, $vob, $comment, $global, $acquire, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION NAME VOB COMMENT GLOBAL ACQUIRE ) ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setName( $name );
   $self->setVob( $vob );
   $self->setGlobal( $global );
   $self->setAcquire( $acquire );
   $self->setComment( $comment );

   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();

   if ( defined $self->getComment() )
   {
      push @options, ' -c "' . $self->getComment() . '"';
   }
   else
   {
      push @options, ' -nc';
   }

   push @options, '-shared'; #hyperlink types are always shared
   push @options, '-global' if $self->getGlobal();
   push @options, '-acquire' if $self->getAcquire();

   ClearCase::Common::Cleartool::mkhltype(
      @options,
      $self->getName() . '@' . $self->getVob() );
}

sub do_commit {
   my $self = shift;
}

sub do_rollback {
   my $self = shift;
   ClearCase::Common::Cleartool::rmtype(
      '-f',
      '-rmall',
      'hltype:'. $self->getName() . '@' . $self->getVob() );
}


# ============================================================================
# Autoload methods go after =cut, and are processed by the autosplit program.
#
# remeber to
#  require AutoLoader

1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2007  Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com.

When   sending   bug   reports,   please  provide   the   version   of
checkin.pm, the  version of Perl and  the name and version  of the
operating system you are using.


=head1 SEE ALSO

=cut
