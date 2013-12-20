#!/usr/intel/pkgs/perl/5.14.1/bin/perl
use warnings;
use strict;
use UsrIntel::R1;
use feature qw(say);
use autodie;
use Data::Dumper;
use File::Slurp;
use Moose;
my $file=$ARGV[0];
my @lines=read_file($ARGV[0]);
my $class;
$class->{file}=$file;
my $in_func=0;
my $in_class=0;
my $in_task=1;
my $func_type;
my $func;
my $line_num=0;
foreach my $line (@lines)
{
    $line_num++;
    chomp $line;
    next if ($line=~m!^//!);  #skip comment
    next if ($line=~/^\s*$/); # skip blank line
    if ($line=~/^\s*class\s*(\w+)/)
    {
        $class->{name}=$1;
        say "found class:$1";
        next;
    }

    if ($line=~/^\s*(?:virtual\s)?(task|function)\s/)
    {
            $in_func=1;
            $func_type=$1;
        $func=get_func_name($line);
        my $obj={name=>$func,line_num=>$line_num};
        $class->{$func_type}->{$func}=$obj;
        next;
    }

    if ($line=~/^\s*end(task|function)\b/)
    {
        $in_func=0;
        next;
    }
    #look for variable
    if ($line=~/^\s*(\w+)\s+(\w+);/)
    {
        if ($in_func)
        {
            $class->{$func_type}->{$func}->{var}->{$2}=$1;
        }
        $class->{var}->{$2}=$1
    }
    


}
say Dumper($class);
sub get_func_name
{
    my $line=shift;
    $line=~s/\(.*//; # remove paren
    $line=~/(\w+)\s*$/;
    return $1;

}
