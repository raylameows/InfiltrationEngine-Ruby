# Ruby
Ruby is an automatic update fetcher for [InfiltrationEngine-Custom-Missions](https://github.com/MoonstoneSkies/InfiltrationEngine-Custom-Missions). As long as a major change isn't made to the serializer, you will never have to reinstall anything serializer-related again.

Ruby will automatically fetch **SerializationTools** and set it up for you in `ReplicatedStorage/Plugins/Ruby/SerializationTools`. This folder is also used as a cache to prevent sending a million HTTP requests every time you open Studio.

## Usage
When opening the serialization tools, you'll see a new button - pressing the button once will check if your serializer is up to date, pressing it twice will build the serializer from source. It is heavily recommended that you don't treat this button as a toy, unless you like getting HTTP 403 errors.
Ruby automatically checks if your serializer is up to date every 10 minutes, so doing manual checks should be done rarely.
Feel free to open an issue if you encounter any problems.

## Terms of Use
- You may **not** use Ruby to create distributable builds of SerializationTools; use a different method for that (you'd end up with a broken *Fetch Source* button anyway).  
- All modifications made to Ruby must be shared publicly with full source code to allow others to benefit from your changes.

## Meow
meow :3