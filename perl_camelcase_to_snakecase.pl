#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

my ($dir) = @ARGV;
die "Choose a path!" unless defined $dir;

sub get_filelist
{
	my ($curdir) = @_;
	my @ret;

	foreach my $item (glob "$curdir/*") {

		if (-d $item) {
			next if ($item =~ m/^$curdir\/blib/);
			my $nested_files = get_filelist($item);
			push @ret, @$nested_files;
		} elsif (-f $item) {
			push @ret, $item;
		}

	}

	return \@ret;
}

my @list = grep { m:.*\.(pm|t)$: } @{get_filelist($dir)}; # lista plików do sprawdzenia
my @defs; # lista nazw funkcji do podmiany
my @attributes; # lista nazw atrybutów do podmiany

foreach my $path (@list) {

	open my $file, '<', $path;
	while (my $line = <$file>) {
		chomp $line;
		if ($line =~ m/^__END__/) {
			last;
		}
		if ($line =~ m/(?<=\bsub)\s+(\w+([A-Z]\w*)+)(?=\W|$)/) {
			push @defs, $1;
		}
		if ($line =~ m/(?<=^has)\s+["']?(\w+([A-Z]\w*)+)(?=\W|$)/) {
			push @attributes, $1;
		}
	}
}

foreach my $path (@list) {

	my $file;
	open $file, '<', $path;
	my @old_lines = <$file>;
	close $file;
	open $file, '>', $path;
	foreach my $line (@old_lines) {

		foreach my $item (@defs, @attributes) {
			my $replace = $item =~ s/([A-Z])/"_".lc($1)/ger;
			$line =~ s/(?<=\W)$item(?=\W)/$replace/g;
		}
		print $file $line;
	}
	close $file;
}