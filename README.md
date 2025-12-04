# LUH-Skin
Dieser Skin wurde dem [LUH-Stil](https://www.uni-hannover.de/) entsprechend angepasst.

## Version
v1.0.7

- [CHANGELOG](CHANGELOG.md)

## Screenshot
![Screenshot](screenshots/xmas-2024-0.png)
![Screenshot](screenshots/xmas-2024-2.png)

## Installation

Um das Skin zu installieren, sollte man zur {ILIAS Root}-Installation navigieren, zum Beispiel.
`/srv/ilias-luh/ILIAS`

```
cd /srv/ilias-luh/ILIAS/
cd Customizing/global/
```


Falls der Ordner 'skin' nicht vorhanden ist, dann anlegen.

```
mkdir skin
cd skin
```

Nun werden wir den LUH-Skin innerhalb des Skin-Ordners installieren; dazu führen wir einfach einen Git-Clone-Befehl aus:

`git clone https://github.com/iFadi/LUH-Skin.git`

Dann den entsprechenden Branch bzw. Tag auswählen z.B.:

`git checkout tags/v2.0.0`

bzw. falls man auf dem release_9 branch ist, dann kann man einfach git pull machen.

`git pull`


Das war es.

## Für die Implementierung

Zur Anpassung des Skins müssen die `.scss`-Dateien bearbeitet werden. Anschließend ist das Skript `update-skin.sh` **als root** auszuführen, um die **SCSS-Dateien zu kompilieren**.

```sudo ./update-skin.sh```

Dieses Skript benutzt die Systemzeit, um die CSS-Dateien mit einer eindeutigen ID zu versehen. 
Diese ID wird an den Hauptdateinamen des Skins LUH-Style.css angehängt, um das Neuladen der Skin-Änderungen im Browser zu erzwingen.
Falls auf dem produktiven System `dart-sass` nicht installiert ist, kann das oben genannte Skript nicht ausgeführt werden.
Daher ist es vorteilhaft, die kompilierte LUH-Style.css zum Beispiel auf einem Testsystem in einer bestimmten Tag- oder Skin-Version hinzuzufügen.

## ✅ Kompatibilität

Dieses Release wurde erfolgreich getestet mit:

* **ILIAS v9.12**

**WICHTIG**: Der Skin sollte bei jeder ILIAS Minor- und Major-Release auf Funktionalität getestet werden. Bei jedem ILIAS-Update muss der Skin neu kompiliert werden.

