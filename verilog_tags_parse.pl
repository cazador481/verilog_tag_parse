#!/usr/intel/pkgs/perl/5.14.1/bin/perl
use warnings;
use strict;
use UsrIntel::R1;
use lib
"/nfs/site/disks/ltdn_lrb_disk1100/knh/work/valnic02/elash1/local_perl_install/5.14.1/lib/perl5";
use local::lib
"/nfs/site/disks/ltdn_lrb_disk1100/knh/work/valnic02/elash1/local_perl_install/5.14.1";
use feature qw(say);
use Data::Dumper;
use File::Slurp;
use Moo;

package variable;
use Moo;
# use MooX::HandlesVia;
has name => ( is=> 'rw' );
has class => ( is => 'rw' );

sub dump {
    my $self = shift;
    return "var: $self->name, type:$self->class";
}
1;

package function;
use Moo;
use MooX::HandlesVia;
has name => ( is => 'rw', required => 1 );
has var => (
    is          => 'rw',
    handles_via => 'Hash',
    default =>sub{{}},
    handles     => {
        # get_val  => 'get_var',
        add_var  => 'set',
        # all_keys => 'keys_var',
        # exists   => 'has_Var',
    },
);
has 'type'     => ( is => 'rw' );
has 'line_num' => ( is => 'rw' );
1;

package class;
use Moo;
use MooX::HandlesVia;
has name => ( is => 'rw', default => "" );
has file => ( is => 'rw', default => "" );
has inher=> ( is => 'rw', default => "" );



has function => ( is          => 'rw',
    default     => sub { {} },
    handles_via => 'Hash',
    handles     => {
        get_function  => 'get',
        add_function =>'set',
        'keys_function'=>'keys',
        'has_function'=>'exists'
    },

);
has var => (
    is          => 'rw',
    default=>sub{{}},
    handles_via => 'Hash',
    handles     => {
        # get_val  => 'get_var',
         'add_var', =>'set',
        # all_keys => 'keys_var',
        # exists   => 'has_Var',
    },
);

sub match_func
{
    my $self=shift;
    my $match=shift;
    my $list_of_functions;
    foreach my $func ( ($self->keys_function(),$self->keys_task()))
    {
        if (subst($func,0,length($match)) eq $match)
        {
            push(@$list_of_functions,$func);
        }
    }
}
1;

package main;

say "hi world";

my $tags={};
parse_file($ARGV[0]);

sub list_matching_func
{
    my ($tags,$class,$file,$match)=@_;
    #file used to find what package class is in
    #for now we are adding global to namespace
    $class="global::$class";
    return $tags->{$class}->match_func();
}

sub parse_file
{
    my $file=shift;
    my @lines    = read_file( $file );
    my $file=$ARGV[0];
    my $class    = class->new( file => $file );
    my $in_func  = 0;
    my $in_class = 0;
    my $in_task  = 1;
    my $func_type;
    my $func;
    my $line_num = 0;

    foreach my $line (@lines) {
        $line_num++;
        chomp $line;
        next if ( $line =~ m!^//! );     #skip comment
        next if ( $line =~ /^\s*$/ );    # skip blank line
        if ( $line =~ /^\s*class\s*(\w+)/ ) {

            # $class->name($1);
            $class->new(file=>$file);
            $tags->{global::$1}=$class; # for now put all classes in global namespace
            say "found class:", $class->name($1);
            if( $line=~/extends (\w+)/)
            {
                $class->inher($1);
            }

            next;
        }

        if ( $line =~ /^\s*(?:virtual\s)?(task|function)\s/ ) {
            $in_func   = 1;
            $func_type = $1;
            $func      = get_func_name($line);
            my $obj = function->new(
                name     => $func,
                line_num => $line_num,
                type     => $func_type
            );
            $class->add_function($func,$obj);
            next;
        }

        if ( $line =~ /^\s*end(task|function)\b/ ) {
            $in_func = 0;
            next;
        }

        #look for variable
        if ( $line =~ /^\s*(\w+)\s+(\w+);/ ) {
            my $var = variable->new( class => $1, name => $2 );
            if ($in_func) {
                say $func_type, $func;
                $class->{$func_type}->{$func}->add_var($var->name,$var);
            }
            else {
                $class->add_var( $var->name,$var );
            }
        }
    }
    return $class;
}

say Dumper($class);

sub get_func_name {
    my $line = shift;
    $line =~ s/\(.*//;      # remove paren
    $line =~ /(\w+)\s*$/;
    return $1;

}
