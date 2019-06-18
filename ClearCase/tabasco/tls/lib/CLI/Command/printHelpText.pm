package CLI::Command::printHelpText;

use strict;
use Carp;
use CLI;
use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
   $VERSION = '0.09';
   require Exporter;

   @ISA = qw(Exporter CLI::Command);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

} # sub BEGIN()



sub run {
   my $self = shift;

   $self->printEnvironmentHeader();

   print "The following commands are provided.\n";
   print "All commands can be called with option -help for further documentation.\n";
   print "All commands can be called with option -verb progress | debug for verbose output.\n";

   my @allCommands = sort keys %CLI::Config::COMMAND;
   foreach my $cmd ( @allCommands ) {
     print "\n$cmd" . " (short form: " . $CLI::Config::COMMAND{ $cmd }->{ 'short' } . ")\n";
      my $description = $CLI::Config::COMMAND{ $cmd }->{'description'};

      if ( ref $description ) {
         foreach ( @$description ) { printf "      %s\n", $_; }
      }  else {
            printf "      %s\n", $description ;
      }
   }

   return 0;
} # run

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


