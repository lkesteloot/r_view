// Pulling this out of main.ts so it can be tested without booting Electron.

// The filenames on the command line. When packaged, argv is the app binary
// followed by the arguments; in development, electron is followed by the script.
// Anything starting with a dash is an option, either ours or one of Chromium's,
// or the "-psn_0_123" that the Finder passes when you double-click the app.
export function filenamesFromArgv(argv: readonly string[], isPackaged: boolean): string[] {
    return argv.slice(isPackaged ? 1 : 2).filter((arg) => !arg.startsWith("-"));
}
