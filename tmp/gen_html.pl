
use File::Basename;

my $htmlFile = '/Library/WebServer/Documents/index.html';

open HT, ">$htmlFile";
print HT "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n";

print HT "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"de\" lang=\"de\">\n";

print HT "\t<head>\n";
print HT "\t\t<title>Web Release Server</title>\n";
print HT "\t\t<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n";
print HT "\t\t<style type=\"text/css\">\n";
print HT "\t\t\t table{border:solid 1px #000000;border-collapse:collapse;} th,td{font-size: 16px; border:solid 1px #000000;padding:6px 30px;font-weight:bold;text-align:center;} div{margin:30px 20px;} div.inner{margin:4px 0px;} h3.blockHeader{padding:6px;background-color:#ededed;margin-top:20px;}\n";
print HT "\t\t</style>\n";
print HT "\t</head>\n";

print HT "\t<body>\n";
print HT "\t\t<h1>Web Release Server</h1><hr />\n";
print HT "\t\t\t<a href=\"/pkgProd\" title=\"Scanner production packages\">Scanner production packages</a><hr />\n";
print HT "\t\t\t<a href=\"/pkgTest\" title=\"Scanner test packages\">Scanner test packages</a><hr />\n";
print HT "\t</body>\n";

print HT "</html>\n";
close HT;
