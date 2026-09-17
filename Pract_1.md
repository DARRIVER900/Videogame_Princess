# UNIVERSIDAD DE COLIMA
## Facultad de Telemática
### Ingeniería de Software - 7° Semestre

**Juego:** Once Upon a Final War  
**Documento:** Game Design Document (GDD)  
**Integrante(s):**
* Rivera Anguiano Barbara Daria
* Rios Martinez Carla Jazmin
* Rodríguez Alejandro

---

## 1. High Concept
Juego de pelea táctica 2D estilo pixel-art gótico (Dark-Cute) donde dos princesas rivales libran duelos a muerte tras el misterioso asesinato de sus hermanos. Combina la estética tierna de caramelo con combates medievales sangrientos, violencia explícita y gestión estratégica por turnos/tiempo.

## 2. Experiencia central
El jugador experimenta una constante tensión táctica al equilibrar agresión y supervivencia bajo presión de tiempo. Busca transmitir satisfacción visual (gore estilizado) al dominar los movimientos, junto con un sentimiento de triunfo real tras superar combates castigadores.

## 3. Perfil de jugador
* **Público Objetivo:** Jugadores de títulos indie de acción, peleas 2D y estética retro/gótica.
* **Nivel de Habilidad:** Mid-core a Hardcore. Valoran los retos basados en tiempo de reacción, aprendizaje de patrones y ejecución precisa de comandos.

## 4. Core Loop
* **Narrativa:** Inicia capítulo e historia del reino.
* **Duelo:** Comienza la batalla 1v1 contra la rival.
* **Interacción:** Atacas, esquivas o te curas en turno.
* **Victoria:** Avanzas de capítulo, sumas puntuación.
* **Derrota:** Pantalla de moriste, reinicias el capítulo.

## 5. Mecánicas principales

### Movimiento de Navegación
* **Moverse a la derecha:** Tecla `D` / Flecha Derecha
* **Moverse a la izquierda:** Tecla `A` / Flecha Izquierda

### Acciones de Combate (Ofensivas)
* **Golpe Normal:** Tecla `K`
* **Golpe Fuerte:** Tecla `L`
* **Ataque de Veneno (Rango/Directo):** Tecla `U` (Aplica daño DoT)
* **Super Pesado con Carga:** Tecla `J` (Rompe guardia / Daño alto)

### Acciones de Evasión y Defensa
* **Saltar atrás:** Teclas `W + A`
* **Saltar adelante:** Teclas `W + D`
* **Agacharse:** Tecla `S`
* **Derrapar:** Teclas `S + A/D`

### Sustento y Condición de Muerte
* **Curar HP:** Tecla `E` (Restaura salud consumiendo inventario)
* **Muerte:** Pérdida total de Puntos de Vida ($HP = 0$) desencadena pantalla de derrota.

## 6. Dinámicas esperadas
* **Riesgo vs. Recompensa:** Decidir entre ejecutar el ataque pesado con carga (Tecla `J`) dejando vulnerable al personaje o asegurar con un golpe rápido (Tecla `K`).
* **Presión de Inventario:** Evaluar el momento crítico para curarse con la tecla `E` antes de recibir un impacto letal.
* **Lectura de Patrones:** Derrapar o agacharse para esquivar proyectiles o veneno enemigo y contraatacar en la ventana de recuperación.

## 7. Mundo y conflicto
Los reinos de Candy (riqueza comercial) y Chocolate (riqueza minera) mantenían prosperidad gracias al compromiso matrimonial de sus herederos. La tragedia ocurrió cuando ambos príncipes aparecieron sin vida en circunstancias no esclarecidas. Ante la falta de culpables, la ira desató una guerra prolongada. Las hermanas menores, convertidas en las nuevas princesas herederas, toman el mando para erradicar al reino vecino y coronarse sobre las ruinas.

## 8. Interfaz conceptual
* **HUD Superior:** Barras de vida (HP) de ambas princesas, retratos Dark-Cute, indicador de estado actual (Veneno/Normal) y temporizador de turno.
* **HUD Inferior:** Indicador de pociones disponibles, contador de combo y multiplicador de daño activo.
* **Pantallas de Transición:** Cuadros estilo novela visual en pixel-art para introducir diálogos de narrativa entre capítulos y pantalla sangrienta de Game Over.

## 9. MVP (Producto Mínimo Viable)

### Personajes Jugables
2 Princesas (Chocolatito y Dulcecito) compartiendo el set de ataques base pero con variantes estéticas (skins) y voces/efectos.

#### Princesa Dulcecito (Reino de Candy)
* **Perfil:** Heredera menor del Reino de Candy, la potencia comercial del continente. Tras la misteriosa muerte de su hermano mayor, pasó de ser una joven ingenua rodeada de lujos a una estratega fría y despiadada, impulsada por un deseo implacable de venganza contra la casa de Chocolate.
* **Apariencia (Skin Default):** Estética Dark-Cute victoriana. Lleva un vestido estilizado de tul de azúcar rosa pálido manchado de jarabe oscuro en el dobladillo, una corona asimétrica de caramelo cristalizado y ojos amarillos brillantes con ojeras pronunciadas.
* **Personalidad:** Perfeccionista, calculadora y distante. Habla con elegancia aristocrática, pero ejecuta sus ataques con una crueldad sangrienta.
* **Atributos POO Específicos:**
  ```json
  {
    "nombre": "Princesa Dulcecito",
    "idSkinActiva": "SKIN_CANDYR_DEFAULT",
    "modsetClase": "AGIL_DISTANCIA",
    "multiplicadorDanio": 1.0
  }

  ## 13. Roles del Equipo de Diseño

* **Lead Designer & UI Designer (Barbara):**
  * Supervisión general de la visión del juego y coherencia entre sistemas.
  * Diseño conceptual de la interfaz de usuario (HUD, barras de HP, temporizadores y contadores de inventario).
  * Creación y flujo de pantallas (Menú principal, Selección de personaje, Diálogos narrativos y *Game Over*).
  * Regulación del feedback visual e indicadores de estado (*Veneno/Normal*, alertas de vida baja).

* **Game Designer (Alex):**
  * Definición y balanceo del *Core Loop* de juego y sistemas de combate 1v1.
  * Mapeo y asignación de controles tácticos (`W,A,S,D` + `U,J,K,L,E`).
  * Parametrización del sistema de combate (daño por tipo de ataque, tiempos de refresco, consumo de pociones +15 HP).
  * Definición de reglas del juego, condiciones de victoria/derrota y estructura POO de la clase base `Personaje`.

* **Level Designer & Writer (Carla):**
  * Redacción de la narrativa *Dark-Cute* y estructuración de los 9 pasos del arco dramático.
  * Diseño del flujo de misiones y progresión de capítulos.
  * Creación del trasfondo de los reinos de **Candyr** y **Chocolate**, así como las fichas de las princesas.
  * Layout y ambientación espacial de la arena de combate 2D (Frontera en ruinas y Catedral de Azúcar).