#  -*- perl -*-

use 5.008;
use Fcntl 		qw':flock :seek :mode';
use IO::Handle;
use Encode;
use Digest::MD5 	qw'md5_hex';
use File::Basename;
use Sys::Hostname;

# set and untaint ENV if not in CLI (fexsrv provides clean ENV)
unless (-t) {
  foreach my $v (keys %ENV) {
    ($ENV{$v}) = ($ENV{$v} =~ /(.*)/s);
  }
  $ENV{PATH}     = '/usr/local/bin:/bin:/usr/bin';
  $ENV{IFS}      = " \t\n";
  $ENV{BASH_ENV} = '';
}

unless ($FEXLIB = $ENV{FEXLIB} and -d $FEXLIB) {
  die "$0: found no FEXLIB - fexsrv needs full path\n"
}

$FEXLIB =~ s:/+:/:g;
$FEXLIB =~ s:/$::;

# $FEXHOME is top-level directory of F*EX installation
# $ENV{HOME} is login-directory of user fex
# in default-installation both are equal, but they may differ
$FEXHOME = $ENV{FEXHOME} or $ENV{FEXHOME} = $FEXHOME = dirname($FEXLIB);

umask 077;

# defaults
$hostname = gethostname();
$tmpdir = $ENV{TMPDIR} || '/var/tmp';
$spooldir = $ENV{HOME}.'/spool';
$docdir = $FEXHOME.'/htdocs';
$logdir = $spooldir;
$autodelete = 'YES';
$overwrite = 'YES';
$limited_download = 'YES';	# multiple downloads only from same client
$keep = 5;	    		# days
$recipient_quota = 0; 		# MB
$sender_quota = 0;    		# MB
$timeout = 30;	 		# seconds
$bs = 2**16;		 	# I/O blocksize
$use_cookies = 1;
$sendmail = '/usr/lib/sendmail';
$sendmail = '/usr/sbin/sendmail' unless -x $sendmail;
$mailmode = 'auto';
$bcc = 'fex';
$default_locale = '';

# allowed download managers (HTTP User-Agent)
$adlm = '^(Axel|fex)';

# allowed multi download recipients
$amdl = '^(anonymous|_fexmail_)';

# local config
require "$FEXLIB/fex.ph" or die "$0: cannot load $FEXLIB/fex.ph - $!";

push @doc_dirs,$docdir;

# check for name based virtual host
vhost($ENV{'HTTP_HOST'});

$nomail = ($mailmode =~ /^MANUAL|nomail$/i);

if (not $nomail and not -x $sendmail) {
  http_die("found no sendmail\n");
}
http_die("cannot determine the server hostname") unless $hostname;

$ENV{PROTO} = 'http' unless $ENV{PROTO};
$keep_default ||= $keep || 5;
$fra = $ENV{REMOTE_ADDR} || '';
$sid = $ENV{SID} || '';
  
mkdirp($dkeydir = "$spooldir/.dkeys"); # download keys
mkdirp($ukeydir = "$spooldir/.ukeys"); # upload keys
mkdirp($akeydir = "$spooldir/.akeys"); # authentification keys
mkdirp($skeydir = "$spooldir/.skeys"); # subuser authentification keys
mkdirp($gkeydir = "$spooldir/.gkeys"); # group authentification keys
mkdirp($xkeydir = "$spooldir/.xkeys"); # extra download keys
mkdirp($lockdir = "$spooldir/.locks"); # download lock files

if (my $ra = $ENV{REMOTE_ADDR} and $max_fail) {
  mkdirp("$spooldir/.fail");
  $faillog = "$spooldir/.fail/$ra";
}

unless ($admin) {
  $admin = $ENV{SERVER_ADMIN} ? $ENV{SERVER_ADMIN} : 'fex@'.$hostname;
}

# $ENV{SERVER_ADMIN} may be set empty in fex.ph!
$ENV{SERVER_ADMIN} = $admin unless defined $ENV{SERVER_ADMIN};

$mdomain ||= '';

if ($use_cookies) {
  if (my $cookie = $ENV{HTTP_COOKIE}) {
    if    ($cookie =~ /\bakey=(\w+)/) { $akey = $1 }
    # elsif ($cookie =~ /\bskey=(\w+)/) { $skey = $1 }
  }
}

if (@locales) {
  if ($default_locale and not grep /^$default_locale$/,@locales) {
    push @locales,$default_locale;
  }
  if (@locales == 1) {
    $default_locale = $locales[0];
  }
}

unless ($durl) {
  my $host = '';
  my $port = 0;
  
  ($host,$port) = split(':',$ENV{HTTP_HOST}||'');
  $host = $hostname;
  
  unless ($port) {
    $port = 80;
    if (open my $xinetd,'<',"/etc/xinetd.d/fex") {
      while (<$xinetd>) {
        if (/^\s*port\s*=\s*(\d+)/) {
          $port = $1;
          last;
        }
      }
      close $xinetd;
    }
  }
  
  # use same protocal as uploader for download
  if ($ENV{PROTO} eq 'https' and $port == 443 or $port == 80) {
    $durl = "$ENV{PROTO}://$host/fop";
  } else {
    $durl = "$ENV{PROTO}://$host:$port/fop";
  }
}

@durl = ($durl) unless @durl;

sub debug {
  print header(),"<pre>\n";
  print "file = $file\n";
  foreach $v (keys %ENV) {
    print $v,' = "',$ENV{$v},"\"\n";
  }
  print "</pre><p>\n";
}


sub nvt_print {
  foreach (@_) { syswrite STDOUT,"$_\r\n" }
}


sub html_quote {
  local $_ = shift;
  
  s/&/&amp;/g;
  s/</&lt;/g;
  s/\"/&quot;/g;
  
  return $_;
}



sub http_header {
  
  my $status = shift;
  my $msg = $status;

  return if $HTTP_HEADER;
  $HTTP_HEADER = $status;
  
  $msg =~ s/^\d+\s*//;

  nvt_print("HTTP/1.1 $status");
  nvt_print("X-Message: $msg");
  # nvt_print("X-SID: $ENV{SID}") if $ENV{SID};
  nvt_print("Server: fexsrv");
  nvt_print("Expires: 0");
  nvt_print("Cache-Control: no-cache");
  # http://en.wikipedia.org/wiki/Clickjacking
  nvt_print("X-Frame-Options: SAMEORIGIN");
  if ($force_https) {
    # https://www.owasp.org/index.php/HTTP_Strict_Transport_Security
    nvt_print("Strict-Transport-Security: max-age=2851200");
  }
  if ($use_cookies) {
    if ($akey) {
      nvt_print("Set-Cookie: akey=$akey; Max-Age=9999; Discard");
    }
    # if ($skey) {
    #   nvt_print("Set-Cookie: skey=$skey; Max-Age=9999; Discard");
    # }
    if ($locale) {
      nvt_print("Set-Cookie: locale=$locale");
    }
  }
  unless (grep /^Content-Type:/i,@_) {
    # nvt_print("Content-Type: text/html; charset=ISO-8859-1");
    nvt_print("Content-Type: text/html; charset=UTF-8");
  }

  nvt_print(@_,'');
}


sub html_header {
  my $title = shift;
  my $header = 'header.html';
  my $head;

  # http://www.w3.org/International/O-charset
  $head = qqq(qq(
    '<html>'
    '<head>'
    '  <meta http-equiv="expires" content="0">'
    '  <meta http-equiv="Content-Type" content="text/html;charset=utf-8">'
    '  <title>$title</title>'
    '</head>'
  ));
  # '<!-- <style type="text/css">\@import "/fex.css";</style> -->'
  
  if ($0 =~ /fexdev/) { $head .= "<body bgcolor=\"pink\">\n" } 
  else                { $head .= "<body>\n" }
  
  $title =~ s:F\*EX:<a href="/index.html">F*EX</a>:;

  if (open $header,'<',"$docdir/$header") {
    $head .= $_ while <$header>;
    close $header;
  }
  
  if (@H1_extra) {
    $head .= sprintf(
      '<h1><a href="%s"><img align=center src="%s" border=0></a>%s</h1>',
      $H1_extra[0],$H1_extra[1]||'',$title
    );
  } else {
    $head .= "<h1>$title</h1>";
  }
  $head .= "\n";
  
  return $head;
}


sub html_error {
  my $error = shift;
  my $msg = "@_";
  my @msg = @_;
  my $isodate = isodate(time);
  
  $msg =~ s/[\s\n]+/ /g;
  $msg =~ s/<.+?>//g; # remove HTML
  map { s/<script.*?>//gi } @msg;
  
  errorlog($msg);
  
  # cannot send standard HTTP Status-Code 400, because stupid 
  # Internet Explorer then refuses to display HTML body!
  http_header("666 Bad Request - $msg");
  print html_header($error);
  print 'ERROR: ',join("<p>\n",@msg),"\n";
  pq(qq(
    '<p><hr><p>'
    '<address>
    '  $ENV{HTTP_HOST}'
    '  $isodate'
    '  <a href="mailto:$ENV{SERVER_ADMIN}">$ENV{SERVER_ADMIN}</a>'
    '</address>'
    '</body></html>'
  ));
  exit;
}


sub http_die {
  
  # not in CGI mode
  die "$0: @_\n" unless $ENV{GATEWAY_INTERFACE};
  
  debuglog(@_);
  
  # create special error file on upload
  if ($uid) {
    my $ukey = "$spooldir/.ukeys/$uid";
    $ukey .= "/error" if -d $ukey;
    unlink $ukey;
    if (open $ukey,'>',$ukey) {
      print {$ukey} join("\n",@_),"\n";
      close $ukey;
    }
  }
  
  html_error($error||'',@_);
}


sub check_maint {
  if (my $status = readlink '@MAINTENANCE') {
    my $isodate = isodate(time);
    http_header('666 MAINTENANCE');
    print html_header($head);
    pq(qq(
      "<center>"
      "<h1>Server is in maintenance mode</h1>"
      "<h3>($status)</h3>"
      "</center>"
      "<p><hr><p>"
      "<address>$ENV{HTTP_HOST} $isodate</address>"
      "</body></html>"
    ));
    exit;
  }
}


sub check_status {
  my $user = shift;
  
  $user = lc $user;
  $user .= '@'.$mdomain if $mdomain and $user !~ /@/;

  if (-e "$user/\@DISABLED") {
    my $isodate = isodate(time);
    http_header('666 DISABLED');
    print html_header($head);
    pq(qq(
      "<h3>$user is disabled</h3>"
      "Contact $ENV{SERVER_ADMIN} for details"
      "<p><hr><p>"
      "<address>$ENV{HTTP_HOST} $isodate</address>"
      "</body></html>"
    ));
    exit;
  }
}


sub isodate {
  my @d = localtime shift;
  return sprintf('%d-%02d-%02d %02d:%02d:%02d',
                 $d[5]+1900,$d[4]+1,$d[3],$d[2],$d[1],$d[0]);
}


sub encode_Q {
  my $s = shift;
  $s =~ s{([\=\x00-\x20\x7F-\xA0])}{sprintf("=%02X",ord($1))}eog;
  return $s;
}  


# from MIME::Base64::Perl
sub decode_b64 {
  local $_ = shift;
  my $uu = '';
  my ($i,$l);

  tr|A-Za-z0-9+=/||cd;
  s/=+$//;
  tr|A-Za-z0-9+/| -_|;
  return '' unless length;
  $l = (length)-60;
  for ($i = 0; $i <= $l; $i += 60) {
    $uu .= "M" . substr($_,$i,60);
  }
  $_ = substr($_,$i);
  $uu .= chr(32+(length)*3/4) . $_ if $_;
  return unpack ("u",$uu);
}


# short base64 encoding
sub b64 {
  local $_ = '';
  my $x = 0;
  
  pos($_[0]) = 0;
  $_ = join '',map(pack('u',$_)=~ /^.(\S*)/, ($_[0]=~/(.{1,45})/gs));
  tr|` -_|AA-Za-z0-9+/|;
  $x = (3 - length($_[0]) % 3) % 3;
  s/.{$x}$//;
  
  return $_;
}


# simulate a "rm -rf", but never removes '..'
# return number of removed files
sub rmrf {
  my @files = @_;
  my $dels = 0;
  my ($file,$dir);
  local *D;
  local $_;
  
  foreach (@files) {
    next if /(^|\/)\.\.$/;
    /(.*)/; $file = $1;
    if (-d $file and not -l $file) {
      $dir = $file;
      opendir D,$dir or next;
      while ($file = readdir D) {
        next if $file eq '.' or $file eq '..';
        $dels += rmrf("$dir/$file");
      }
      closedir D;
      rmdir $dir and $dels++;
    } else {
      unlink $file and $dels++;
    }
  }
  return $dels;
}


sub gethostname {
  my $hostname = hostname;
  my $domain;
  local $_;

  unless ($hostname) {
    $_ = `hostname 2>/dev/null`;
    $hostname = /(.+)/ ? $1 : '';
  }
  if ($hostname !~ /\./ and open my $rc,'/etc/resolv.conf') {
    while (<$rc>) {
      if (/^\s*domain\s+([\w.-]+)/) {
        $domain = $1;
        last;
      }
      if (/^\s*search\s+([\w.-]+)/) {
        $domain = $1;
      }
    }
    close $rc;
    $hostname .= ".$domain" if $domain;
  }
  if ($hostname !~ /\./ and $admin and $admin =~ /\@([\w.-]+)/) {
    $hostname .= '.'.$1;
  }
  
  return $hostname;
}


# strip off path names (Windows or UNIX)
sub strip_path {
  local $_ = shift;
  
  s/.*\\// if /^([A-Z]:)?\\/;
  s:.*/::;
  
  return $_;
}


# substitute all critcal chars
sub normalize {
  local $_ = shift;
  
  return '' unless defined $_;
  
  # we need perl native utf8 (see perldoc utf8)
  $_ = decode_utf8($_) unless utf8::is_utf8($_);

  s/[\r\n\x09]+/ /g;
  s/[\x00-\x1F\x80-\x9F]/_/g;
  s/^\s+//;
  s/\s+$//;
  
  return encode_utf8($_);
}


# substitute all critcal chars with underscore
sub normalize_filename {
  local $_ = shift;

  return $_ unless $_;

  # we need native utf8
  $_ = decode_utf8($_) unless utf8::is_utf8($_);
 
  $_ = strip_path($_);
  
  # substitute all critcal chars with underscore
  s/[^a-zA-Z0-9_=.+-]/_/g;
  s/^\./_/;
  
  return encode_utf8($_);
}


sub untaint {
  local $_ = shift;
  /(.*)/s;
  return $1;
}


sub checkchars {
  my $input = shift;
  local $_ = shift;
  if (/^([<>|+.])/) {
    http_die(sprintf("\"&#%s;\" is not allowed at beginning of %s",
                     ord($1),$input));
  }
  if (/([\/\"\'\\<>;])/) {
    http_die(sprintf("\"&#%s;\" is not allowed in %s",ord($1),$input));
  }
  if (/([<>|])$/) {
    http_die(sprintf("\"&#%s;\" is not allowed at end of %s",ord($1),$input));
  }
}


sub checkaddress {
  my $a = shift;
  my $re;
  local $_;
  local ($domain,$dns);
  
  $a =~ s/:\w+=.*//; # remove options from address
  
  return $a if $a eq 'anonymous';
  
  $re = '^[.@]|@.*@|local(host|domain)$|["\'\`\|\s()<>/;,]';
  if ($a =~ /$re/i) {
    debuglog("$a has illegal syntax ($re)");
    return '';
  }
  $re = '^[!^=~#_:.+*{}\w\-\[\]]+\@(\w[.\w\-]*\.[a-z]+)$';
  if ($a =~ /$re/i) {
    $domain = $dns = $1;
    { 
      local $SIG{__DIE__} = sub { die "\n" };
      eval q{
        use Net::DNS;
        $dns = Net::DNS::Resolver->new->query($domain)||mx($domain);
        unless ($dns or mx('uni-stuttgart.de')) {
          http_die("Internal error: bad resolver");
        }
      } 
    };
    if ($dns) {
      return untaint($a);
    } else {
      debuglog("no A or MX DNS record found for $domain");
      return '';
    }
  } else {
    debuglog("$a does not match e-mail regexp ($re)");
    return '';
  }
}


# check forbidden addresses
sub checkforbidden {
  my $a = shift;
  if (@forbidden_recipients) {
    foreach my $fr (@forbidden_recipients) {
      $fr = quotemeta $fr;
      $fr =~ s/\\\*/.*/g; # allow wildcard *
      $a .= '@'.$mdomain if $mdomain and $a !~ /@/;
      # skip public recipients
      if (@public_recipients) {
        foreach my $pr (@public_recipients) {
          if ($a eq lc $pr) {
            $fr = '';
            last;
          }
        }
      }
      return '' if $a =~ /^$fr$/i;
    }
  }
  return $a;
}


sub randstring {
  my $n = shift;
  my @rc = ('A'..'Z','a'..'z',0..9 ); 
  my $rn = @rc; 
  my $rs;
  
  for (1..$n) { $rs .= $rc[int(rand($rn))] };
  return $rs;
}


# emulate mkdir -p
sub mkdirp {
  my $dir = shift;
  my $pdir;
  
  return if -d $dir;
  $dir =~ s:/+$::;
  http_die("cannot mkdir /\n") unless $dir;
  $pdir = $dir;
  if ($pdir =~ s:/[^/]+$::) {
    mkdirp($pdir) unless -d $pdir;
  }
  unless (-d $dir) {
    mkdir $dir,0770 or http_die("mkdir $dir - $!\n");
  }
}


# hash with SID
sub sidhash {
  my ($rid,$id) = @_;

  if ($rid and $ENV{SID} and $id =~ /^MD5H:/) {
    $rid = 'MD5H:'.md5_hex($rid.$ENV{SID});
  }
  return $rid;
}


# test if ip is in iplist (ipv4/ipv6)
# iplist is an array with ips and ip-ranges
sub ipin {
  my ($ip,@list) = @_;
  my ($i,$ia,$ib);

  $ipe = lc(ipe($ip));
  map { lc } @list;
  
  foreach $i (@list) {
    if ($ip =~ /\./ and $i =~ /\./ or $ip =~ /:/ and $i =~ /:/) {
      if ($i =~ /(.+)-(.+)/) {
        ($ia,$ib) = ($1,$2);
        $ia = ipe($ia);
        $ib = ipe($ib);
        return $ip if $ipe ge $ia and $ipe le $ib;
      } else {
        return $ip if $ipe eq ipe($i);
      }
    }
  }
  return '';
}

# ip expand (ipv4/ipv6)
sub ipe {
  local $_ = shift;

  if (/^\d+\.\d+\.\d+\.\d+$/) {
    s/\b(\d\d?)\b/sprintf "%03d",$1/ge;
    return $_;
  } elsif (/^[:\w]+:\w+$/) {
    s/\b(\w+)\b/sprintf "%04s",$1/ge;
    s/^:/0000:/;
    while (s/::/::0000:/) { last if length > 39 }
    s/::/:/;
    return $_;
  } else {
    return '';
  }
  
}


# doted ip to ip integer
sub ipn {
  local $_ = shift;

  if (/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
    return $1*256**3+$2*256**2+$3*256+$4;
  } else {
    return undef;
  }
}


sub filename {
  my $file = shift;
  my $filename;

  if (open $file,'<',"$file/filename") {
    $filename = <$file>||'';
    close $file;
    chomp $filename;
  }
  
  return $filename ? $filename : '???';
}


sub urlencode {
  local $_ = shift;
  s/(^[.~]|[^\w.,=:~^+-])/sprintf "%%%X",ord($1)/ge;
  return $_;
}


# file and document log
sub fdlog {
  my ($log,$file,$s,$size) = @_;
  my $ra;
  
  if (open $log,'>>',$log) {
    flock $log,LOCK_EX;
    seek $log,0,SEEK_END;
    $ra = $ENV{REMOTE_ADDR}||'-';
    $ra .= '/'.$ENV{HTTP_X_FORWARDED_FOR} if $ENV{HTTP_X_FORWARDED_FOR};
    $ra =~ s/\s//g;
    $file =~ s:/data$::;
    printf {$log} 
           "%s [%s_%s] %s %s %s/%s\n",
           isodate(time),$$,$ENV{REQUESTCOUNT},$ra,encode_Q($file),$s,$size;
    close $log;
  }
}


# extra debug log
sub debuglog {
  my $prg = $0;
  local $_;
  
  return unless $debug and @_;
  unless ($debuglog and fileno $debuglog) {
    mkdir "$logdir/.debug",0770 unless -d "$logdir/.debug";
    $prg =~ s:.*/::;
    $prg = untaint($prg);
    $debuglog = sprintf("%s/.debug/%s_%s_%s.%s",
                        $logdir,time,$$,$ENV{REQUESTCOUNT}||0,$prg);
    $debuglog =~ s/\s/_/g;
    open $debuglog,'>>',$debuglog or return;
    autoflush $debuglog 1;
    # printf {$debuglog} "\n### %s ###\n",isodate(time);
  }
  while ($_ = shift @_) {
    s/\n*$/\n/;
    s/<.+?>//g; # remove HTML
    print {$debuglog} $_;
    print "DEBUG: $_" if -t;
  }
}


# extra debug log
sub errorlog {
  my $prg = $0;
  my $log = "$logdir/error.log";
  my $msg = "@_";

  $prg =~ s:.*/::;
  $msg =~ s/[\r\n]+$//;
  $msg =~ s/[\r\n]+/ /;
  $msg =~ s/\s*<p>.*//;

  if (open $log,'>>',$log) {
    flock $log,LOCK_EX;
    seek $log,0,SEEK_END;
    $ra = $ENV{REMOTE_ADDR}||'-';
    $ra .= '/'.$ENV{HTTP_X_FORWARDED_FOR} if $ENV{HTTP_X_FORWARDED_FOR};
    $ra =~ s/\s//g;
    printf {$log} "%s %s %s %s\n",isodate(time),$prg,$ra,$msg;
    close $log;
  }
}


# failed authentification log
sub faillog {
  my $request = shift;
  my $n = 1;
  my $ra = $ENV{REMOTE_ADDR};

  if ($faillog and $max_fail_handler and open $ra,"+>>$faillog") {
    flock($ra,LOCK_EX);
    seek $ra,0,SEEK_SET;
    $n++ while <$ra>;
    printf {$ra} "%s %s\n",isodate(time),$request;
    close $ra;
    &$max_fail_handler($ra) if $n > $max_fail;
  }
}

# remove all white space
sub despace {
  local $_ = shift;
  s/\s//g;
  return $_;
}


# superquoting
sub qqq {
  local $_ = shift;
  my ($s,$i,@s);
  my $q = "[\'\"]"; # quote delimiter chars " and '

  # remove first newline and look for default indention
  s/^(\«(\d+)?)?\n//;
  $i = ' ' x ($2||0);

  # remove trailing spaces at end
  s/[ \t]*\»?$//;

  @s = split "\n";

  # first line have a quote delimiter char?
  if (/^\s+$q/) {
    # remove heading spaces and delimiter chars
    foreach (@s) {
      s/^\s*$q//;
      s/$q\s*$//;
    }
  } else {
    # find the line with the fewest heading spaces (and count them)
    # (beware of tabs!)
    $s = length;
    foreach (@s) {
      if (/^( *)\S/ and length($1) < $s) { $s = length($1) };
    }
    # adjust indention
    foreach (@s) {
      s/^ {$s}/$i/;
    }
  }

  return join("\n",@s)."\n";
}


# print superquoted
sub pq {
  my $H = STDOUT;
  if (@_ > 1 and defined fileno $_[0]) { $H = shift }
  print {$H} qqq(@_);
}


# check sender quota
sub check_sender_quota {
  my $sender = shift;
  my $squota = $sender_quota||0;
  my $du = 0;
  my ($file,@file,$size,%size,$qf,$qs);
  local $_;
  
  if (open $qf,'<',"$sender/\@QUOTA") {
    while (<$qf>) {
      s/#.*//;
      $squota = $1 if /sender.*?(\d+)/i;
    }
    close $qf;
  }
  $qs = "*/$sender/*";
  if (glob $qs and open $qs,untaint("du $qs 2>/dev/null|")) {
    while (<$qs>) {
      $du += $1 if /^(\d+)/;
    }
    close $qs;
  }
  
  return($squota,int($du/1024));
}


# check recipient quota
sub check_recipient_quota {
  my $recipient = shift;
  my $rquota = $recipient_quota||0;
  my $du = 0;
  local $_;
  
  if (open my $qf,'<',"$recipient/\@QUOTA") {
    while (<$qf>) {
      s/#.*//;
      $rquota = $1 if /recipient.*?(\d+)/i;
    }
    close $qf;
  }
  foreach my $data (glob("$recipient/*/*/data $recipient/*/*/upload")) {
    unless (-l $data) {
      $du += -s $data||0;
    }
  }
  
  return($rquota,int($du/1024/1024));
}


sub getline {
  my $file = shift;
  local $_;
  chomp($_ = <$file>||'');
  return $_;
}


# (shell) wildcard matching
sub wcmatch {
  local $_ = shift;
  my $p = quotemeta shift;
  
  $p =~ s/\\\*/.*/g;
  $p =~ s/\\\?/./g;
  $p =~ s/\\\[/[/g;
  $p =~ s/\\\]/]/g;

  return /$p/;
}

  
sub logout {
  my $logout;
  if    ($skey) { $logout = "/fup?logout=skey:$skey" }
  elsif ($gkey) { $logout = "/fup?logout=gkey:$gkey" }
  elsif ($akey) { $logout = "/fup?logout=akey:$akey" }
  else          { $logout = "/fup?logout" }
  return qqq(qq(
    '<p>'
    '<form name="logout" action="$logout">'
    '  <input type="submit" name="logout" value="logout">'
    '</form>'
    '<p>'
  ));
}


# print data dump of global or local variables in HTML
# input musst be a string, eg: '%ENV'
sub DD {
  my $v = shift; 
  local $_;

  $n =~ s/.//;
  $_ = eval(qq(use Data::Dumper;Data::Dumper->Dump([\\$v])));
  s/\$VAR1/$v/;
  s/&/&amp;/g;
  s/</&lt;/g;
  print "<pre>\n$_\n</pre>\n";
}
  
# make symlink
sub mksymlink {
  my ($file,$link) = @_;
  unlink $file;
  return symlink untaint($link),$file;
}


# copy file (and modify) or symlink
# returns chomped file contents or link name
# preserves permissions and time stamps
sub copy {
  my ($from,$to,$mod) = @_;
  my $link;
  local $/;
  local $_;
  
  $to .= '/'.basename($from) if -d $to;

  if (defined($link = readlink $from)) {
    mksymlink($to,$link);
    return $link;
  } else {
    open $from,'<',$from or return;
    open $to,'>',$to or return;
    $_ = <$from>;
    close $from;
    eval $mod if $mod;
    print {$to} $_;
    close $to or http_die("internal error: $to - $!");
    if (my @s = stat($from)) { 
      chmod $s[2],$to;
      utime @s[8,9],$to;
    }
    chomp;
    return $_;
  }
}


sub slurp {
  my $file = shift;
  local $_;
  local $/;
  
  if (open $file,$file) {
    $_ = <$file>;
    close $file;
  }

  return $_;
}


# name based virtual host?
sub vhost {
  my $hh = shift; # HTTP_HOST
  my $vhost;
  my $locale = $ENV{LOCALE};

  # memorized vhost? (default is in fex.ph)
  %vhost = split(':',$ENV{VHOST}) if $ENV{VHOST};
    
  if (%vhost and $hh and $hh =~ s/^([\w\.-]+).*/$1/) {
    if ($vhost = $vhost{$hh} and -f "$vhost/lib/fex.ph") {
      $ENV{VHOST} = "$hh:$vhost"; # memorize vhost for next run
      $ENV{FEXLIB} = $FEXLIB = "$vhost/lib";
      $logdir = $spooldir    = "$vhost/spool";
      $docdir                = "$vhost/htdocs";
      if ($locale and -e "$vhost/locale/$locale/lib/fex.ph") {
        $ENV{FEXLIB} = $FEXLIB = "$vhost/locale/$locale/lib";
      }
      require "$FEXLIB/fex.ph" or die "$0: cannot load $FEXLIB/fex.ph - $!";
      $ENV{SERVER_NAME} = $hostname;
      return $vhost;
    }
  }
}


# extract locale functions into hash of subroutine references
# e.g. \&german ==> $notify{german}
sub locale_functions {
  my $locale = shift;
  local $/;
  local $_;
  
  if ($locale and open my $fexpp,"$FEXHOME/locale/$locale/lib/fex.pp") {
    $_ = <$fexpp>;
    s/.*\n(\#\#\# locale functions)/$1/s;
    # sub xx {} ==> xx{$locale} = sub {}
    s/\nsub (\w+)/\n\$$1\{$locale\} = sub/gs; 
    s/\n}\n/\n};\n/gs;
    eval $_;
    close $fexpp;
  }
}


### locale functions ###
# will be extracted by install process and saved in $FEXHOME/lib/lf.pl
# you cannot modify them here without re-installing!

sub notify {
  # my ($status,$dkey,$filename,$keep,$warn,$comment,$autodelete) = @_;
  my %P = @_;
  my ($to,$from,$file,$mimefilename,$receiver,$warn,$comment,$autodelete);
  my ($size,$bytes,$days,$header,$data,$replyto);
  my ($mfrom,$mto,$dfrom,$dto);
  my $index;
  my $fileid = 0;
  my $fua = $ENV{HTTP_USER_AGENT}||'';
  my $warning = '';
  my $download = '';

  return if $nomail;
  
  $warn = $P{warn}||2;
  $comment = $P{comment}||'';
  $autodelete = $P{autodelete}||$::autodelete;
  $index = $durl;
  $index =~ s/fop/index.html/;

  (undef,$to,$from,$file) = split('/',untaint(readlink("$dkeydir/$P{dkey}")));
  $filename = strip_path($P{filename});
  $mfrom = $from;
  $mto = $to;
  $mfrom .= '@'.$mdomain if $mdomain and $mfrom !~ /@/;
  $mto .=   '@'.$mdomain if $mdomain and $mto   !~ /@/;
  $to = '' if $to eq $from;
  $replyto = $P{replyto}||$mfrom;
  $header = "From: <$mfrom> ($mfrom via F*EX service $hostname)\n".
            "Reply-To: <$replyto>\n".
            "To: <$mto>\n";
  $data = "$dkeydir/$P{dkey}/data";
  $size = $bytes = -s $data;
  return unless $size;
  $warning = 
    "Please avoid download with Internet Explorer, ".
    "because it has too many bugs.\n".
    "We recommend Firefox or wget.";
  if ($filename =~ /\.(tar|zip|7z|arj|rar)$/) {
    $warning .= "\n\n".
      "$filename is a container file.\n".
      "You can unpack it for example with 7zip ".
      "(http://www.7-zip.org/download.html)";
  }
  if ($limited_download =~ /^y/i) {
    $warning .= "\n\n".
      'This download link only works for you, you cannot distribute it.';
  }
  if ($size < 2048) {
    $size = "$size Bytes";
  } elsif ($size/1024 < 2048) {
    $size = int($size/1024)." kB";
  } else {
    $size = int($size/1024/1024)." MB";
  }
  if ($autodelete eq 'YES') {
    $autodelete = "WARNING: After download (or view with a web browser!), "
                . "the file will be deleted!";
  } elsif ($autodelete eq 'DELAY') {
    $autodelete = "WARNING: When you download the file it will be deleted "
                . "soon afterwards!";
  } else {
    $autodelete = '';
  }
  $mimefilename = $filename;
  if ($mimefilename =~ s{([_\?\=\x00-\x1F\x7F-\xFF])}{sprintf("=%02X",ord($1))}eog) {
    $mimefilename =~ s/ /_/g;
    $mimefilename = '=?UTF-8?Q?'.$mimefilename.'?=';
  }
  
  unless ($fileid = readlink("$dkeydir/$P{dkey}/id")) {
    my @s = stat($data);
    $fileid =  @s ? $s[1].$s[9] : 0;
  }
  
  if ($P{status} eq 'new') {
    $days = $P{keep};
    $header .= "Subject: F*EX-upload: $mimefilename\n";
  } else {
    $days = $warn;
    $header .= "Subject: reminder F*EX-upload: $mimefilename\n";
  }
  $header .= "X-FEX-Client-Address: $fra\n" if $fra;
  $header .= "X-FEX-Client-Agent: $fua\n"   if $fua;
  foreach my $u (@durl) {
    my $durl = sprintf("%s/%s/%s",$u,$P{dkey},normalize_filename($filename));
    $header .= "X-FEX-URL: $durl\n";
    $download .= "$durl\n";
  }
  $header .= "X-FEX-Filesize: $bytes\n".
             "X-FEX-File-ID: $fileid\n".
             "X-Mailer: F*EX\n".
             "MIME-Version: 1.0\n".
             "Content-Type: text/plain; charset=UTF-8\n".
             "Content-Transfer-Encoding: 8bit\n";
  if ($comment =~ s/^\[(\@(.*?))\]\s*//) { 
    $receiver = "group $1";
    if ($_ = readlink "$from/\@GROUP/$2" and m:^../../(.+?)/:) {
      $receiver .= " (maintainer: $1)";
    }
  } else { 
    $receiver = 'you';
  }
  if ($days == 1) { $days .= " day" }
  else            { $days .= " days" }

  # explicite sender set in fex.ph?
  if ($sender_from) {
    map { s/^From: $mfrom/From: $sender_from/ } $header;
    open $sendmail,'|-',$sendmail,$mto,$bcc
      or http_die("cannot start sendmail - $!\n");
  } else {
    # for special remote domains do not use same domain in From, 
    # because remote MTA will probably reject this e-mail
    $dfrom = $1 if $mfrom =~ /@(.+)/;
    $dto   = $1 if $mto   =~ /@(.+)/;
    if ($dfrom and $dto and @remote_domains and 
        grep { 
          $dfrom =~ /(^|\.)$_$/ and $dto =~ /(^|\.)$_$/ 
        } @remote_domains) {
      map { s/^From: $mfrom/From: $admin/ } $header;
      open $sendmail,'|-',$sendmail,$mto,$bcc
        or http_die("cannot start sendmail - $!\n");
    } else {
      open $sendmail,'|-',$sendmail,'-f',$mfrom,$mto,$bcc
        or http_die("cannot start sendmail - $!\n");
    }
  }
  print {$sendmail} $header,"\n";
  if ($comment =~ s/^!(shortmail|\.)!\s*//i 
    or (readlink "$to/\@NOTIFICATION"||'') =~ /short/i
  ) {
    pq($sendmail,qq(
      '$comment'
      ''
      '$download'
      '$size'
    ));
  } else {
    $comment = "Comment: $comment\n" if $comment;
    pq($sendmail,qq(
      '$from has uploaded the file'
      '  "$filename"'
      '($size) for $receiver. Use'
      ''
      '$download'
      'to download this file within $days.'
      ''
      '$comment'
      '$autodelete'
      '$warning'
      ''
      'F*EX is not an archive, it is a transfer system for personal files.'
      'For more information see $index'
      ''
      'Questions? ==> F*EX admin: $admin'
    ));
  }
  close $sendmail 
    or $! and http_die("cannot send notification e-mail (sendmail error $!)\n");
}


sub reactivation {
  my ($expire,$user) = @_;
  my $fexsend = "$FEXHOME/bin/fexsend";

  return if $nomail;
  
  if (-x $fexsend) {
    $fexsend .= " -D -k 30 -C "
               ." 'Your F*EX account has been inactive for $expire days,"
               ." you must download this file to reactivate it."
               ." Otherwise your account will be deleted.'"
               ." $FEXLIB/reactivation.txt $user";
    # on error show STDOUT and STDERR
    system "$fexsend >/dev/null 2>&1";
    if ($?) {
      warn "$fexsend\n";
      system $fexsend;
    }
  } else {
    warn "$0: cannot execute $fexsend for reactivation()\n";
  }
}


1;
