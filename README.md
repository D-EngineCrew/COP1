# COP 1 — City of Peru (Ciudad del Perú)

Juego de mundo abierto para Android hecho con **Godot 4.3** (renderer de compatibilidad, pensado para móviles).
Protagonista: **JeanSyo**, con casa y auto en **El Agustino**.

## Qué incluye
- Mapa de Lima con 26 distritos, 10 avenidas y 29 hitos (Plaza Mayor, Cerro San Cristóbal, Gamarra, estadios, aeropuerto, malls, Huaca Pucllana…). Posiciones aproximadas y escala comprimida (0.12) para que el móvil aguante. Se genera por chunks alrededor del jugador.
- Clima: despejado, nublado, llovizna (garúa) y lluvia, con ciclo día/noche.
- Policía con IA: nivel de búsqueda en **sirenas** (1–5), patrulleros, arresto, SWAT en niveles altos.
- Bandas ficticias por territorio (Los Cuervos de Gamarra, La Jauría del Cerro, Los Halcones de Lurigancho, Los Lobos de la Costa Verde, Los Zorros de Comas).
- NPCs con estados (pasear, huir, atacar, testigos de crímenes), 7 armas, 5 tipos de vehículos (sedán, taxi, combi, mototaxi, patrullero).
- Interiores reales: casa, bodega, pollería, pizzería, tienda de armas, comisaría, banco, hospital, gimnasio, museo.
- Menú principal, 3 ranuras de guardado, opciones y menú de pausa.
- Controles táctiles multitáctil: joystick flotante, cámara por arrastre, botones.

## Compilar el APK (GitHub Actions)
1. Sube esta carpeta a un repositorio de GitHub (rama `main`).
2. El workflow `.github/workflows/build-apk.yml` usa `checkout@v6`, `setup-java@v5`, `setup-node@v6` (Node 24) y `upload-artifact@v7`.
3. En la pestaña **Actions** → *Build COP 1 APK* → descarga el artefacto `COP1-apk` (APK debug firmado).

## Pendiente / límites conocidos
- Código escrito sin poder abrirlo en Godot en esta sesión: puede haber errores menores al primer arranque; pega el log del workflow o del editor y se corrigen.
- Sin sonido todavía (no hay audio incluido).
- Gráficos low-poly (cajas y cilindros), no fotorrealistas.
