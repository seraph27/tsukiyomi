import SwiftUI
import SwiftData

struct AIInputView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var input = ""
    @State private var status = ""
    @State private var isLoading = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("ai")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.mauve)
                Spacer()
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 12, height: 12)
                }
            }

            TextEditor(text: $input)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(CatppuccinMocha.text)
                .scrollContentBackground(.hidden)
                .focused($focused)
                .disabled(isLoading)
                .frame(minHeight: 40, maxHeight: 60)
                .overlay(alignment: .topLeading) {
                    if input.isEmpty {
                        Text("did 30 pushups, cf round 781 A-D...")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.overlay0)
                            .allowsHitTesting(false)
                    }
                }
                .onKeyPress(.return) { submit(); return .handled }

            if !status.isEmpty {
                Text(status)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(status.hasPrefix("err") ? CatppuccinMocha.red : CatppuccinMocha.green)
                    .lineLimit(5)
                    .textSelection(.enabled)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(CatppuccinMocha.surface0.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
    }

    private func submit() {
        let text = input.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        guard let apiKey = UserDefaults.standard.string(forKey: "anthropicAPIKey"), !apiKey.isEmpty else {
            status = "err: set anthropic api key in settings"
            return
        }

        isLoading = true
        status = ""

        Task {
            do {
                let parsed = try await AIService.parse(input: text, apiKey: apiKey)

                // Add tracker entries locally
                for t in parsed.tracker {
                    modelContext.insert(TrackerEntry(type: t.type, amount: t.amount))
                }

                // Problems & contests go to Google Sheet only (not local backlog)
                if !parsed.problems.isEmpty {
                    try? await SheetsService.appendProblems(parsed.problems)
                }
                if let contests = parsed.contests, !contests.isEmpty {
                    try? await SheetsService.appendContests(contests)
                }

                status = parsed.summary
                input = ""
            } catch {
                status = "err: \(error.localizedDescription)"
            }

            isLoading = false
        }
    }
}
