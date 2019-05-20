package ClearCase::Replica;

# ============================================================================
# standard modules
use strict;                   # restrict unsafe constructs
use Carp;

sub BEGIN {
   # =========================================================================
   # global definitions
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);

   # set the version for version checking. All on one line !!!!!
   $VERSION = '0.01';

   # =========================================================================
   # required Moduls
   require Exporter;          # implements default import method for modules
   require ClearCase::Common::MetaObject;

   # =========================================================================
   #
   @ISA = qw(Exporter ClearCase::Common::MetaObject);

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
	   );
   require Data;
   Data::init(
      PACKAGE     => __PACKAGE__,
      SUPER       => 'ClearCase::Common::MetaObject'
      );


} # sub BEGIN()


sub _init {
   my $self = shift;

   $self->SUPER::_init( -type => 'replica', @_ );
   return $self;
} # _init

sub create {
   my $self = shift;

   Die( [ 'subroutine create of ' . __PACKAGE__ . ' is not yet implemented.' ] );
#   ClearCase::mklbtype(
#       -name    => $self->getName(),
#       -pbranch => $pbranch,
#       -vob     => $self->getVob()->getTag()
#      );

   return $self;
} # create



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

 Copyright (C) 2007   Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com.

When   sending   bug   reports,   please  provide   the   version   of
BrType.pm, the  version of Perl and  the name and version  of the
operating system you are using.


=head1 SEE ALSO

=cut
