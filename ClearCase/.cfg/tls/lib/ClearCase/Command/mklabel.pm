package ClearCase::Command::mklabel;

use strict;                   # restrict unsafe constructs
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
      Label     => undef,
      UndoList  => undef,
      Recurse   => undef,
      Replace   => undef,
      Version   => undef,
      Comment   => undef,
      Argv      => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()

sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $label, $argv, $version, $recurse, $replace, $comment, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION LABEL ARGV VERSION RECURSE REPLACE COMMENT) ],
         @_ );
   confess join( '-', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setLabel( $label );
   $self->setRecurse( $recurse );
   $self->setReplace( $replace );
   $self->getComment( $comment );
   $self->setVersion( $version );
   $self->setArgv( $argv );
   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();

   if ( defined $self->getComment() )
   {
      push @options, '-c "' . $self->getComment() . '"';
   }
   else
   {
      push @options, '-nc';
   }

   push @options, '-recurse'  if $self->getRecurse();
   push @options, '-replace'  if $self->getReplace();
   push @options, '-version ' . $self->getVersion() if $self->getVersion();

   ClearCase::Common::Cleartool::mklabel(
      @options,
      $self->getLabel(),
      $self->getArgv() );

   my @undoList;
   my $create = $ClearCase::Common::Config::CC_LBTYPE_OUTPUT{'CREATE'};
   my $move = $ClearCase::Common::Config::CC_LBTYPE_OUTPUT{'MOVE'};
   foreach( ClearCase::Common::Cleartool::getOutput() )
   {
      /^$create$/o && do {
         push @undoList, [ 'CREATE', $1, $2, $3 ];
      };
      /^$move$/o && do {
         push @undoList, [ 'MOVE', $1, $2, $3 ];
      };
   }

   $self->setUndoList( \@undoList );
}

sub do_commit {
   my $self = shift;
}

sub do_rollback {
   my $self = shift;

   foreach( @{ $self->getUndoList() } )
   {
      my ( $action, $label, $element, $version ) = @$_;

      for( $action )
      {
         /CREATE/ && ClearCase::Common::Cleartool::rmlabel(
            '-nc',
            $self->getLabel(),
            $element . '@@' .$version );
         /MOVE/ && ClearCase::Common::Cleartool::mklabel(
            '-nc',
            '-replace',
            $self->getLabel(),
            $element . '@@' .$version );
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
