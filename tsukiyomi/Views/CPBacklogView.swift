import SwiftUI
import SwiftData

struct CPBacklogView: View {
    @Query(sort: \CPProblem.createdAt) private var allProblems: [CPProblem]
    @Environment(\.modelContext) private var modelContext
    @State private var newTitle = ""
    @State private var newURL = ""
    @State private var lastCompleted: CPProblem?
    @FocusState private var titleFocused: Bool

    private var activeProblems: [CPProblem] {
        allProblems.filter { !$0.completed }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("competitive programming")
                    .font(.system(.caption, design: .monospaced).bold())
                    .foregroundColor(CatppuccinMocha.subtext0)
                Spacer()
                if lastCompleted != nil {
                    Button {
                        lastCompleted?.completed = false
                        lastCompleted?.completedAt = nil
                        lastCompleted = nil
                    } label: {
                        Text("undo")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.peach)
                    }
                    .buttonStyle(.plain)
                }
            }

            ForEach(activeProblems.prefix(6)) { problem in
                HStack(spacing: 8) {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            problem.completed = true
                            problem.completedAt = Date()
                            lastCompleted = problem
                        }
                    } label: {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(CatppuccinMocha.overlay1, lineWidth: 1.2)
                            .frame(width: 13, height: 13)
                            .contentShape(Rectangle().inset(by: -4))
                    }
                    .buttonStyle(.plain)

                    if !problem.url.isEmpty, let url = URL(string: problem.url) {
                        Button {
                            NSWorkspace.shared.open(url)
                        } label: {
                            HStack(spacing: 4) {
                                Text(problem.title)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(CatppuccinMocha.blue)
                                    .lineLimit(1)
                                    .underline(color: CatppuccinMocha.blue.opacity(0.3))
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 8))
                                    .foregroundColor(CatppuccinMocha.blue.opacity(0.5))
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text(problem.title)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.text)
                            .lineLimit(1)
                    }

                    Spacer()
                }
            }

            if activeProblems.count > 6 {
                Text("+\(activeProblems.count - 6) more")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.overlay0)
            }

            HStack(spacing: 6) {
                TextField("title", text: $newTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.subtext0)
                    .focused($titleFocused)
                    .onSubmit { addProblem() }

                Rectangle()
                    .fill(CatppuccinMocha.surface2)
                    .frame(width: 1, height: 14)

                TextField("url", text: $newURL)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.overlay1)
                    .onSubmit { addProblem() }
            }
        }
        .padding(12)
        .background(CatppuccinMocha.surface0.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }

    private func addProblem() {
        let title = newTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        modelContext.insert(CPProblem(title: title, url: newURL.trimmingCharacters(in: .whitespaces)))
        newTitle = ""
        newURL = ""
        titleFocused = true
    }
}
