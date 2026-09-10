Actividad 9. Documento de diseño UI + Riesgos

Para lograr la magia de este juego primero debemos tomar en cuenta la IU (Interfaz de Usuario) que en pocas palabras vendria siendo la pantallita visual qeu le permite al usuario comunicarse al juego a travez de sus elementos HUD (osea los mapas, los botones, indicadores de vida, etc) que nos permiten estarle mostrandole al jugador la información vital que necesita en su juego.
Loop principal de interacción:

    Inico comabte: EL personaje recibe un capitulo de la narrativa, se presenta el reto de la batalla e inicia el combate

    Decision: Viene la parte de ataque donde se decide que tipo de ataque usar (un ataque, combo, etc), esquivar o usar pocion

    Ejecución: El jugador comienza tocando los botones en pantalla para ejecutar sus ataques

    Final: Viene la parte donde se finaliza la partida con un ganador (pantalla indicandote exito y tu recompensa y la nueva narrativa ) o de lo contrario el fracaso (donde se tendra que empezar desde ese capitulo la batalla)

Dinamicas vs IU

    Decidir si usar un ataque en combo o evitar exponerse -> Mostrar la barra de HP para que el usuario vea cuanta vida tiene y poner al jugador en un momento precipitado

    Cuando el usuario se esta quedando sin vida y sin pociones entra en momento de preocupación -> Mostrarle al usuario un contador de pociones en su in ventario

    Cuando el usario perdio la batalla y todo su avance tiene que idear otra tecnica de ataque -> Mostrar la pantalla de game over con el motivo de muerte de esa forma el jugador podra reflexionar en que si y no hacer

Riesgo de Diseño

Uno de los pricnipales errores de diseño que tal vez se podria presentar es que los botones estan tan rigidoz a que solo tendran las mecanicas esos boton es definidios y que no se permitira una li re flexibilidad al jugador de elegir que hara cada boton en si
Trade off

Al ser un juego de los mas sencillos, en 2d, pixel art es mas simplon de hacer desde sus mecanicas, diseño, etc . Lo malo es que no sera de esos juegos donde el realismo es donde manda la experiencia .
Justificación

Esto se debe a que el diseñador es su primera vez que diseña algo por lo que busca la menor complejidad en el desarrollo y si de graficos se trata lo menos posible de algo 3D algo mas sencillo de realizar. Las mecanicas deben ser muy simples tipas atacar, perder vida, matar, morir, etc.
