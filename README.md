# GOSS
Godot OS Simulator

First Godot project as a test bed for simulating a desktop to learn various UI features, input handling, file system handling for saving and loading, and loading built in applications inside windows as well as lauch external applications.

Currently features a desktop with any number of taskbars on sides of the screen, each taskbar has widgets supported by widget resources loaded both internal and external for modding.

There is an application manager, like the widget manager, that loads .tscn files inside resizable windows that can be moved around and what not. Apps are also registered/loaded internal and external so you can add your own apps by adding new .tres resource files in the correct user directory.

There is also a context menu, notification system, and a file browser to browser your user directory of files that you can Drag N Drop in the program from your PC to do what you want with.

If there is no built in app for that file extension you open it will use your OS native app to open it, so dont feak out if a program opens when you try to open certain files.

Current apps are an Image Viewer, Text Viewer/Editor, File Explorer, .tscn Viewer.
Current widgets are Start Menu, Clock, Apps/Windows open List with Pin support and preview icons
Taskbars have profiles that can be saved for later, and windows have custom color support set or through AppManifest files.
Window locations and Pins, along with any other themes are saved across sessions.


![alt text](https://github.com/kewsonagi/GOSS/blob/main/Screenshot%202025-09-02%20075415.png?raw=true)
![alt text](https://github.com/kewsonagi/GOSS/blob/main/Screenshot%202025-09-02%20075157.png?raw=true)
![alt text](https://github.com/kewsonagi/GOSS/blob/main/Screenshot%202025-09-02%20075128.png?raw=true)
![alt text](https://github.com/kewsonagi/GOSS/blob/main/Screenshot%202025-08-10%20183823.png?raw=true)
![alt text](https://github.com/kewsonagi/GOSS/blob/main/Screenshot%202025-08-10%20183807.png?raw=true)
