# config for F*EX CGI fup

$info_1 = $info_login = <<EOD;
<p><hr><p>
<a href="/">F*EX (File EXchange)</a>
é un servizo para enviar (grandes, enormes, xigantes, ...) ficheiros.
<p>
O remitente (vostede) carga o ficheiro no servidor F*EX e o receptor obtén automaticamente
unha notificación vía correo cun enderezo URL para descargalo.<br>
Despois de descargalo ou tras $keep_default días o servidor elimina o ficheiro.
F*EX non é un arquivo!
<p>
Vexa máis información en <a href="/FAQ.html">preguntas e respostas</a>.
<p><hr><p>
<address>
  <a href="mailto:$ENV{SERVER_ADMIN}">$ENV{SERVER_ADMIN}</a><br>
</address>
EOD

$info_2 = <<EOD;
<p><hr><p>
Despois de remitilo verá unha barra de progreso de carga 
(se ten o javascript activado e permite as xanelas emerxentes).
<p>
<em>NOTA: A maior parte dos navegadores non poden cargar ficheiros > 2 GB!</em><br>
Se o seu ficheiro é maior, ten que usar un <a href="/fuc?show=tools">cliente F*EX</a> especial.<br>
Tamén pode necesitalo para retomar cargas interrompidas. O seu navegador non pode facelo.
<p>
Aviso: algúns proxies HTTP como privoxy retardan a barra de progreso de carga!<br>
Pode querer desactivar a intermediación do proxy $ENV{SERVER_NAME} se se encontra con este problema.
<p>
Usuarios do Firefox: non prema en [ESC] porque isto abortará a carga!
<p>
Vexa máis información na <a href="/FAQ.html">FAQ<a>.
EOD
