# Ruby
Ruby is an automatic update fetcher for [InfiltrationEngine-Custom-Missions](https://github.com/MoonstoneSkies/InfiltrationEngine-Custom-Missions). As long as a major change isn't made to the serializer, you will never have to reinstall anything serializer-related again.

Ruby automatically fetches **SerializationTools** and caches them efficiently on your device to avoid unnecessary HTTP requests.

## Usage
When you open the serialization tools, you’ll see a new button created by Ruby. The button has two states:
- **Check**, labeled `Ruby: Check` with a transparent-gray color. Pressing it will check if your serializer is up to date.
- **Fetch**, labeled `Ruby: Fetch` with a transparent-red color. Pressing it will update your serializer. The button gets put in this state when Ruby detects that your serializer is outdated.
Ruby automatically performs a background check every 10 minutes, assuming it has been used at least once in the currently opened Roblox Studio place, so performing manual checks isn't necessary.
Feel free to open an issue or contact me on discord (**@raylameows**) if you encounter any problems or have any questions.

## Terms of Use
- You may **not** use Ruby to create distributable builds of SerializationTools; use a different method for that (you'd end up with a broken *Fetch Source* button anyway).  
- All modifications made to Ruby must be shared publicly with full source code to allow others to benefit from your changes.

## Meow
meow :3