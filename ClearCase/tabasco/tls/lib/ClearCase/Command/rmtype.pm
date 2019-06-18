package ClearCase::Command::rmtype;

use strict;
use Carp;
use Cwd;
use File::Basename;
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
      Type     => undef,
      RmAll    => undef,
      Force    => undef,
      Vob      => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()

sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $type, $rmall, $force, $vob, @other ) =
      $class->rearrange(
         [ 'TRANSACTION', 'TYPE', 'RMALL', 'FORCE', 'VOB' ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setType( $type );
   $self->setRmAll( $rmall );
   $self->setForce( $force );
   $self->setVob( $vob );
   return $self;
}

sub do_execute {
   my $self = shift;
   my @options;

   push @options, '-force'    if $self->getForce();
   push @options, '-rmall'    if $self->getRmAll();

   #  warning the following code is not able to rollback a half done command!
   ClearCase::Common::Cleartool::rmtype( @options, $self->getType() . '@' . $self->getVob() );

}

sub do_commit {
   my $self = shift;
}

sub do_rollback {
   my $self = shift;

   Warn( [ 'Rollback of rmtype not POSSIBLE!',
           '  Type ' . $self->getType() . ' not restored' ] );

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
