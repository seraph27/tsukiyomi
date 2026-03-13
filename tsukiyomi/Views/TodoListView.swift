import SwiftUI
import SwiftData

struct TodoListView: View {
    @Query(sort: \TodoItem.createdAt) private var allTodos: [TodoItem]
    @Environment(\.modelContext) private var modelContext
    @State private var newTodoTitle = ""
    @State private var lastCompleted: TodoItem?

    private var activeTodos: [TodoItem] {
        allTodos.filter { !$0.completed }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("todo")
                    .font(.system(.caption, design: .monospaced).bold())
                    .foregroundColor(CatppuccinMocha.subtext0)
                Spacer()
                if lastCompleted != nil {
                    Button {
                        lastCompleted?.completed = false
                        lastCompleted = nil
                    } label: {
                        Text("undo")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.peach)
                    }
                    .buttonStyle(.plain)
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(activeTodos) { todo in
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                todo.completed = true
                                todo.completedAt = Date()
                                lastCompleted = todo
                            }
                        } label: {
                            HStack(alignment: .top, spacing: 8) {
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(CatppuccinMocha.overlay1, lineWidth: 1.2)
                                    .frame(width: 13, height: 13)
                                    .padding(.top, 2)

                                Text(todo.title)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(CatppuccinMocha.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            TextField("add task...", text: $newTodoTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(CatppuccinMocha.subtext0)
                .onSubmit { addTodo() }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(CatppuccinMocha.surface0.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }

    private func addTodo() {
        let title = newTodoTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        modelContext.insert(TodoItem(title: title))
        newTodoTitle = ""
    }
}
