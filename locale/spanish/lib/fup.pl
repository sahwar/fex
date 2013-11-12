# config for F*EX CGI fup

$info_1 = $info_login = <<EOD;
<p><hr><p>
<a href="/">F*EX (File EXchange)</a>
es un servicio para enviar ficheros (grandes, enormes, gigantes, ...).
<p>
El remitente (usted) sube el fichero al servidor F*EX y el destinatario recibe autom&aacute;ticamente
una notificaci&oacute;n por correo electr&oacute;nico con una URL de descarga.<br>
Tras la descarga o tras $keep_default d&iacute;as el servidor borra el fichero.
&iexcl;F*EX no es un archivador!
<p>
Vea tambi&eacute;n <a href="/FAQ.html">preguntas y respuestas</a>.
<p><hr><p>
<address>
  <a href="mailto:$ENV{SERVER_ADMIN}">$ENV{SERVER_ADMIN}</a><br>
</address>
EOD

$info_2 = <<EOD;
<p><hr><p>
Tras pulsar el bot&oacute;n de enviar ver&aacute; una barra de progreso de la subida
(si tiene javascript activado y permite las ventanas emergentes)
<p>
<em>NOTE: &iexcl;La mayor&iacute;a de los navegadores web no pueden subir ficheros > 2 GB!</em><br>
Si su fichero es m&aacute;s grande tiene que usar <a href="/fuc?show=tools">un cliente de F*EX</a> especial.<br>
Tambi&eacute;n necesita uno para poder continuar con una subida interrumpida. Su navegador no puede hacerlo.
<p>
Aviso: &iexcl;algunos proxys HTTP como privoy retrasan la barra de progreso de la subida!<br>
Quiz&aacute; quiera desabilitar el proxy para $ENV{SERVER_NAME} si se encuentra con problemas.
<p>
Usuarios de firefox: &iexcl;no pulse [ESC] porque aborta la subida!
<p>
Vea tambi&eacute;n la <a href="/FAQ.html">FAQ<a>.
EOD
