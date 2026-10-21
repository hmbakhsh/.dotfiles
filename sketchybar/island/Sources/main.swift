// Island: a Dynamic Island-style panel that grows out of the notch.
//
//   Island                 run the background agent (started by sketchybarrc)
//   Island spotify         open/close the Spotify now-playing panel
//   notch TITLE [BODY] …   show a message (notch is a symlink to Island)

import AppKit

let usage = """
    usage: notch TITLE [BODY] [options]
           notch --json '{"title": "…", "body": "…", …}'   (or --json - to read stdin)
           notch --dismiss                                 hide the message on screen now
           notch --inbox                                   open/close the inbox (history + waiting T3 threads)

    History is kept in ~/.local/state/notch/history.jsonl (one JSON entry per line).

    Shows a message that drops out of the notch. Messages queue; each hides
    after a few seconds, pauses while hovered, and is dismissed on click.

      -b, --body TEXT       second line, wraps to two lines
      -s, --source TEXT     small label top-right, e.g. "Claude · prism"
      -i, --icon NAME       SF Symbol, e.g. checkmark.circle.fill, exclamationmark.triangle.fill
      -a, --app NAME        use an app's icon instead, e.g. Claude, Slack
          --image PATH      use an image file instead
      -c, --color COLOR     icon tint: red orange yellow green mint teal blue indigo purple pink gray, or #RRGGBB
      -t, --time SECONDS    how long it stays (default 5)
          --sticky          stay until clicked
      -o, --open URL|PATH   open this on click
      -r, --run COMMAND     run this shell command on click
          --sound NAME      play a system sound, e.g. Glass, Ping, Submarine

    JSON keys match the long option names: title body source icon app image
    color seconds open run sound.
    """

let arguments = Array(CommandLine.arguments.dropFirst())

if URL(fileURLWithPath: CommandLine.arguments[0]).lastPathComponent == "notch" {
    Notify.run(arguments)
}
switch arguments.first {
case nil:
    break
case "notify":
    Notify.run(Array(arguments.dropFirst()))
case "spotify":
    Agent.post(spotifyToggleName)
    exit(0)
case "inbox":
    Agent.post(inboxName)
    exit(0)
case "-h", "--help":
    print(usage)
    exit(0)
default:
    FileHandle.standardError.write(Data("unknown command \(arguments[0])\n\n\(usage)\n".utf8))
    exit(64)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let island = Island()
app.run()
