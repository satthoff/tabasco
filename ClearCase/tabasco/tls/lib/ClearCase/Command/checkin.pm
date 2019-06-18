package ClearCase::Command::checkin;

use strict;
use Carp;
use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;
   require Transaction::Command;

   @ISA = qw(Exporter Transaction::Command);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
       Argv => undef,
       UndoList       => undef,
       Identical      => 0
       );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()


sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $identical, $argv, @other ) =
      $class->rearrange(
         [ 'TRANSACTION', 'IDENTICAL', 'ARGV' ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;
   $self->setIdentical( $identical ) if defined $identical;
   $self->setArgv( $argv );
   return $self;
}

sub do_execute {
   my $self = shift;

   my @options = ();
   push @options, $self->getComment();
   push @options, '-identical' if ($self->getIdentical());
   ClearCase::Common::Cleartool::checkin(
      @options,
      $self->getArgv() );

   my @undoList;
   my $co = $ClearCase::Common::Config::CC_CHECKIN_OUTPUT;
   foreach( ClearCase::Common::Cleartool::getOutput() )
   {
      /^$co$/o && do {
         push @undoList, [ $1, $2 ];
      };
   }

   $self->setUndoList( \@undoList );
}

sub do_commit {
   my $self=shift;
}

sub do_rollback {
   my $self=shift;

   # foreach element to uncheckin, do the following
   # 1. make a backup of the version checked in
   # 2. remvove checked in version
   # 3. checkout elements
   # 4. mv backup to checkedout
   my @elementVersions;
   my @elements;
   foreach( reverse @{ $self->getUndoList() } )
   {
      my ( $element, $version ) = @$_;

      print "UNCHECK IN $element, $version\n";

      push ( @elementVersions, $element . '@@' . $version );
      push ( @elements, $element );

      if ( -d $element ) {
         Warn ( [ 'Rollback for directory not possible!'] );
      } else {
         ClearCase::Common::Cleartool::execute( 'cp', "$element", "$element.$$" );
      }
   }

   ClearCase::Common::Cleartool::rmver( '-f', '-xhl', '-xla', @elementVersions )
      if @elementVersions;

   ClearCase::Common::Cleartool::checkout( '-nc', @elements )
      if @elements;

   foreach( reverse @{ $self->getUndoList() } )
   {
      my ( $element, $version ) = @$_;
      if ( ! -d $element ) {
         ClearCase::Common::Cleartool::execute( 'mv', "$element.$$", "$element" );
         ClearCase::Common::Cleartool::execute( 'chmod', 'u+w',  "$element.$$", "$element" );
      }
   }

}


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

Address bug reports and comments to: satthoff@icloud.com


=head1 SEE ALSO

=cut
