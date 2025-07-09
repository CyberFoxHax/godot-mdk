# Open source reimplementation of MDK in Godot

This project aims to reimplement [MDK](https://en.wikipedia.org/wiki/MDK_(video_game))
using [Godot Engine](https://godotengine.org/). **It is not in a playable state yet. (but you can walk around in the levels)**

This is being developed as a personal project for several reasons:

- Allow MDK to run on modern systems easily, on any platform.
  No compatibility wrappers needed. (Except this one)
- Enhance the game in ways that were not possible beforehand: uncapped framerate,
  replayability options, quality of life features, …
- Give me another "real world" Godot project to work on :slightly_smiling_face:

___

**Project status**

Currently only levels mesh have been correctly loaded. That is all levels.

**MDK file formats**

MDK File formats related information can be retrieved by analysing these projects

1. https://github.com/brandonhare/mdk-parse/
2. MDK-Tools by Buxxe, can be found on the mdk discord server: [https://discord.gg/KGG9ttDg](https://discord.gg/JUVnWZR6Z4)

most of the project is based on MDK-Tools. But there is no details on the 3D Animations. That should be in the mdk-parse project.

___

## Running the project

This project is currently being developed with Godot 4.4

Running the project **requires** game data from a MDK installation.
You can buy the original game on [GOG](https://www.gog.com/game/mdk)
or [Steam](https://store.steampowered.com/app/38450/MDK/).
*Waiting for a sale?* Set up an email alert using [IsThereAnyIdeal](https://isthereanydeal.com/game/mdk/info/).

MDK's game can be in several locations and to find the list look in: levels/load_level.gd#3

(and without redistributing it within this repository).

## License

Copyright © 2021 Hugo Locurcio and contributors

Unless otherwise specified, files in this repository are licensed under the MIT license.
See [LICENSE.md](LICENSE.md) for more information.

This repository does not include any proprietary game data from MDK.

*This project is not affiliated with Shiny Entertainment or Interplay Inc.*
