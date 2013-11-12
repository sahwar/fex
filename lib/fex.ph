## your F*EX server host name (with domain)
$hostname = 'MYHOSTNAME.MYDOMAIN';

## admin e-mail address used in notification e-mails
$admin = 'fex@'.$hostname;

## password for http://$hostname/fac admin web interface
$admin_pw = '';

## optional: restrict web administration to ip range(s)
# @admin_hosts = qw(127.0.0.1-127.1.1.254 129.69.13.139);

## server admin e-mail address shown on web page 
$ENV{SERVER_ADMIN} = $admin;

## Bcc address for notification e-mails
$bcc = 'fex';

## send notifications about new F*EX releases
$notify_newrelease = $admin;

## optional: download-URLs as sent in notification e-mails
# @durl = qw(http://MYFEXSERVER/fop https://MYFEXSERVER/fop http://MYPROXY/fex/fop);

## On AUTO mode the fexserver sends notification e-mails automatically.
## On MANUAL mode the user must notify the recipients manually.
# $mailmode = 'MANUAL';
$mailmode = 'AUTO';

## optional: your mail domain
## if set it will be used as domain for every user without domain
## local_user ==> local_user@$mdomain
## if not set, addresses without domains produce an error
# $mdomain = 'MY.MAIL.DOMAIN';
# $admin = 'fexmaster@'.$mdomain;

## optional: static address (instead of F*EX user) in notification e-mail From
## BEWARE: if set, mail error bounces will not go to the real sender, but
##         to this address!
# $sender_from = $admin;

## optional HTML header extra link and logo
# @H1_extra = qw(http://www.MY.ORG http://www.MY.ORG/logo.gif);

# locales to present (must be installed!)
# if empty, present all installed locales
# @locales = qw(english swabian);

## default locale: which languange is used in first place
# $default_locale = 'swabian';

## where to store the files and logs
$spooldir = "$ENV{HOME}/spool";
$logdir = $spooldir;

## Default quota in MB for recipient; 0 means "no quota"
$recipient_quota = 0; 

## Default quota in MB for sender; 0 means "no quota"
$sender_quota = 0; 

## Expiration: keep files that number of days (default)
$keep = 5; 

## Expiration: keep files that number of days (maximum)
$keep_max = 99;

## Autodelete: delete files after download (automatically)
##	YES     ==> immediatelly (1 minute grace time)
##	DELAY   ==> after download at next fex_cleanup cronjob run 
##      2       ==> 2 days after download (can be any number!)
##	NO      ==> after expiration date (see $keep)
$autodelete = 'YES';

## if the file has been already downloaded then subsequentials
## downloads are only allowed from the same client (uses cookies)
## to prevent file sharing
$limited_download = 'YES';

## Allow or disallow overwriting of files
$overwrite = 'YES';
   
## optional: from which hosts and for which mail domains users may 
##           register themselves as full users
# @local_hosts = qw(127.0.0.1 ::1 10.10.100.0-10.10.200.255 129.69.1.11);
# @local_domains = qw(uni-stuttgart.de flupp.org);
# @local_domains = qw(*); # special: allow ALL domains

## optional: external users may register themselves as restricted users
##           for local receiving domains and hosts (must set both!)
# @local_rdomains = qw(flupp.org *.flupp.org);
# @local_rhosts = qw(10.0.0.0-10.0.255.255 129.69.1.11);
## optional: allow restricted user registration only by certain domains
# @registration_domains = qw(belwue.de ietf.org);
## optional: allow restricted user registration only by certain hosts
# @registration_hosts = qw(129.69.0.0-129.69.255.255 176.9.84.26);

## optional: for certain remote domains do not use sender address in 
##           notfication e-mail From, because their MTA will probably 
##           reject it if From and To contain their domain name.
##           Instead use $admin for From.
# @remote_domains = qw(flupp.org);

## optional: allow public upload via http://$hostname/pup for
# @public_recipients = qw(fexmaster@rus.uni-stuttgart.de);

## optional: allow anonymous upload without authentication for these IP ranges
# @anonymous_upload = qw(127.0.0.1 ::1 10.10.100.0-10.10.200.255 129.69.1.11);

## optional: forbidden addresses
# @forbidden_recipients = qw(nobody@* *@microsoft.com);

## optional: restrict upload to these IP ranges
# @upload_hosts = qw(127.0.0.1 ::1 10.10.100.0-10.10.200.255 129.69.1.11);

## optional: restrict download to these address ranges
# @download_hosts = qw(127.0.0.1 10.10.100.0-10.10.200.255 129.69.1.11);

## optional: throttle bandwith for certain addresses (in kB/s)
##           0 means : full speed
##           first match wins
# @throttle = qw(
#	framstag@*:0 microsoft.com:100 
#	127.0.0.1:0 202.0.0.0-211.255.255.255:1024
#	[::1]:0 [fe00::0-fe00::ffff]:0
# );

## optional: expire user accounts after x days of inactivity
##           delete=wipe out, notify=send mail to fex admin
# $account_expire = "100:delete";
# $account_expire = "365:notify";

## optional: allowed directories for file linking (see fexsend)
# @file_link_dirs = qw(/sw /nfs/home/exampleuser);

## optional: allow additional directories with static documents
##           (/home/fex/htdocs is always allowed implicitly)
# @doc_dirs = qw(/sw /nfs/home/exampleuser/htdocs);

## optional: suppress funny messages
# $boring = 1;

## optional: text file with your conditions of using
## will be append to registrations request replies.
# $usage_conditions = "$docdir/usage_conditions";
