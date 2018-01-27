## Comandos globales {#comandos-globales}

!Ejecuta un comando bash en GHEDSH

cdTe lleva al path indicado por parámetro.

_cd [path]_

Para volver al directorio raíz lo ejecutamos sin parámetro.

_cd_

Para volver al nivel anterior usaremos el parámetro “..”

_cd [..]_

Por defecto buscara un Repositorio al final de la cola de prioridades, si quieres buscar un repositorio con mayor prioridad usaremos:

_cd repo [nombre]_

Para buscar por defecto una asignación usaremos el parámetro “assig”.

cd assig [nombre]

doEjecuta un script con comando GHEDSH desde un fichero.

_do [Fichero script]_

exitSalir del programa.

helpLista de comandos disponibles.

rm clone filesBorra los repositorios clonados con GHEDSH.

Puedes usar una expresión regular para borrar los repositorios que tú prefieras.

_rm clone files /RegExp/_