import SwiftUI
import SwiftData

struct DailyNoteView: View {
    @Query(sort: \DailyNote.date, order: .reverse) private var notes: [DailyNote]
    @Environment(\.modelContext) private var modelContext
    @State private var text = ""
    @FocusState private var focused: Bool

    private var todayNote: DailyNote? {
        let today = Calendar.current.startOfDay(for: .now)
        return notes.first { Calendar.current.startOfDay(for: $0.date) == today }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("notes")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(CatppuccinMocha.overlay0)

            TextEditor(text: $text)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(CatppuccinMocha.subtext0)
                .scrollContentBackground(.hidden)
                .focused($focused)
                .frame(maxHeight: .infinity)
                .onChange(of: text) { _, _ in
                    save()
                }
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("note...")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.overlay0)
                            .allowsHitTesting(false)
                    }
                }
        }
        .padding(8)
        .background(CatppuccinMocha.surface0.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
        .onAppear {
            text = todayNote?.content ?? ""
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if let note = todayNote {
            note.content = trimmed
        } else if !trimmed.isEmpty {
            modelContext.insert(DailyNote(content: trimmed))
        }
    }
}
