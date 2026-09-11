# HSD-Party
[![Made with Godot](https://img.shields.io/badge/Made%20with-Godot-478CBF?style=flat&logo=godot%20engine&logoColor=white)](https://godotengine.org)

HSD-Party ist ein Sammlung von vielen Minispielen.

## Git
`git clone [repo url]` Klonen des Repos auf den Computer <br/>

`git fetch` Holt neue Branches/Commits vom Remote, ändert aber nichts am aktuellen Stand. <br/>

<br/>

#### Neuen Branch erstellen / wechseln

Bitte benennt die Branch, mit der Nummer des Issues/Task/Bug, zu welcher die neue Änderung gehört + was es macht. z.B. "1_Multiplayer" dies dient der einfacheren Zuordnung und Struktur.

`git branch` zeigt alle lokalen Branches <br/>
`git branch <name>` erstellt neuen Branch <br/>

`git checkout <name>` zu Branch wechseln <br/>
`git checkout -b <name>` erstellen + wechseln (Shortcut) <br/>

<br/>

#### Änderungen hochladen

`git add <datei>` <br/>
`git add .` alle Änderungen <br/>

`git commit -m "Commit beschreibung"` <br/>

`git rebase <branch>` <br/>
`git rebase origin/main` Platziert eigene Commits „oben drauf“ auf einen anderen Stand → saubere Historie. <br/>

`git push --force` Pushed die Änderungen auf die Branch.

<br/>

#### Merge auf den Master

Nach dem der Code auf einer eigenen Branch Fertig gestellt wurde, kann eine Merge request gestellt werden. Bitte dort sowohl den Issue, als auch die passende Dokumentation verlinken.

Spätestend jeden Dienstag um 10 Uhr werde ich @jonas.kampshoff eine Merge von alle offenen Merge requests durchführen. MergeRequest nach diesem Zeitpunkt werden nicht mehr in der Version von dieser Woche sein.

Teil des Merges ist eine CodeReview mit möglichen Anmerkungen, welche zuvor verbessert werden sollten.

#### Informationen

`git diff` unstaged Änderungen <br/>
`git diff --staged` gestaged vs letzter Commit <br/>
