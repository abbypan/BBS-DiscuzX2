#ABSTRACT: DISCUZ X2 帖子处理

=pod

=encoding utf8

=head1 NAME

BBS::DiscuzX2

=over 

=back

=head1 DESCRIPTION 

Discuz X2 贴子处理器

=over 

=back

=head1 SYNOPSIS

   注意：数据库中的表名前缀固定为pre_

=over 

=back

=head1 FUNCTION

=head2 init_db_handler

    #初始化

    my $bbs = BBS::DiscuzX2->new(

        db_host => 'xxx.xxx.xxx.xxx',

        db_port => 3306, 

        db_user => 'xxx',

        db_passwd => 'xxx',

        db_name => 'xxx',

        default_passwd => 'yyy', 

    );
    
    $bbs->init_db_handler();
    
=over

=back

=head2 create_user

    #新建论坛用户

    #mail/user_ip可不填，如果passwd未指定，则采用default_passwd作为初始密码

    my $uid = $bbs->create_user({

        user => 'xxx',

        passwd => 'xxx',

        mail => 'xxx@xxx.xxx',

        user_ip => 'xxx.xxx.xxx.xxx', 

    });

=over

=back

=head2 load_thread

    #从后台向 版块10 载入一个贴子

    my $data = {

        fid => 10, 

        floors => [

            {   poster => 'abc', subject => 'test', dateline => '2013-03-05 11:20:00', 

                message => 'just a test', user_ip => '123.123.123.123', 

                is_html => 0, is_bbcode => 1, 
                
            }, 

            {   poster => 'def', dateline => '2013-03-05 11:21:00', 

                message => 'just a test reply', user_ip => '222.222.222.222', 

            }, 

            {   poster => 'ghi',  dateline => '2013-03-06 10:00:03', 

                message => 'just a test reply update', user_ip => '202.202.202.202', 
            }, 

        ], 

    };

    my $tid = $self->load_thread($data);

=over

=back

=over 

=back

=cut

use strict;
use warnings;
package BBS::DiscuzX2;
use Moo;
use BBS::DiscuzX2::DB;

our $VERSION =0.01;

has db_host => ( is => 'rw' );
has db_port => ( is => 'rw' );
has db_user => ( is => 'rw' );
has db_passwd => ( is => 'rw' );
has db_name => ( is => 'rw' );

sub init_db_handler {
    my ($self) = @_;
    $self->{db_port} ||= 3306;

    my $dsn      = "DBI:mysql:host=$self->{db_host};port=$self->{db_port};database=$self->{db_name}";
    $self->{db_handler} = BBS::DiscuzX2::DB->new(
        connect_info => [ $dsn, $self->{db_user}, $self->{db_passwd} ]
    );

    if($self->{db_charset}){
        $self->{db_handler}->do("SET character_set_client='$self->{db_charset}'");
        $self->{db_handler}->do("SET character_set_connection='$self->{db_charset}'");
        $self->{db_handler}->do("SET character_set_results='$self->{db_charset}'");
    }

    $self;
}

sub create_user {
    my ($self,$data) = @_;
    $self->{db_handler}->create_user($data);
}

sub load_thread {
    my ($self,$data) = @_;
    $self->{db_handler}->load_thread($data);
}

1;