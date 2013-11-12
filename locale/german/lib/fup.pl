# lokale Konfiguration fuer F*EX CGI fup

$info_1 = $info_login = <<EOD;
<p><hr><p>
<a href="/index.html">F*EX (File EXchange)</a>
ist ein Dienst um gro&szlig;e (sehr gro&szlig;e, riesige, gigantische, ...) Dateien zu senden.
<p>
Der Absender (Sie) l&auml;dt eine Datei auf den F*EX Server hoch und der
Empf&auml;nger bekommt automatisch eine Benachrichtigungs-E-Mail mit der Download-URL.<br> 
Nach dem Download oder nach $keep_default Tagen l&ouml;scht der Server die Datei.<br>
F*EX ist kein Archiv!
<p>
Um es zu nutzen, geben Sie Ihre Empf&auml;nger E-Mail Adresse(n) in die Felder oben ein.
<p>
Noch immer verwirrt?<br>
Testen Sie F*EX, indem Sie eine Datei an sich selbst senden
(Absender = Empf&auml;nger = Ihre E-Mail Adresse).
<p>
Siehe auch <a href="/FAQ.html">Fragen &amp; Antworten</a>.
<p><hr><p>
<address>
  <a href="mailto:$ENV{SERVER_ADMIN}">$ENV{SERVER_ADMIN}</a><br>
</address>
EOD

$info_2 = <<EOD;
<p><hr><p>
Nach dem Abschicken sehen Sie einen Upload Fortschrittsbalken
(wenn Sie Javascript aktiviert haben und Popups erlauben).
<p>
<em>Bemerkung: Viele Webbrowser k&ouml;nnen keine Dateien hochladen,
die gr&ouml;&szlig;er als 2 GB sind!</em><br> 
Wenn Ihre Datei gr&ouml;&szlig;er ist, m&uuml;ssen Sie einen speziellen 
<a href="/fuc?show=tools">F*EX client</a> nutzen.<br>
Sie brauchen ihn au&szlig;erdem, wenn Sie abgebrochene Uploads
wiederaufnehmen wollen. Ihr Webbrowser ist dazu nicht in der Lage.
<p>
Wenn Sie mehr als eine Datei verschicken wollen, dann verpacken Sie sie vorher in ein zip oder tar Archiv,
z.B. mit <a href="http://www.7-zip.org/download.html">7-Zip</a>.
<p>
Siehe auch <a href="/FAQ.html">FAQ<a>.
<p><hr><p>
<address>
  <a href="mailto:$ENV{SERVER_ADMIN}">$ENV{SERVER_ADMIN}</a><br>
</address>
EOD
