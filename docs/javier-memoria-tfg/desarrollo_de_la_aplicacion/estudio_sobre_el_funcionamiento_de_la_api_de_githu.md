## Estudio sobre el funcionamiento de la API de GitHub {#estudio-sobre-el-funcionamiento-de-la-api-de-github}

Para poder poder hacer uso de los datos de GitHub, así como modificarlos y subirlos a su plataforma, se hará uso la interfaz de programación de aplicaciones web “GitHub API v3” [4].

Actualmente existen para esta API varias librerías que permiten el intercambio de datos mediante peticiones HTTPS y envió de datos a través del formato de texto ligero JSON.

Por un lado se puede encontrar la librería oficial Octokit, quetiene diferentes versiones para distintos lenguajes de programación.

Lenguajes en los que esta disponible Octokit:

*   Objetive-C

*   Ruby

*   .NET

Además de la oficial de GitHub, se pueden encontrar bastantes librerías no oficiales en diferentes lenguajes tales como: Ruby, Python, Go, Java, Haskell, Javascript, Julia, Pearl, Php o Ruby.

Finalmente, se optó por utilizar la librería oficial Octokit [5] 
, para el lenguaje de programación Ruby. Ya que ofrecía una mayor sensación de fiabilidad, estar mejor documentada y haber sido usada también en la herramienta _Teacher&#039;s Pet_ diseñada por la propia plataforma GitHub.

### Uso de la librería Octokit {#uso-de-la-librer-a-octokit}

1.  1.  A continuación se explicara el método de uso necesario para el correcto funcionamiento de la librería en Ruby.

        Para poder usar las funcionalidades que ofrece la librería, es necesario hacer un “Login” con la plataforma GitHub. Para ello hace uso de un objeto cliente que realice la autentificación del usuario, y a partir de ahí poder aplicar las funcionalidades permitidas según el tipo de “Login” aplicado.

        client = Octokit::Client.new(:login =&gt; &#039;user&#039;, :password =&gt; &#039;password&#039;)

        user = client.user

        user.login

        Sería un ejemplo de la creación del objeto cliente del usuario y su posterior petición de acceso. En este caso se puede observar que se le indica el nombre de usuario de GitHub y la contraseña por parámetro, esto es debido a que la librería ofrece diferentes opciones de autentificación.

        - Autentificación básica:

        Se aplica al no autenticar al usuario, permite el acceso a la API pero las funcionalidades estarán limitadas. Básicamente da lugar a poder ejercer un modo lectura de los datos de GitHub, siempre que sea permitido.

        - Autentificación compleja:

        Se hace uso de ella al autenticar completamente al usuario. Existen varias formas de aplicarla, como la opción de Usuario y Contraseña que en este caso daría todos los permisos existentes, o la autentificación por _Open Authorization_ (**Oauth**)limitando los permisos aplicables a la aplicación.

A partir de aquí se podrán usar las diferentes opciones que ofrece la librería. Que básicamente realizara consultas y convertirá los datos recibidos en un tipo de objeto de una clase Ruby llamada _Sawyer_. Este objeto creado contendrá volcada toda la información, que a su vez tendrá que ser seleccionada para su uso por el propio programador que utilice la herramienta.
