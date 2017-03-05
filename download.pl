#!/usr/bin/perl -wT

###########################################################################
############### © Soumik Ghosh - soumik@soumikghosh.com     ###############
############### Requires Perl 5.11.2 or above               ###############
###########################################################################

use CGI ':standard';
use CGI::Carp qw(fatalsToBrowser);

use strict;
use warnings;

my $picdir;
my $zipname;
my $rf = $ENV{'HTTP_REFERER'};

if($rf =~ m|^https?://(?:\w+\.)?websitename\.(?:com\|ru)/(members)?/?(\w+)/(\w+)/(?:page\d+\.php)?$|ig)
{
        if(defined($1))
        {
                $picdir = "/home/user/websitename.com/$1/$2/$3";
                $zipname = "$2-$3-$1.zip";
        }
        else {
                $picdir = "/home/user/websitename.com/$2/$3";
                $zipname = "$2-$3.zip";
        }
}
else {
        die "An error has occured.[BR]\n";
}

my $zipdir = '/var/www/zips';
my $zipfile = "$zipdir/$zipname";

if (-e $zipfile) # If file exists
{
        download($zipfile, $zipname, 'HIT') or die 'Cannot send existing file for download.';
}
else {
        use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
        use File::Spec;

        my $zip = Archive::Zip->new() or die 'Cannot create ZIP archive.';

        opendir my $dh, $picdir or die 'Cannot open dir';
	while (readdir $dh)
        {
                next if !/\.jpg$/;
                $zip->addFile(File::Spec->catfile($picdir, $_), $_)->desiredCompressionMethod( COMPRESSION_STORED ) or die 'Cannot add file.';
        }
        closedir $dh;

        # Save the Zip file
        unless ( $zip->writeToFileNamed($zipfile) == AZ_OK )
        {
                die 'Write error';
        }

        # Delete least recently accessed file if no. of files > 29
        my @files = <$zipdir/*>;
        if(@files > 29)
        {
                my %cache;
                my @sorted = sort { ($cache{$a} ||= -A $a) <=> ($cache{$b} ||= -A $b) } @files;
                my $temp = @sorted[-1];
                $temp =~ /(.*)/;
                $temp=$1;
                unlink $temp or die "Could not delete file.\n";
        }

        download($zipfile, $zipname, 'MISS') or die 'An unknown error has occured';
}

sub download {
        my $file = shift or return(0);

        # For debugging, uncomment
        #open(my $DLFILE, '<', "$file") or die "Can't open file '$file' : $!";

        # Comment when debugging
        open(my $DLFILE, '<', "$file") or return(0);

        # this prints the download headers with the file size included
        # so you get a progress bar in the dialog box that displays during file downloads.
        print header(-type            => 'application/x-download',
                     -attachment      => shift,
                     -Content_length  => -s "$file",
                     -ZIP_cache       => shift,
        );

        binmode $DLFILE;
        print while <$DLFILE>;
        undef ($DLFILE);
        return(1);
}
