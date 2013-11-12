# config for F*EX CGI fup

$info_1 = $info_login = <<EOD;
<p><hr><p>
<a href="/">F*EX (File EXchange)</a>
is a service to send big (large, huge, giant, ...) files.
<p>
The sender (you) uploads the file to the F*EX server and the recipient automatically gets
a notification e-mail with a download-URL.<br>
After download or after $keep_default days the server deletes the file.
F*EX is not an archive!
<p>
See also <a href="/FAQ/FAQ.html">questions & answers</a> and
<a href="http://fex.rus.uni-stuttgart.de/usecases/">use cases</a>.
<p><hr><p>
<address>
  <a href="mailto:$ENV{SERVER_ADMIN}">$ENV{SERVER_ADMIN}</a><br>
</address>
EOD

$info_2 = <<EOD;
<p><hr><p>
After submission you will see an upload progress bar 
(if you have javascript enabled and popups allowed).
<p>
<em>NOTE: Many web browsers cannot upload files > 2 GB!</em><br>
If your file is larger you have to use a special <a href="/fuc?show=tools">F*EX client</a>
or Firefox or Google Chrome which have no size limit.<br>
You also need a F*EX client for resuming interrupted uploads. Your web browser cannot do this.
<p>
If you want to send more than one file, then put them in a zip or tar archive, 
e.g. with <a href="http://www.7-zip.org/download.html">7-Zip</a>.
<p>
See also the <a href="/FAQ/FAQ.html">FAQ<a> and
<a href="http://fex.rus.uni-stuttgart.de/usecases/">use cases</a>.
<p><hr><p>
<address>
  <a href="mailto:$ENV{SERVER_ADMIN}">$ENV{SERVER_ADMIN}</a><br>
</address>
EOD
