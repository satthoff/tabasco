package ClearCase::Command::mkbranch;

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
       BranchType  => undef,
       Checkout => undef,
       Argv => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()

sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $argv, $branchType, $co, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION ARGV BRANCHTYPE CHECKOUT ) ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setBranchType( $branchType );
   $self->setCheckout( 1 );
   $self->setCheckout( $co ) if( defined $co );
   $self->setArgv($argv);

   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();

   push @options, '-nc';
   push @options, '-nco' unless( $self->getCheckout() );
   push @options, $self->getBranchType()->getFullName();
   ClearCase::Common::Cleartool::mkbranch(
				  @options, $self->getArgv()
				 );
}

sub do_commit {
   my $self = shift;
}

sub do_rollback {
   my $self = shift;
   my $p = $self->getArgv();
   $p =~ s/\"//g;
   $p =~ s/\'//g;
   my $branch =  '"' . $p . '@@/' . $self->getBranchType()->getName() . '"';
   my @options = ();
   push @options, '-nc';
   push @options, '-force';
   ClearCase::Common::Cleartool::rmbranch( @options, $branch );
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
