import SwiftUI
import SwiftData

struct HistoryView: View {
    @Binding var currentView: AppView
    @Query(sort: \TrackerEntry.date, order: .reverse) private var trackerEntries: [TrackerEntry]
    @Query(sort: \TrackerTypeConfig.order) private var trackerTypes: [TrackerTypeConfig]
    @Query(sort: \TodoItem.completedAt, order: .reverse) private var allTodos: [TodoItem]
    @Query(sort: \CPProblem.completedAt, order: .reverse) private var allProblems: [CPProblem]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab = 0

    private var completedTodos: [TodoItem] {
        allTodos.filter { $0.completed }
    }

    private var completedProblems: [CPProblem] {
        allProblems.filter { $0.completed }
    }

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

                Text("history")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.text)

                Spacer()
                Spacer().frame(width: 40)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            // Tabs
            HStack(spacing: 2) {
                tabButton("tracker", index: 0)
                tabButton("todos", index: 1)
                tabButton("competitive programming", index: 2)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)

            Divider().overlay(CatppuccinMocha.surface1)

            // Content
            ScrollView {
                switch selectedTab {
                case 0: trackerHistory
                case 1: todoHistory
                case 2: cpHistory
                default: EmptyView()
                }
            }
        }
        .frame(width: 420, height: 600)
        .background(CatppuccinMocha.base)
    }

    private func tabButton(_ label: String, index: Int) -> some View {
        Button {
            selectedTab = index
        } label: {
            Text(label)
                .font(.system(size: 11, weight: selectedTab == index ? .bold : .regular, design: .monospaced))
                .foregroundColor(selectedTab == index ? CatppuccinMocha.blue : CatppuccinMocha.overlay1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(
                    selectedTab == index
                        ? CatppuccinMocha.blue.opacity(0.12)
                        : Color.clear
                    , in: RoundedRectangle(cornerRadius: 5)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tracker History

    private var trackerHistory: some View {
        VStack(spacing: 16) {
            ForEach(trackerTypes) { type in
                let color = Color(hex: type.colorHex)
                let dailyData = last14Days(for: type.name)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(type.name.lowercased())
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(color)
                        Spacer()
                        Text("today: \(dailyData.last?.count ?? 0)\(type.unit)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.overlay1)
                    }

                    // Bar chart
                    HStack(alignment: .bottom, spacing: 3) {
                        ForEach(Array(dailyData.enumerated()), id: \.offset) { _, day in
                            let maxVal = max(dailyData.map(\.count).max() ?? 1, 1)
                            let ratio = CGFloat(day.count) / CGFloat(maxVal)

                            VStack(spacing: 2) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(day.count > 0 ? color.opacity(0.6) : CatppuccinMocha.surface1)
                                    .frame(height: max(ratio * 60, 2))

                                Text(day.label)
                                    .font(.system(size: 7, design: .monospaced))
                                    .foregroundColor(CatppuccinMocha.overlay0)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 76)
                }
                .padding(10)
                .background(CatppuccinMocha.surface0.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(14)
    }

    private struct DayData {
        let label: String
        let count: Int
    }

    private func last14Days(for typeName: String) -> [DayData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"

        return (0..<14).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let dayStart = calendar.startOfDay(for: day)
            let count = trackerEntries
                .filter { $0.type == typeName && calendar.startOfDay(for: $0.date) == dayStart }
                .reduce(0) { $0 + $1.count }
            return DayData(label: formatter.string(from: day), count: count)
        }
    }

    // MARK: - Todo History

    private var todoHistory: some View {
        VStack(alignment: .leading, spacing: 4) {
            if completedTodos.isEmpty {
                Text("no completed tasks yet")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.overlay0)
                    .padding(14)
            } else {
                HStack {
                    Spacer()
                    Button {
                        for todo in completedTodos {
                            modelContext.delete(todo)
                        }
                    } label: {
                        Text("clear all")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.top, 6)
            }

            ForEach(completedTodos.prefix(30)) { todo in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9))
                        .foregroundColor(CatppuccinMocha.green)

                    Text(todo.title)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.subtext0)
                        .lineLimit(1)

                    Spacer()

                    Button {
                        modelContext.delete(todo)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8))
                            .foregroundColor(CatppuccinMocha.overlay0)
                    }
                    .buttonStyle(.plain)

                    if let date = todo.completedAt {
                        Text(relativeDate(date))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.overlay0)
                            .frame(width: 60, alignment: .trailing)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 3)
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - CP History

    private var cpHistory: some View {
        VStack(alignment: .leading, spacing: 4) {
            if completedProblems.isEmpty {
                Text("no completed problems yet")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.overlay0)
                    .padding(14)
            } else {
                HStack {
                    Spacer()
                    Button {
                        for problem in completedProblems {
                            modelContext.delete(problem)
                        }
                    } label: {
                        Text("clear all")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.top, 6)
            }

            ForEach(completedProblems.prefix(30)) { problem in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9))
                        .foregroundColor(CatppuccinMocha.green)

                    if !problem.url.isEmpty, let url = URL(string: problem.url) {
                        Button {
                            NSWorkspace.shared.open(url)
                        } label: {
                            Text(problem.title)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(CatppuccinMocha.blue.opacity(0.7))
                                .lineLimit(1)
                                .underline(color: CatppuccinMocha.blue.opacity(0.2))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text(problem.title)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.subtext0)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        modelContext.delete(problem)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8))
                            .foregroundColor(CatppuccinMocha.overlay0)
                    }
                    .buttonStyle(.plain)

                    if let date = problem.completedAt {
                        Text(relativeDate(date))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.overlay0)
                            .frame(width: 60, alignment: .trailing)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 3)
            }
        }
        .padding(.vertical, 10)
    }

    private func relativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "today" }
        if calendar.isDateInYesterday(date) { return "yesterday" }
        let days = calendar.dateComponents([.day], from: date, to: .now).day ?? 0
        if days < 7 { return "\(days)d ago" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
