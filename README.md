Este capítulo se centrará en explicar las características que incorpora
*ghedsh* tras la etapa de desarrollo tratada en el capítulo anterior.

Se hará una distinción entre comandos del núcleo y comandos incorporados
(*built-in commands*). Los comandos del núcleo, son aquellos que no
trabajan con los datos de GitHub del usuario pero que, sin embargo, son
esenciales desde el punto de vista de la usabilidad y experiencia de
usuario con el CLI.

Además, los comandos incorporados sí trabajan con los datos de GitHub
del usuario identificado. Permiten realizar diversas tareas, priorizando
la rapidez en la ejecución de las mismas y la facilidad de uso de la
herramienta.

Autenticación con credenciales de GitHub {#3:sec:1}
========================================

El contenido de esta sección pretende explicar el proceso de
autenticación que debe seguir el usuario al usar *ghedsh* por primera
vez.

Dicho proceso es necesario, puesto que se trabajan con los datos que
dispone el usuario en GitHub. Además, la API REST v3 requiere, para
ciertas consultas (en especial, modificaciones como crear repositorios,
equipos y administrar la configuración), verificar la identidad del
usuario. Si no fuera así, se podrían llevar a cabo comportamientos
indeseados.

En *ghedsh*, se realiza la autenticación con *OAuth access
token*[]{.citation data-cites="B16"}, que consiste, en una definición
muy simplificada, en una cadena de caracteres alfanuméricos que actúa
como una contraseña. No obstante, en este caso de uso es mucho más
potente y segura. Las principales ventajas son:

-   Es revocable, es decir, el *token* puede dejar de ser válido,
    eliminando el acceso para ese *token* en particular, sin que el
    usuario tenga que cambiar su contraseña en todos sus accesos.

-   Sus permisos son configurables, esto es, un *token* puede ser válido
    sólo para ciertos recursos de una API. De esta manera, se conceden
    permisos de forma más controlada.

Para sintetizar este apartado, el usuario que utilice por primera vez
*ghedsh*, debe verificar su identidad mediante sus credenciales (nombre
de usuario y contraseña) de GitHub y se generará de forma automática un
*token* de acceso con los permisos necesarios para usar la herramienta.

![Ejemplo de autenticación al usar ghedsh por primera
vez.[]{label="fig:masterv1"}](docs/images/login-example.png)

Comandos del núcleo de ghedsh {#3:sec:2}
=============================

Como se ha indicado en la introducción de este tercer capítulo, se han
separado, por un lado, los comandos del núcleo de *ghedsh* y, por otro,
los comandos característicos de *ghedsh*.

En esta sección, se explicará este primer grupo de comandos, encargado
de tareas relacionadas con el sistema operativo y, lo más importante,
hacer que la herramienta sea agradable de manejar para el usuario.
Además, se revisarán aspectos importantes de su implementación.

bash (comando ghedsh) {#3.2.1}
---------------------

Permite interpretar un comando en la terminal del sistema operativo, sin
salir de *ghedsh*.

**Sintaxis:** `bash` `<comando_terminal>` . En la figura
[\[fig:bash-example\]](#fig:bash-example), se muestra un ejemplo de uso.

![Ejemplo de uso del comando
bash.[]{label="fig:bash-example"}](docs/images/bash-example.png)

Change directory: cd {#3.2.2}
--------------------

Análogamente al comando *cd* de la *Bash*[]{.citation data-cites="B17"},
que permite cambiar nuestro directorio actual de trabajo, en *ghedsh*
también existe este comando. No obstante, aunque la idea es similar,
existen diferencias a la hora de usarlo.

En nuestro sistema operativo (tipo Unix)[]{.citation data-cites="B18"},
cuando realizamos la operación *cd*, sólo podemos movernos entre
directorios (dependiendo de los permisos). Dado que en *ghedsh* no
existen directorios como tal, hablaremos de contextos. Los contextos en
esta herramienta hacen referencia a nivel de usuario, nivel de
organización, nivel de repositorio, etcétera.

Imaginemos por un momento que nuestro usuario se llama `ejemplo`,
disponemos de un repositorio que se llama `ejemplo` y una organización
denominada `ejemplo`. Ésto es totalmente válido, puesto que lo que no
permite GitHub es que dos usuarios se llamen igual, que el usuario tenga
dos repositorios con el mismo nombre o dos organizaciones bajo el mismo
nombre. Entonces, debemos proporcionar alguna manera de desambiguar a
qué contexto nos queremos cambiar.

En *ghedsh* se ha optado por el siguiente planteamiento: para realizar
la operación de *cd*, es necesario especificar el tipo de contexto
(nivel) al que queremos cambiarnos, así, aunque el usuario se encuentre
en el caso anteriormente comentado, *ghedsh* es capaz de saber a qué
contexto debe cambiar. La sintaxis del comando sería `cd` `<tipo>`
`<nombre>`, donde `nombre` es la cadena de texto que identifica al tipo.

Los tipos de contexto (pueden ser ampliables) que actualmente se
soportan en *ghedsh* son:

-   **Nivel de usuario**: estando a nivel de usuario, éste se puede
    cambiar a cualquiera de sus repositorios o a cualquier organización
    a la que pertenezca, como vemos a continuación:

    -   Repositorio del usuario: `cd` `repo` `<nombre>`.

    -   Organización del usuario: `cd` `org` `<nombre>`. *ghedsh*
        soporta el autocompletado de organizaciones, es decir, se puede
        pulsar el tabulador para completar automáticamente el nombre de
        la organización.

-   **Nivel de organización**: estando a nivel de una organización de la
    que es miembro el usuario autenticado, (*ghedsh* sabrá que se
    refiere al entorno de la organización a la que se ha cambiado) se
    puede mover a:

    -   Repositorio de la organización: `cd` `repo` `<nombre>`.

    -   Equipo de la organización: `cd` `team` `<nombre>`.

Además, si deseamos volver al contexto anterior, haremos de la misma
manera que en sistemas operativos tipo Unix: `cd` `..` . Hay que tener
en cuenta que, actualmete, no se puede realizar la operación de volver
al contexto anterior y cambiar a otro de manera simultánea (como en Unix
`cd` `../another/dir` ), es necesario hacerlo por separado.

### Detalles de implementación

Puesto que se trata de uno de los comandos más importantes de *ghedsh*,
se comentarán los aspectos destacados de la implementación del mismo,
incluyendo las dificultades encontradas.

Internamente, el comando *cd* contiene una pila (stack[]{.citation
data-cites="B19"}) en la que se almacenan todos los contextos previos.
La estructura de un contexto se muestra en el siguiente fragmento de
código:

::: {#cb1 .sourceCode data-language="Ruby"}
``` {.sourceCode .ruby}
  config = {
    'User' => client.login.to_s,
    'user_url' => client.web_endpoint.to_s << client.login.to_s,
    'Org' => nil,
    'org_url' => nil,
    'Repo' => nil,
    'repo_url' => nil,
    'Team' => nil,
    'team_url' => nil
  }
```
:::

-   `User`: permite saber el nombre del usuario autenticado en *ghedsh*.

-   `user_url`: contiene la URL (*Uniform Resource Locator*[]{.citation
    data-cites="B20"}) del perfil del usuairo en GitHub.

-   `Org`: indica el nombre de la organización actual, si el usuario no
    está posicionado sobre alguna, el valor es nulo.

-   `org_url`: URL de la organización en GitHub.

-   `Repo`: nombre del repositorio actual, en caso de estar dentro de
    alguno.

-   `repo_url`: URL del repositorio en GitHub.

-   `Team`: nombre del equipo actual si el usuario está posicionado
    dentro de alguno.

-   `team_url`: URL del equipo en GitHub.

En esencia, *change directory* irá variando estos parámetros para
conocer a qué nivel se encuentra el usuario (`User` siempre tendrá un
valor asignado porque representa el usuario autenticado). Por ejemplo,
para referirnos a un repositorio de una organización en la que el
usuario es miembro, tendríamos:

::: {#cb2 .sourceCode data-language="Ruby"}
``` {.sourceCode .ruby}
    config = {
    'User' => client.login.to_s,
    'user_url' => client.web_endpoint.to_s << client.login.to_s,
    'Org' => "EXAMPLE-ORG",
    'org_url' => nil,
    'Repo' => "repository-within-example-org",
    'repo_url' => nil,
    'Team' => nil,
    'team_url' => nil
  }
```
:::

En el caso de un repositorio de usuario, `User` tendría valor asignado y
`Repo` también tendría valor asignado. A diferencia con el caso
anterior, `Org` sería nulo ya que nos referimos a un repositorio a nivel
de usuario.

Una de las dificultades en la implementación de este comando, fue que,
antes de reasignar la estructura de datos que respresenta los contextos,
era necesario almacenar el contexto actual para poder volver a éste más
tarde.

Ruby proporciona dos métodos para copiar/clonar objetos:
`dup`[]{.citation data-cites="B21"} y `clone`[]{.citation
data-cites="B22"}. No obstante, realizan una copia superficial del
objeto, es decir, crearán un nuevo identificador de objeto pero el
contenido del mismo referenciará al de la entidad original.

Para solucionarlo, se utilizó el módulo *Marshal*[]{.citation
data-cites="B23"} de Ruby, que sí realiza una copia profunda del objeto.

Comandos incorporados en ghedsh {#3:sec:3}
===============================

A lo largo de esta sección, se explicarán individualmente los comandos
característicos de *ghedsh*. Los comandos característicos o incorporados
por *ghedsh* son aquellos que trabajan con los datos de GitHub del
usuario de la herramienta. Colaboran estrechamente con la GitHub API
REST v3 (véase, para más detalle, la documentación oficial de
*Octokit*[]{.citation data-cites="B24"}). Se explicará la sintaxis para
cada uno de ellos y se proporcionará ejemplos de uso.

Como convenio, los parámetros con el formato `<parameter>`, son
obligatorios. Los que tengan el formato `[parameter]`, son opcionales.

Por otro lado, las expresiones regulares admiten las opciones
establecidas por Ruby.

clear {#3.3.1}
-----

Realiza la misma tarea que el comando `clear` en Bash. Borra la pantalla
si es posible y sitúa el cursor en la parte superior izquierda de la
pantalla (ignora cualquier parámetro adicional).

**Sintaxis**: `clear` .

clone {#3.3.2}
-----

Clona repositorios y, si ya existe en el directorio local, realizará
`git` `pull` `--all`. Recibe como parámetro obligatorio el nombre del
repositorio que se desea clonar o una expresión regular, que permitirá
clonar todos los repositorios que casen con ella. Opcionalmente, es
posible especificar un directorio dentro de `$HOME` de la máquina local.
En caso de no exisir, se creará. Por defecto, se clonarán en el
directorio actual de la máquina local.

**Sintaxis**: `clone` `<nombre_repo`/Regexp/\>\| `[ruta_en_home]` .

Se puede ejecutar en:

-   Contexto de **usuario**: clonará los repositorios del usuario
    autenticado en *ghedsh*.

-   Contexto de **organización**: clonará los repositorios de la
    organización en la que se encuentre posicionado.

En la figura [\[fig:clone-example\]](#fig:clone-example) y
[\[fig:clone-example-org\]](#fig:clone-example-org) se muestran ejemplos
de uso.

![Ejemplo de clonar un repositorio de
usuario.[]{label="fig:clone-example"}](docs/images/clone-example.png)

![Ejemplo de clonar un repositorio de
organización.[]{label="fig:clone-example-org"}](docs/images/clone-example-org.png)

commits {#3.3.3}
-------

Muestra los *commits* (SHA, fecha, autor y mensaje del *commit*) de la
rama `master`, en caso de que no se le pase como parámetro una rama en
concreto. Es necesario estar posicionado sobre un repositorio de
cualquiera de los siguientes contextos: **organización** o **usuario**.

**Sintaxis**: `commits` `[rama_repositorio]` .

![Mostrar commits en un repositorio de
usuario.[]{label="fig:user-commits"}](docs/images/user-commits.png)

![Mostrar commits de la rama de un repositorio de
organización.[]{label="fig:user-commits"}](docs/images/orgs-commits.png)

exit {#3.3.4}
----

Temina la ejecución de *ghedsh*, guardando el contexto actual. Es decir,
si el usuario se encontraba dentro de una organización, la próxima vez
que entre en *ghedsh* estará dentro de la organización.

**Sintaxis**: `exit` .

files {#3.3.5}
-----

Muestra el contenido y el tipo de contenido (fichero o directorio) de un
repositorio. Debe estar posicionado dentro de un repositorio de
**usuario** o repositorio de **organización**. Si no se le proporciona
ningún parámetro, muestra el contenido de la raíz del repositorio. Si se
le especifica un subdirectorio, se mostrará su contenido.

**Sintaxis**: `files` `[subdirectorio]` .

![Listar contenido del
repositorio.[]{label="fig:dir-content"}](docs/images/dir-content.png)

![Listar contenido de un
subdirectorio.[]{label="fig:subdir-content"}](docs/images/subdir-content.png)

invite\_member {#3.3.6}
--------------

Añade nuevos miembros a una organización. Recibe como parámetros el/los
nombres de usuario de GitHub, separados por comas o por espacios.

Sólo puede ejecutarse en el contexto de una **organización**.

**Sintaxis**: `invite_member` `<user1,` `user2,` `user3,` `...,` `n>` .

![Añadir miembros
específicos.[]{label="fig:invite-member"}](docs/images/invite-member.png)

invite\_member\_from\_file {#3.3.7}
--------------------------

Añade nuevos miembros a una organización, especificando su nombre de
usuario en GitHub. Recibe como único parámetro un fichero (ver plantilla
[]{.citation data-cites="B27"}) existente en `$HOME` de la máquina
local.

El comando se ejecuta, exclusivamente, dentro del contexto de una
**organización**.

**Sintaxis**: `invite_member_from_file` `<ruta_home_fichero>` .

![Añadir miembros mediante
fichero.[]{label="fig:add-members-fil"}](docs/images/add-members-file.png)

invite\_outside\_collaborators {#3.3.8}
------------------------------

Invita a ser miembros de la organización a los colaboradores externos de
la misma. Si no se especifica ningún parámetro, invita a todos los
colaboradores externos. En caso de que reciba un parámetro, tendrá que
ser un fichero (ver plantilla []{.citation data-cites="B26"}) situado en
`$HOME` de la máquina local.

Se ejecuta, exclusivamente, cuando el usuario de *ghedsh* está situado
en el contexto de una **organización**.

**Sintaxis**: `invite_outside_collaborators` `[ruta_home_fichero]` .

![Invitación a ser miembros desde
fichero.[]{label="fig:invite-collabs"}](docs/images/invite-collabs.png)

issues {#3.3.9}
------

Abre el navegador por defecto, situando al usuario en la lista de
incidencias (*issues*). Debe estar posicionado dentro de un repositorio
de **usuario** o repositorio de **organización**.

**Sintaxis**: `issues` .

![Ver incidencias de un
repositorio.[]{label="fig:list-issues"}](docs/images/list-issues.png)

![Listado de incidencias del repositorio en
GitHub.[]{label="fig:issues-list"}](docs/images/issues-list.png)

new\_issue {#3.3.10}
----------

Abre el navegador por defecto, situando al usuario en el formulario de
creación de un issue. Para ejecutarlo, es necesario estar posicionado
sobre un repositorio.

**Sintaxis**: `new_issue` .

Está disponible para:

-   Contexto **usuario**: abre la página de *issues* del repositorio de
    usuario en el que está posicionado.

-   Contexto **organización**: abre la página de *issues* del
    repositorio de la organización sobre la que está posicionado.

![Nuevo issue en repositorio de
organización.[]{label="fig:new-issue"}](docs/images/new-issue.png)

![Formulario de creación de incidencias
(issues).[]{label="fig:new-issue"}](docs/images/issue-form.png)

new\_repo {#3.3.11}
---------

Crea un nuevo repositorio. La herramienta muestra al usuario dos
opciones para crearlo (menú):

-   *Default*: crea un repositorio público.

-   *Custom*: crea un repositorio público o privado, al que es posible
    añadirle opciones específicas mediante una guía que se le mostrará.
    Si no se quiere especificar alguna de las opciones que se muestran,
    puede pulsar la tecla retorno y omitir el paso.

**Sintaxis**: `new_repo` `<nombre_repositorio>`. Disponible para:

-   Contexto **usuario**: crea un repositorio para el usuario
    autenticado.

-   Contexto **organización**: crea un repositorio dentro de la
    organización en la que se encuentre posicionado el usuario.

En la figura [\[fig:create-repo\]](#fig:create-repo), vemos el menú de
creación del repositorio.

![Menú para la creación de un
repositorio.[]{label="fig:create-repo"}](docs/images/create-repo.png)

![Creación de un repositorio de usuario con opciones
específicas.[]{label="fig:custom-repo"}](docs/images/custom-repo.png)

new\_team {#3.3.12}
---------

Crea un nuevo equipo dentro de la organización en la que esté
posicionado el usuario. Si el comando no recibe ningún parámetro, se
abrirá la URL del formulario para crear el equipo en la web de GitHub.
En caso de especificarle un parámetro, éste tiene que ser un fichero
(ver plantilla []{.citation data-cites="B25"}) que se encuentre en algún
lugar de `$HOME` en la máquina local.

Una vez más, este comando sólo se puede ejecutar cuando el usuario está
posicionado dentro de una organización en *ghedsh*.

**Sintaxis**: `new_team` `[ruta_home_fichero]` .

![Formulario de creación de un equipo en
GitHub.[]{label="fig:create-team-form"}](docs/images/create-team-form.png)

![Creación de un equipo mediante
fichero.[]{label="fig:create-team-file"}](docs/images/create-team-file.png)

open {#3.3.13}
----

Abre el navegador por defecto y muestra información de GitHub según el
contexto:

-   Contexto de **usuario**: si se ejecuta `open` a nivel de usuario, se
    abre en el navegador el perfil GitHub del usuario autenticado en
    *ghedsh*. En caso de estar en un repositorio de usuario, se abre la
    URL de este repositorio.

-   Contexto de **organización**: a nivel de organización abre el perfil
    de la organización en GitHub. Si el usuario se encuentra posicionado
    en un repositorio de la organización, abre la URL del repositorio.
    Para este contexto en concreto, es posible pasarle un parámetro que
    consista en una expresión regular o el nombre de algún miembro y
    abrir su perfil. En este caso, la **sintaxis** sería: `open`
    `"nombre"` (para el nombre del miembro) o bien `open` `/Regexp/` .

-   Contexto de **equipo**: abre la URL del equipo en GitHub.

**Sintaxis** general: `open` .

orgs {#3.3.14}
----

Muestra las organizaciones a las que pertenece el usuario autenticado en
*ghedsh*. Si el comando no recibe ningún parámetro, se mostrarán todas
las organizaciones. En caso de proporcionarle un parámetro, debe ser una
expresión regular y mostrará los resultados que casen.

Sólo está disponible en contexto de **usuario**.

**Sintaxis**: `orgs` `[/Regexp/]` .

![Mostrar todas las organizaciones del usuario autenticado en
ghedsh.[]{label="fig:show-orgs-regexp"}](docs/images/show-all-orgs.png)

![Filtrar organizaciones mediante expresión
regular.[]{label="fig:show-orgs-regexp"}](docs/images/show-orgs-regexp.png)

people {#3.3.15}
------

Muestra los nombres de los usuarios que componen una organización. Esto
incluye miembros y colaboradores externos (si el usuario autenticado en
*ghedsh* tiene permisos de administrador en la organización). Si no se
le proporciona ningún parámetro, lista todos. En caso de utilizar una
expresión regular, se mostrarán los resultados que hayan casado con
ella.

Este comando se usa, exclusivamente, cuando el usuario está posicionado
dentro del contexto de una **organización**.

**Sintaxis**: `people` `[/Regexp/]` .

![Mostrar los miembros de una
organización.[]{label="fig:org-people"}](docs/images/org-people.png)

![Mostrar mediante expresión regular los miembros de una
organización.[]{label="fig:org-people-regexp"}](docs/images/org-people-regexp.png)

repos {#3.3.16}
-----

Muestra los repositorios según el contexto. Si no se le especifica
nungún parámetro, mostrará todos los repositorios. Si se le proporciona
una expresión regular, mostrará los nombres de los repositorios que
hayan casado.

**Sintaxis**: `repos``[/Regexp/]`.

-   Contexto **organización**: muestra los repositorios de la
    organización en la que se encuentra el usuario de *ghedsh*.

    ![Comando repos a nivel de
    usuario.[]{label="fig:user-repos"}](docs/images/user-repos.png)

-   Contexto **usuario**: muestra los repositorios del usuario
    autenticado en *ghedsh*.

    ![Comando repos a nivel de
    organización.[]{label="fig:org-repos"}](docs/images/org-repos.png)

rm\_repo {#3.3.17}
--------

Elimina el repositorio especificado. Se puede realizar tanto a nivel de
**usuario** como a nivel de **organización**.

**Sintaxis**: `rm_repo` `<nombre_repositorio>` .

![Eliminación de un
repositorio.[]{label="fig:custom-repo"}](docs/images/delete-repo.png)

rm\_team {#3.3.18}
--------

Elimina un equipo. No recibe ningún parámetro. Se abre el navegador por
defecto y el usuario borrará el o los equipos que desee de la lista
proporcionada. Se ejecuta sólo en contexto de **organización**.

**Sintaxis**: `rm_team` .

teams {#3.3.19}
-----

Muestra los equipos existentes en una organización. Si no se le
especifica ningún parámetro, listará todos los equipos. Si se le
proporciona una expresión regular, mostrará los resultados que casen con
ella. Se ejecuta, exclusivamente, en el contexto de una
**organización**.

**Sintaxis**: `teams` `[/Regexp/]` .

![Listar los equipos de una
organización.[]{label="fig:org-teams"}](docs/images/org-teams.png)

![Listar mediante expresión regular los equipos de una
organización.[]{label="fig:org-regexp-teams"}](docs/images/org-regexp-teams.png)

Comandos que dan soporte al proceso de evaluación {#3:sec:4}
=================================================

Los comandos que se explicarán en esta sección reflejan uno de los
principales objetivos de *ghedsh*: aportar funcionalidades específicas
que usen las metodologías de *GitHub Education*, facilitando al
profesorado la gestión de repositorios del alumnado así como la
ejecución de *scripts* sobre los mismos.

En este conjunto de comandos tenemos: `new_eval`, `foreach` y
`foreach_try`.

new\_eval {#3.4.1}
---------

Permite crear un repositorio de evaluación. Recibe como parámetros el
nombre del repositorio de evaluación y una expresión regular que añade
como subdirectorios los repositorios que lo conforman. En *ghedsh*, un
repositorio de evaluación consiste en hacer uso de los submódulos de
*git*, de manera que se crea un repositorio raíz que contiene como
submódulos todos los proyectos que se van a evaluar. Los pasos que
realiza son:

-   En el directorio actual de la máquina local del usuario, crea un
    directorio con el mismo nombre del repositorio de evaluación.

-   Añade como submódulos los repositorios de la organización que casen
    con la expresión regular.

-   Ejecuta `git` `push` y sube el contenido a la plataforma GitHub.

Dado que, para comprender todas las ventajas que ofrece este comando, es
necesario conocer los submódulos de git (*gitsubmodules[]{.citation
data-cites="B28"}*), se explicará en qué consisten a continuación.

Esencialmente, un submódulo es un repositorio que se encuentra contenido
dentro de otro repositorio. El submódulo tiene su propio histórico de
*commits* y, el repositorio raíz que lo contiene, se denomina
súper-proyecto o súper-repositorio.

Es probable que, mientras trabajamos en un proyecto, necesitemos usar
otro proyecto dentro de él. Quizás se trate de una librería de terceros
o una que desarrollamos nosotros mismos de forma separada dentro de un
proyecto principal. En estos casos, surge un problema común: precisamos
de ser capaces de tratar los dos proyectos por separado y, aún así, usar
uno dentro del otro.

El control de versiones *Git* aborda ese problema usando submódulos. Los
submódulos permiten mantener un repositorio como un subdirectorio de
otro repositorio *Git*. Por lo tanto, permite clonar otro repositorio en
nuestro proyecto, separando los *commits* de cada uno.

En *ghedsh*, el comando `new_eval` se encuentra disponible únicamente en
el contexto de **organización**.

**Sintaxis**: `new_eval` `<nombre_repo_evaluacion>` `</Regexp/>` .

![Ejemplo de creación de un repositorio de
evaluación.[]{label="fig:eval-example"}](docs/images/eval-example.png)

![Estructura de un repositorio de evaluación en
GitHub.[]{label="fig:eval-example"}](docs/images/eval-preview.png)

foreach {#3.4.2}
-------

Ejecuta sobre cada submódulo el comando *Bash* especificado como
parámetro. No se detiene ante posibles errores en el proceso.
Internamente, ejecuta `git` `submodule` `foreach` .

**Sintaxis**: `foreach` `<comando_bash>` .

Para que el comando lleve a cabo su cometido, se necesita lo siguiente:

-   Estar en contexto de **organización** dentro de *ghedsh* (único
    contexto en el que está disponible `foreach` ).

-   Estar posicionado dentro de un repositorio que contenga submódulos,
    dentro de *ghedsh*.

-   En la máquina local, el directorio actual (donde hemos ejecutado
    *ghedsh*) debe ser el repositorio de evaluación en cuestión.

Como se indica en la documentación oficial de *git submodule foreach
[]{.citation data-cites="B29"}*, el comando que se le proporciona tiene
acceso a las siguientes variables:

-   `$name`: nombre del submódulo.

-   `$path`: nombre del submódulo relativo al súper-proyecto.

-   `$sha1`: SHA-1[]{.citation data-cites="B30"} del último *commit*.

-   `$toplevel`: ruta absoluta al súper-proyecto.

Por otro lado, como también indica la documentación, cuando existe un
error en algún submódulo durante la ejecución del comando, se detiene y
devuelve un código distinto de cero. No obstante, este comportamiento
puede evitarse añadiendo ``\|\| `:` al final del comando especificado
como parámetro.

Hay que tener en cuenta que *foreach* en ***ghedsh***, **ya incorpora
este comportamiento** y no se detendrá ante errores.

![Ejemplo de ghedsh
foreach.[]{label="fig:foreach-example"}](docs/images/foreach-example.png)

foreach\_try {#3.4.3}
------------

Realiza la misma tarea que *foreach*([4.2](#3.4.2)) y requiere las
mismas condiciones para su uso. A diferencia de éste, *foreach\_try*
**detendrá su ejecución cuando se produzca un error en el proceso**.

Caso de uso {#3:sec:5}
===========

Cabe destacar que el director de este Trabajo de Fin de Grado, Casiano
Rodríguez León, ha hecho uso de la herramienta *ghedsh* en un entorno
educativo real.

En concreto, se ha utilizado para facilitar tareas de gestión de
repositorios y evaluación de prácticas en el curso de Procesadores de
Lenguajes (año académico 2017-2018) a lo largo del mes de junio. Además,
esto ha contribuido a mejorar aspectos de la herramienta, puesto que, en
un entorno real, suelen aparecer nuevos casos de uso que han sido
cubiertos satisfactoriamente.

Por otro lado, Casiano ha realizado diversos vídeo tutoriales (ver
sección [6](#3:sec:6)) en los que se profundiza en el manejo de comandos
que dan soporte al proceso de evaluación.

Aprendiendo a evaluar usando Git, GitHub y GitHub Classroom {#3:sec:6}
===========================================================

En esta sección se comentará una serie de recursos disponibles que
contienen ejemplos e información de cómo *Git*, *GitHub* y *GitHub
Classroom* ayudan en el proceso de evaluación. Además, se hará especial
mención a los vídeo tutoriales realizados por Casiano Rodríguez León, en
los que, mediante el uso de *ghedsh*, se gestiona mejor dicho proceso.

Se debe tener en cuenta que todavía se están incorporando cambios en
*ghedsh*. Por lo tanto, es posible que el comportamiento de algunos
comandos hayan cambiado respecto a los vídeos tutoriales que se
indicarán a continuación. No obstante, la filosofía de uso sigue siendo
la misma.

En cuanto a los tutoriales realizados por Casiano tenemos:

-   "Preparando una tutoria con un alumno usando Git, GitHub, ghedsh y
    ghi"[]{.citation data-cites="B31"}, donde se muestra un ejemplo de
    cómo hacer un seguimiento del trabajo de un alumno para poder
    evaluarlo. En este caso, se utiliza el comando `clone` con expresión
    regular de *ghedsh*. Para las incidencias se usa *ghi*, de esta
    manera se puede aportar retroalimentación al alumno desde la línea
    de comandos.

-   "Evaluando múltiples asignaciones con ghedsh usando
    foreach"[]{.citation data-cites="B32"}. En este otro vídeo se expone
    cómo es posible evaluar un conjunto grande de prácticas, mediante la
    ejecución de un script a través de `git` `submodule` `foreach`
    `script` .

Por otro lado, también existen recursos de la propia plataforma *GitHub*
y la comunidad *GitHub Education*:

-   Guía *GitHub Classroom* para los profesores[]{.citation
    data-cites="B33"}.

-   Colección de comentarios en el Foro de la *GitHub Education
    Community* sobre evaluar[]{.citation data-cites="B34"}.

-   Blog *GitHub*: "How to grade programming assignments on
    GitHub"[]{.citation data-cites="B35"}.
