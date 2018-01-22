package ClearCase::Command::mkbranch;

use strict;
use Carp;

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
	    Name     => undef,
	    Version  => undef,
	    Checkout => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()

sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $pathname, $version, $name, $co, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION PATHNAME VERSION NAME CHECKOUT ) ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction, $pathname );
   bless $self, $class;

   $self->setName( $name );
   $self->setVersion( $version ) if( $version );
   $self->setCheckout( 1 );
   $self->setCheckout( $co ) if( defined $co );

   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();

   push @options, '-nc';
   push @options, '-version ' . $self->getVersion() if( $self->getVersion();
   push @options, '-nco' unless( $self->getCheckout() );
   push @options, $self->getName();
   ClearCase::Common::Cleartool::mkbranch(
				  @options, $self->getPathname()
				 );
}

sub do_commit {
   my $self = shift;
}

sub do_rollback {
   my $self = shift;
   my $v = $self->getVersion();
   $v =~ s/\\/\//g if( defined $ENV{ OS } ); # always UNIX style
   $v =~ s/^(.*\/)\d+$/$1/;
   my $p = $self->getPathname();
   $p =~ s/\"//g;
   $p =~ s/\'//g;
   my $branch =  '"' . $p . '@@' . $v . $self->getName() . '"';
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

Address bug reports and comments to: uwe@satthoff.eu

=head1 SEE ALSO

=cut
