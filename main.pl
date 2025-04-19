#!/usr/bin/perl
use strict;
use warnings;
use Cwd 'getcwd';

sub searchlangdata{
    my $lang = $_[0]."\n";
    my $collum = $_[1];

    my $output = "";
    
    my $flag = 0;
    open(FILE, ".build_data");
    
    while(<FILE>){
	if($_ =~ "end section assemble"){
	    $flag = 0;
	    last;
	}
	
	if($flag == 1){
	    my $line = $_;
	    my $data = $line;
	    $data =~ s/:.+:.+//;
	    if($data eq $lang){
		if($collum eq "path"){
		$data = $line;
		$data =~ s/.+:(.+):[\d\D]+/$1/e;
		$output = $data;
		last;
	    } elsif($collum eq "command"){
		$data = $line;
		$data =~ s/.+:.+:(.+)\n/$1/e;
		$output = $data;
		last;
		}
	    }
	}

	if($_ eq "section assemble\n"){
	    $flag = 1;
	}
    }
    close(FILE);

    if($flag eq ""){
	return "";
    }else{
	return $output;
    }
}

sub setup{
    if($_[0] eq ""){
	die "Please enter projectname in after \"setup\".\n"
    }
    open(FILE, '>.build_data');
    print FILE ("section basicdata\nname : ".$_[0]."\nend section basicdata\n\n\nsection assemble\nend section assemble\n");
    close(FILE);
    mkdir "src" or die "mkdir failed.\n";
}

sub addsrcdir{
    my $langdata = $_[0];
    if($langdata !~ /.+:.+:.+/){
	die "Entered language data is not comply with format.\n";
    }
        
    my $count = 0;
    my @filedata;
    
    open(FILE, ".build_data");
    while(<FILE>){
	$filedata[$count] = $_;
	if($filedata[$count] eq "section assemble\n"){
	    $count = $count + 1;
	    $filedata[$count] = $langdata."\n";
	}
	$count = $count + 1;
    }
    close(FILE);
    
    open(FILE, ">.build_data");
    foreach my $line (@filedata){
	print FILE ($line);
    }
    close(FILE);

    $langdata =~ s/(.+):.+:.+/$1/e;
    my $path = searchlangdata($langdata, "path");
    mkdir $path or die "make new directory is failed\n";
    
    open(FILE, ">".$path."/.srclist");
    close(FILE);
}

sub addfile{
    my $filename = $_[0];
    my $extension = $filename;
    $extension =~ s/.+\.(.+)/$1/e;
    
    my $path = searchlangdata($extension, "path");
    if($path eq ""){
	die "extension is not found\n";
    }
    
    open(FILE, ">".$path."/".$filename);
    close(FILE);
    
    open(FILE, ">>".$path."/.srclist");
    print FILE ($filename."\n");
    close(FILE);
}

sub build{
    my $basedir = getcwd;
    my $objlist = " ";
    
    my $name;
    my $linkcommand;
    
    open(FILE, ".build_data");
    my $flag = 0;
    while(<FILE>){
	my $line = $_;
	
	if($line =~ /name:.+/){
	    $name = $line;
	    $name =~ s/name:(.+)\n/$1/e;
	}
	
	if($line =~ /link:.+/){
	    $linkcommand = $line;
	    $linkcommand =~ s/link:(.+)\n/$1/e;
	}
	
	if($line =~ "end section assemble"){
	    last;
	}
	
	if($flag == 1){
	    my $path = $line;
	    $path =~ s/.+:(.+):[\d\D]+/$1/e;
	    
	    chdir($path);
	    
	    open(SRCLIST, ".srclist");
	    while(<SRCLIST>){
		my $srcfile = $_;
		my $command = $line;
		$command =~ s/.+:.+:(.+)\n/$1/e;
		$command =~ s/<src>/$srcfile/;
		$srcfile =~ s/\..+\n/.o/;
		$command =~ s/<obj>/$srcfile/;
		system($command);
		if(-e $srcfile){
		    $objlist = $objlist.$path."/".$srcfile." ";
		} else {
		    die "$srcfile not found. most likely due to a compilation failure.\n ";
		}
	    }
	    close(SRCLIST);
	    chdir($basedir);
	}
	
	
	if($line eq "section assemble\n"){
	    $flag = 1;
	}
    }
    close(FILE);
    
    $linkcommand =~ s/<name>/$name/;
    $linkcommand =~ s/<obj>/$objlist/;
    system($linkcommand);
}

if ($ARGV[0] ne "setup"){
    open(FILE, ".build_data") or die "please execute `ppm setup`\n";
}

if ($ARGV[0] eq "setup"){
    setup($ARGV[1]);
} elsif ($ARGV[0] eq "addsrcdir"){
    addsrcdir($ARGV[1]);
} elsif ($ARGV[0] eq "addfile"){
    if ($ARGV[1] eq ""){
	print "please set filename for after \"addfile\"";
    }else{
	addfile($ARGV[1]);
    }
} elsif ($ARGV[0] eq "build"){
    build();

}
