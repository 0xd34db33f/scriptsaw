#!/usr/bin/perl -w
# pcre-matcher.pl : feed it pcres, spit out matches. *** USES EVAL() ***
# Ryan C. Moon
# 24 April 2013

use strict;

if ($#ARGV < 1) {
	die "Illegal usage.\n\tUsage: ./pcre-matcher.pl <url> <text file with pcres> \n\tex: ./pcre-matcher http://www.google.com /tmp/pcres.txt\n";
}

my $pcre_file = $ARGV[1];
my $url = $ARGV[0];
my @pcres = ();

die "$pcre_file does not exist!\n" unless (-e $pcre_file);
die "$pcre_file is not readable!\n" unless (-r $pcre_file);
die "$pcre_file is empty!\n" unless (-s $pcre_file);

open FILE, "<$pcre_file" or die $!;
while(<FILE>) { 
	chomp $_;
	push(@pcres,$_); 
}

foreach my $pcre (@pcres) {
	my $regex = eval { qr/$pcre/ };
	die "Regex not valid: $pcre -- $@ \n" if $@;
	print "[!] Match $pcre \n" if ($url =~ /$pcre/);
}

