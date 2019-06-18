package ClearCase::View;

use strict;
use Carp;

use ClearCase::Common::Config;
use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;

   @ISA = qw(Exporter);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
      Path => { CALCULATE => \&loadViewData },
      Tag         => { CALCULATE => \&loadViewData },
      Tag_UUID    => { CALCULATE => \&loadViewData },
      Server      => { CALCULATE => \&loadViewData },
      Active      => { CALCULATE => \&loadViewData },
      Host        => { CALCULATE => \&loadViewData },
      UUID        => { CALCULATE => \&loadViewData },
      Owner       => { CALCULATE => \&loadViewData },
      Type        => { CALCULATE => \&loadViewData }
      );

   require Data;
   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => undef
      );

} # sub BEGIN()

sub new {
   my $proto = shift;
   my $class = ref( $proto ) || $proto;
   my $self  = {};
   bless( $self, $class );

   my $tag_name = shift;
   unless ( defined $tag_name )
   {
      Die( [ "Usage ".__PACKAGE__."->new( \$tagname )" ] );
   }

   $self->setTag( $tag_name );
   $self->setType( 'dynamic' );
   return $self;
} # new

sub loadViewData {
   my ( $self ) = @_;

   ClearCase::lsview(
      -long    => 1,
      -viewtag => $self->getTag() );
   Debug( [ 'start initializing view ' . $self->getTag() ] );
   foreach my $line( ClearCase::getOutput() )
   {
      foreach my $regex ( keys %ClearCase::Common::Config::CC_LSVIEW_VALUES )
      {
	  Debug( [ 'Line  : ' . $line,
		   'Key   : ' . $regex,
		   'Regex : ' . $ClearCase::Common::Config::CC_LSVIEW_VALUES{$regex} ] );
         if ( $line =~ m/$ClearCase::Common::Config::CC_LSVIEW_VALUES{$regex}/ )
	   {
	       Debug( [ 'matched, set attribute ' . $regex ] );
	       $self->set( $regex, $1 );
	   }   
      }
   }
   return;
}

sub getConfigSpec {
   my $self = shift;

   ClearCase::catcs( -tag => $self->getTag() );

   my @result = ClearCase::getOutput();
   grep ( chomp, @result );

   return @result;
} # getConfigSpec

sub setConfigSpec
  {
      my $self = shift;
      my $refcs = shift;

      my $cspec = join( "\n", @$refcs );
      Debug( [ 'set new config spec:',
	       $cspec ] );
      ClearCase::setcs(
		       -cspec      => $cspec,
		       -tag        => $self->getTag
		      );
      return (ClearCase::getRC() == 0);
  }

sub lsprivate {
   my $self = shift;

   ClearCase::lspriv();

   my @result = ClearCase::getOutput();
   grep ( chomp , @result );

   return @result;
} # lsprivate

sub cwdInVob {
    my $self = shift;

    my $directoryVersion = ClearCase::Version->new( -pathname => '.' );
    return $directoryVersion;
}


1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2007 Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com

=head1 SEE ALSO

=cut
