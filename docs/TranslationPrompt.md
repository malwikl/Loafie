# Loafie – Übersetzung vorbereiten

Kopiere den folgenden Prompt zusammen mit den Texten in Perplexity. Die Übersetzung ist von Englisch nach Deutsch.

## Prompt für Perplexity

```text
Du bist ein professioneller Übersetzer für eine iOS-App zum Sauerteigbrotbacken.
Übersetze die folgenden englischen UI-Texte ins natürliche, kurze und verständliche Deutsch.

Regeln:
1. Übersetze jeden Eintrag genau einmal und behalte die Reihenfolge bei.
2. Behalte Platzhalter wie %@, %lld und %1$@ unverändert und an einer passenden Stelle.
3. Übersetze keine SF-Symbolnamen, technischen Bezeichner oder Werte innerhalb von Platzhaltern.
4. Verwende in der Benutzeroberfläche die Sie- bzw. neutrale Form nicht; die App soll freundlich und direkt klingen.
5. Verwende konsistente Begriffe: schedule = Zeitplan, phase = Phase, sub-timer = Untertimer, fold = Falten, bake = Backen.
6. Halte Button-Texte kurz. Übersetze Einheiten passend ins Deutsche: h = Std., min = Min.
7. Gib ausschließlich eine CSV mit exakt zwei Spalten aus: English,German.
8. Setze beide Spalten in doppelte Anführungszeichen. Wenn ein Text ein Anführungszeichen enthält, verdopple es nach CSV-Regeln.
9. Füge keine Erklärungen, keine Markdown-Formatierung und keine zusätzliche Kopfzeile hinzu.

Texte:
```

## Zu übersetzende Texte

```text
%@
%@ ago
%@ finished.
%@ finished. Next: %@.
%@ – %@
%@–%@
%lld h
%lld h %lld min
%lld min
%lld× every %lld min
+1 h
+10 min
+15 min
+2 h
+30 min
+4 h
+5 min
A schedule defines the phases and times of one bake.
Add Sub-Timer
After
All data stays on this iPhone.
All folds done
Another bake is already planned or running.
Another bake is already running. Finish or cancel it first.
Autolyse
Availability
Bake
Bake Start
Baking Path
Before
Bench Rest
Bulk Fermentation
Calculated Start
Calculated Timeline
Can stay in fridge until %@
Cancel
Cancel Bake
Cancel Bake?
Cannot Plan
Cannot Start
Choose Schedule
Coil Fold
Cold Bulk (Advanced)
Cold Bulk (Fridge)
Cold Bulk Bread
Cold Final Proof (Fridge)
Cold Window
Configure Fold Reminders
Continue
Cooling
Create
Create First Schedule
Create a schedule in the Schedules tab first.
Custom
Custom Step
Default start mode
Default target
Delete
Delete Schedule?
Done
Due
Duplicate
Duration
Earliest
Earliest ready
End Hour
Extend time
Fermenting
Final Proof
Finished
Finished %@ ago
First Reminder After
Fold Reminders
Fold and sub-timer reminders are suppressed during sleep hours. Phase-end and max warnings are always delivered. Timer alarms always use sound.
Folds: %lld / %lld done
Fridge time exceeded
Haptics
Hours
Include this step
Interval
Kneading
Latest
Lower Temperature
Lower Temperature to %lld °C
Maximum
Minimum
Minutes
Mix Ingredients
Mode
Name
New Schedule
New reminder
Next at %@
Next: %@
Next: %@ · %@
No Bake Running
No Schedules
Notes
Notifications
Notifications disabled — reminders won't appear.
OK
Open Lid
Optional Note
Overnight (Cold Final Proof)
Overnight Bread
Path
Pause
Paused
Pending
Phase Finished
Phase Name
Phase finished
Phases
Plan Backwards
Plan Start
Planning Defaults
Preheat Oven
Preheat oven
Privacy
Projected Timeline
Ready around %@
Ready to Slice
Ready to bake
Ready to start
Recommended
Recommended start time reached
Recommended start window
Remaining fold reminders for this phase will be skipped.
Reminders
Reminders during this phase, e.g. start preheating or remove the lid.
Remove Steam
Remove lid
Resume
Round %lld of %lld
Rounds
Running
Same-Day
Same-Day Bread
Save
Schedule Name
Schedules
Settings
Shape Loaf
Skip
Skip Rest
Skip remaining folds?
Skipped
Sleep Mode
Start
Start %@
Start %@ now.
Start After
Start Before Next Step
Start First Phase
Start Hour
Start Now
Start Timer
Start a schedule to begin baking.
Start when ready: %@
Stop
Stretch & Fold
Sub-Timers
Sub-timer during %@
Suggested Start
Summary
Tap a phase to adjust duration, sub-timers and details. Use the switch to quickly enable or disable a step.
Target
Target is the planned duration above. Minimum and maximum delimit the recommended cold window.
Technique
Technique Name
Temperature
Temperature (Note)
The last fold would be after the end of bulk fermentation. Adjust the count, interval or duration.
The recommended fridge time is exceeded. Check the dough and bake soon.
The timer will remind you when it is time to start.
The window uses the minimum and maximum durations of cold phases. You decide when to start the first phase.
These are defaults for starting a bake. The target date is chosen for each bake.
This cannot be undone.
This cannot be undone. Existing baking sessions keep their snapshot.
This schedule has an active baking session. The session will be kept as a snapshot.
This will stop the current bake and clear all pending reminders.
Time for a coil fold
Time to fold
Time to start baking
Time to stretch & fold
Timeline
Timer
Times are calculated from the start of the first enabled phase using each phase's target duration.
Timing
Title
Total: %@
Type
Waiting %@
folds
in %@
sub-timers
·
· %@–%@
· %lld %@
· %lld °C
· %lld× %@
```

## Nach der Übersetzung

Speichere die Antwort als CSV. Prüfe anschließend besonders, dass alle Platzhalter unverändert geblieben sind und jede englische Zeile genau eine deutsche Zeile besitzt. Die CSV kann danach in die String-Catalog-Datei `Loafie/Localizable.xcstrings` übertragen werden.
