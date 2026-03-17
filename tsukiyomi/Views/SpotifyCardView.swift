import SwiftUI
import Combine

struct SpotifyCardView: View {
    @StateObject private var spotify = SpotifyBridge()

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                if let art = spotify.artworkImage {
                    Image(nsImage: art)
                        .resizable()
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                } else {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(CatppuccinMocha.surface1)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: "music.note")
                                .font(.system(size: 14))
                                .foregroundColor(CatppuccinMocha.overlay0)
                        }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(spotify.trackName.isEmpty ? "not playing" : spotify.trackName)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(spotify.trackName.isEmpty ? CatppuccinMocha.overlay0 : CatppuccinMocha.text)
                        .lineLimit(1)

                    Text(spotify.artistName.isEmpty ? "spotify" : spotify.artistName)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.subtext0)
                        .lineLimit(1)
                }

                Spacer()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(CatppuccinMocha.surface1)
                        .frame(height: 3)

                    Capsule()
                        .fill(CatppuccinMocha.green)
                        .frame(width: geo.size.width * spotify.progress, height: 3)
                        .animation(.linear(duration: 0.9), value: spotify.progress)
                }
            }
            .frame(height: 3)

            HStack(spacing: 0) {
                Text(formatTime(spotify.position))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.overlay0)

                Spacer()

                HStack(spacing: 16) {
                    Button { spotify.previous() } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(CatppuccinMocha.subtext0)

                    Button { spotify.togglePlay() } label: {
                        Image(systemName: spotify.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(CatppuccinMocha.text)

                    Button { spotify.next() } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(CatppuccinMocha.subtext0)
                }

                Spacer()

                Text(formatTime(spotify.duration))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.overlay0)
            }
        }
        .padding(10)
        .background(CatppuccinMocha.surface0.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }

    private func formatTime(_ seconds: Double) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}

final class SpotifyBridge: ObservableObject {
    @Published var isPlaying = false
    @Published var trackName = ""
    @Published var artistName = ""
    @Published var position: Double = 0
    @Published var duration: Double = 0
    @Published var artworkImage: NSImage?

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(position / duration, 1.0)
    }

    private var timer: Timer?
    private var lastArtworkURL: String?

    init() {
        poll()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    deinit { timer?.invalidate() }

    func togglePlay() {
        osascript("tell application \"Spotify\" to playpause")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in self?.poll() }
    }

    func next() {
        osascript("tell application \"Spotify\" to next track")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.poll() }
    }

    func previous() {
        osascript("tell application \"Spotify\" to previous track")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.poll() }
    }

    private func poll() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.doPoll()
        }
    }

    private func doPoll() {
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client").first != nil

        guard running else {
            DispatchQueue.main.async {
                self.trackName = ""
                self.artistName = ""
                self.position = 0
                self.duration = 0
                self.isPlaying = false
                self.artworkImage = nil
                self.lastArtworkURL = nil
            }
            return
        }

        let script = """
        tell application "Spotify"
            if player state is stopped then return "|||||||||||stopped"
            set t to name of current track
            set a to artist of current track
            set p to player position
            set d to duration of current track
            set art to artwork url of current track
            set s to player state as string
            return t & "|||" & a & "|||" & (p as text) & "|||" & ((d / 1000) as text) & "|||" & art & "|||" & s
        end tell
        """

        guard let result = osascriptResult(script) else { return }
        let parts = result.components(separatedBy: "|||")
        guard parts.count >= 6 else { return }

        if parts[5] == "stopped" {
            DispatchQueue.main.async {
                self.trackName = ""
                self.artistName = ""
                self.position = 0
                self.duration = 0
                self.isPlaying = false
            }
            return
        }

        let artURL = parts[4]

        DispatchQueue.main.async {
            self.trackName = parts[0]
            self.artistName = parts[1]
            self.position = Double(parts[2]) ?? 0
            self.duration = Double(parts[3]) ?? 1
            self.isPlaying = parts[5] == "playing"
        }

        if artURL != lastArtworkURL {
            lastArtworkURL = artURL
            loadArtwork(from: artURL)
        }
    }

    private func loadArtwork(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = NSImage(data: data) else { return }
            DispatchQueue.main.async { self?.artworkImage = image }
        }.resume()
    }

    @discardableResult
    private func osascript(_ source: String) -> String? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        proc.arguments = ["-e", source]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        do {
            try proc.run()
            proc.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    private func osascriptResult(_ source: String) -> String? {
        osascript(source)
    }
}
