package TaBasCo::Common::Template;

use strict;
use Carp;

use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;

   @ISA = qw(  Exporter Data );

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   require Data;

   %DATA = (
            Name             => undef,
	    ProcessName      => { CALCULATE => \&loadProcessName }
	   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => ""
      );


} # sub BEGIN()

sub init
  {
      my $self = shift;

   my ( $name, $xx2 ) = $self->rearrange(
      [ qw( NAME XX2 ) ],
      @_ );

      $self->setName( $name ) if $name;
  }

sub new
{
   my $proto = shift;
   my $class = ref ($proto) || $proto;
   my $self  = {};
   bless $self, $class;
   $self->init( @_ );
   return $self;
} # new ()


sub loadProcessName
  {
    my $self = shift;

    ClearCase::describe(
			-fmt      => '"%[' . $PKG::Config::atProcess . ']NSa"',
			-pathname => $self->getCCIdentifier()
		       );
    my $att = ClearCase::Common::Cleartool::getOutputLine();
    chomp $att;
    if( $att ne '' )
      {
	$att =~ s/\"//g;
	return $self->setProcessName( $att );
      }
    else
      {
	return undef;
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
