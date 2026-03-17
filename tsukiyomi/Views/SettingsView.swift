import SwiftUI

struct SettingsView: View {
    @Binding var currentView: AppView
    @State private var anthropicKey: String = UserDefaults.standard.string(forKey: "anthropicAPIKey") ?? ""
    @State private var sheetsURL: String = UserDefaults.standard.string(forKey: "sheetsWebhookURL") ?? ""
    @State private var saved = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    currentView = .dashboard
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10))
                        Text("back")
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .foregroundColor(CatppuccinMocha.blue)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("settings")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.text)

                Spacer()
                Spacer().frame(width: 40)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider().overlay(CatppuccinMocha.surface1)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Anthropic API Key
                    VStack(alignment: .leading, spacing: 4) {
                        Text("anthropic api key")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.mauve)

                        Text("for AI natural language input")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.overlay0)

                        SecureField("sk-ant-...", text: $anthropicKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11, design: .monospaced))
                    }

                    Divider().overlay(CatppuccinMocha.surface1)

                    // Google Sheets webhook
                    VStack(alignment: .leading, spacing: 4) {
                        Text("google sheets webhook url")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.green)

                        Text("auto-exports CP problems to your sheet")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.overlay0)

                        TextField("https://script.google.com/macros/s/...", text: $sheetsURL)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11, design: .monospaced))

                        Text("setup: in your sheet, go to Extensions > Apps Script, paste the script below, Deploy > Web app")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.overlay0)

                        // Show the script
                        VStack(alignment: .leading) {
                            Text(SheetsService.setupScript)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(CatppuccinMocha.subtext0)
                                .textSelection(.enabled)
                        }
                        .padding(8)
                        .background(CatppuccinMocha.crust, in: RoundedRectangle(cornerRadius: 6))
                    }

                    Divider().overlay(CatppuccinMocha.surface1)

                    // Save
                    HStack {
                        Button("save") {
                            UserDefaults.standard.set(anthropicKey, forKey: "anthropicAPIKey")
                            UserDefaults.standard.set(sheetsURL, forKey: "sheetsWebhookURL")
                            saved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
                        }
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.green)
                        .buttonStyle(.plain)

                        if saved {
                            Text("saved")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(CatppuccinMocha.green.opacity(0.6))
                        }
                    }
                }
                .padding(14)
            }
        }
        .frame(width: 420, height: 600)
        .background(CatppuccinMocha.base)
    }
}
