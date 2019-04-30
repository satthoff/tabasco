package ClearCase::Common::Oid;

use strict;
use Carp;
use File::Basename;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
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

} # sub BEGIN()

sub OidToPath
  {
   my $oid = shift;

   my $path = '';
   ClearCase::describe(
                       -pathname => 'oid:' . $oid,
                       -fmt      => '%n'
                      );
   $path = ClearCase::Common::Cleartool::getOutputLine();
   chomp $path;
   return $path;
  }


sub PathToOid
  {
   my $path = shift;

   my $oid = '';
   ClearCase::describe(
                       -pathname => $path,
                       -fmt      => '%On'
                         );
   $oid =  ClearCase::Common::Cleartool::getOutputLine();
   chomp $oid;
   my $vob = ClearCase::Vob->load( $path );
   return $oid . '@vobuuid:' . $vob->getUUID();
  }


1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

    Copyright (C) 2007 Uwe Satthoff
    satthoff@icloud.com

=cut
