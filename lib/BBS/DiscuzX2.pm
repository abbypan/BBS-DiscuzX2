#ABSTRACT: DISCUZ X2 帖子处理
package BBS::DiscuzX2;
use Moo;
use BBS::DiscuzX2::DB;
use WWW::Mechanize;

our $VERSION =0.01;

sub init_browser {
    my ($self, %opt) = @_;

    $self->{browser} = WWW::Mechanize->new(autocheck=>0);                                                        
    while(my ($k, $v) = each %opt){
        $self->{browser}->add_header($k => $v);
    }

    $self;
}

sub login {
    my ($self, %opt) = @_;

    $self->{browser}->add_header('Referer' => $opt{site});
    my $url = $opt{site}.'member.php?mod=logging&action=login&loginsubmit=yes&infloat=yes&lssubmit=yes&inajax=1';
    my $data = [
        username=>$opt{user},
        password=>$opt{passwd},
        fastloginfield=>'username',
        quickforward=>'yes',
        handlekey=>'ls', 
    ];
    my $res = $self->{browser}->post($url, $data);
    return unless($res->is_success);
    $self->{site}  = $opt{site};

    $res = $self->{browser}->get($opt{site}.'forum.php');
    return unless($res->is_success);

    ($self->{formhash}) = $res->decoded_content =~ m/formhash=(\w+)">/s;
    return 1;
}

sub post_thread {
    my ($self, $data) = @_;
    my $url = "$self->{site}forum.php?mod=post&action=newthread&fid=$data->{fid}&extra=&topicsubmit=yes";
    my $res = $self->{browser}->post($url,
        [
            'formhash' => $self->{formhash},
            'message' => $data->{message},
            'subject' => $data->{subject},
            'usesig' => $data->{use_sig} // 1,
            'allownoticeauthor' => $data->{notice_author} // 1,
            'wysiwyg' => '1',
            'newalbum' => '',
            'posttime' => '',
            'save' => '',
            'uploadalbum' => '',
        ],	
    );

    return unless($res->is_success);

    my ($tid, $pid) = $res->as_string =~ m[action=edit&amp;fid=\d+&amp;tid=(\d+)&amp;pid=(\d+)&amp;]s;
    return {
        tid => $tid,
        pid => $pid, 
        response => $res,
    };	
}

#sub append_thread {
#	my ($self, $data) = @_;
#	my $url = "$self->{site}forum.php?mod=misc&action=postappend&tid=$data->{tid}&pid=$data->{pid}&extra=&postappendsubmit=yes&infloat=yes";
#	my $res = $self->{browser}->post($url,
#		[
#			'formhash' => $self->{formhash},
#			'postappendmessage' => $data->{message}, 
#			'handlekey' => 'postappend',
#		],
#	);
#
#	return unless($res->is_success);
#	return $res;
#}

sub delete_thread {
    my ($self, $data) = @_;
    my $url = "$self->{site}forum.php?mod=post&action=edit&extra=&editsubmit=yes";
    my $referer = "$self->{site}forum.php?mod=post&action=edit&fid=$data->{fid}&tid=$data->{tid}&pid=$data->{pid}&page=1";
    $self->{browser}->add_header('Referer' => $referer);
    my $res = $self->{browser}->post($url,
        [
            fid	=> $data->{fid}, 
            tid	=> $data->{tid}, 
            pid	=> $data->{pid}, 
            formhash	=> $self->{formhash},
            allownoticeauthor	=> $data->{notice_author} // 1, 
            delattachop	=> $data->{del_attach} || 0, 
            delete	=> 1,
        ],
    );

    return unless($res->is_success);
    return 1;
}

sub init_db_handler {
    my ($self, %db_opt) = @_;
    $db_opt{db_port} ||= 3306;

    my $dsn      = "DBI:mysql:host=$db_opt{db_host};port=$db_opt{db_port};database=$db_opt{db_name}";
    $self->{dbh} = BBS::DiscuzX2::DB->new(
        connect_info => [ $dsn, $db_opt{db_user}, $db_opt{db_passwd} ]
    );

    if($db_opt{db_charset}){
        $self->{dbh}->do("SET character_set_client='$db_opt{db_charset}'");
        $self->{dbh}->do("SET character_set_connection='$db_opt{db_charset}'");
        $self->{dbh}->do("SET character_set_results='$db_opt{db_charset}'");
    }

    for my $k (qw/default_passwd default_group_id/){
        next unless(exists $db_opt{$k});
        $self->{dbh}{$k} = $db_opt{$k};
    }

    $self->{dbh};
}

sub create_user {
    my ($self,$data) = @_;
    $self->{dbh}->create_user($data);
}

sub load_thread {
    my ($self,$data) = @_;
    $self->{dbh}->load_thread($data);
}

1;
