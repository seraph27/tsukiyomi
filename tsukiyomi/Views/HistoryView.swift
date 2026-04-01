import SwiftUI
import SwiftData

struct HistoryView: View {
    @Binding var currentView: AppView
    @Query(sort: \TrackerEntry.date, order: .reverse) private var trackerEntries: [TrackerEntry]
    @Query(sort: \TrackerTypeConfig.order) private var trackerTypes: [TrackerTypeConfig]
    @Query(sort: \TodoItem.completedAt, order: .reverse) private var allTodos: [TodoItem]
    @Query(sort: \CPProblem.completedAt, order: .reverse) private var allProblems: [CPProblem]
    @Query(sort: \PomodoroSession.date, order: .reverse) private var pomodoroSessions: [PomodoroSession]
    @Query(sort: \DailyNote.date, order: .reverse) private var allNotes: [DailyNote]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab = 0
    @State private var hoveredType: String?
    @State private var hoveredIndex: Int?

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
                tabButton("macros", index: 0)
                tabButton("tracker", index: 1)
                tabButton("weekly", index: 2)
                tabButton("todos", index: 3)
                tabButton("cp", index: 4)
                tabButton("notes", index: 5)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)

            Divider().overlay(CatppuccinMocha.surface1)

            // Content
            ScrollView {
                switch selectedTab {
                case 0: macrosHistory
                case 1: trackerHistory
                case 2: weeklySummary
                case 3: todoHistory
                case 4: cpHistory
                case 5: notesHistory
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
                .contentShape(Rectangle())
                .background(
                    selectedTab == index
                        ? CatppuccinMocha.blue.opacity(0.12)
                        : Color.clear
                    , in: RoundedRectangle(cornerRadius: 5)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Macros History

    private let macroTypes: [(name: String, unit: String, hex: String)] = [
        ("Calories", "kcal", "f5c2e7"),
        ("Protein", "g", "fab387"),
        ("Fat", "g", "f9e2af"),
        ("Carbs", "g", "a6e3a1"),
    ]

    private var macrosHistory: some View {
        VStack(spacing: 16) {
            // Today's summary card
            VStack(spacing: 6) {
                Text("today")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.overlay1)

                HStack(spacing: 0) {
                    ForEach(macroTypes, id: \.name) { macro in
                        let today = last14DaysGeneric(for: macro.name).last?.total ?? 0
                        let color = Color(hex: macro.hex)
                        VStack(spacing: 1) {
                            Text(TrackerEntry.formatValue(today, unit: macro.unit))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(color)
                            Text(macro.name.lowercased().prefix(4))
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(color.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(10)
            .background(CatppuccinMocha.surface0.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))

            // Charts for each macro
            ForEach(macroTypes, id: \.name) { macro in
                let color = Color(hex: macro.hex)
                let dailyData = last14DaysGeneric(for: macro.name)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(macro.name.lowercased())
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(color)
                        Spacer()
                        let avg = dailyData.reduce(0.0) { $0 + $1.total } / max(Double(dailyData.filter { $0.total > 0 }.count), 1)
                        Text("avg: \(TrackerEntry.formatValue(avg, unit: macro.unit))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.overlay1)
                    }

                    chartBars(dailyData: dailyData, color: color, unit: macro.unit, typeName: macro.name)
                }
                .padding(10)
                .background(CatppuccinMocha.surface0.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(14)
    }

    private func last14DaysGeneric(for typeName: String) -> [DayData] {
        let calendar = Calendar.current
        let today = calendar.logicalDayStart(for: .now)
        let shortFmt = DateFormatter()
        shortFmt.dateFormat = "dd"
        let fullFmt = DateFormatter()
        fullFmt.dateFormat = "M/d"

        return (0..<14).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let dayStart = calendar.logicalDayStart(for: day)
            let total = trackerEntries
                .filter { $0.type == typeName && calendar.logicalDayStart(for: $0.date) == dayStart }
                .reduce(0.0) { $0 + $1.effectiveValue }
            return DayData(label: shortFmt.string(from: day), fullLabel: fullFmt.string(from: day), total: total)
        }
    }

    private func chartBars(dailyData: [DayData], color: Color, unit: String, typeName: String) -> some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(dailyData.enumerated()), id: \.offset) { idx, day in
                let maxVal = max(dailyData.map(\.total).max() ?? 1, 1)
                let ratio = CGFloat(day.total / maxVal)
                let isHovered = hoveredType == typeName && hoveredIndex == idx

                VStack(spacing: 2) {
                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(day.total > 0 ? color.opacity(isHovered ? 0.85 : 0.6) : CatppuccinMocha.surface1)
                            .frame(height: max(ratio * 60, 2))

                        if isHovered && day.total > 0 {
                            Text(TrackerEntry.formatValue(day.total, unit: unit))
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(CatppuccinMocha.text)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(CatppuccinMocha.surface2, in: RoundedRectangle(cornerRadius: 3))
                                .offset(y: -20)
                        }
                    }

                    Text(isHovered ? day.fullLabel : day.label)
                        .font(.system(size: 7, weight: isHovered ? .bold : .regular, design: .monospaced))
                        .foregroundColor(isHovered ? CatppuccinMocha.text : CatppuccinMocha.overlay0)
                }
                .frame(maxWidth: .infinity)
                .onHover { over in
                    if over {
                        hoveredType = typeName
                        hoveredIndex = idx
                    } else if hoveredType == typeName && hoveredIndex == idx {
                        hoveredType = nil
                        hoveredIndex = nil
                    }
                }
            }
        }
        .frame(height: 76)
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
                        Text("today: \(TrackerEntry.formatValue(dailyData.last?.total ?? 0, unit: type.unit))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.overlay1)
                    }

                    // Bar chart
                    HStack(alignment: .bottom, spacing: 3) {
                        ForEach(Array(dailyData.enumerated()), id: \.offset) { idx, day in
                            let maxVal = max(dailyData.map(\.total).max() ?? 1, 1)
                            let ratio = CGFloat(day.total / maxVal)
                            let isHovered = hoveredType == type.name && hoveredIndex == idx

                            VStack(spacing: 2) {
                                ZStack(alignment: .top) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(day.total > 0 ? color.opacity(isHovered ? 0.85 : 0.6) : CatppuccinMocha.surface1)
                                        .frame(height: max(ratio * 60, 2))

                                    if isHovered && day.total > 0 {
                                        Text(TrackerEntry.formatValue(day.total, unit: type.unit))
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(CatppuccinMocha.text)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(CatppuccinMocha.surface2, in: RoundedRectangle(cornerRadius: 3))
                                            .offset(y: -20)
                                    }
                                }

                                Text(isHovered ? day.fullLabel : day.label)
                                    .font(.system(size: 7, weight: isHovered ? .bold : .regular, design: .monospaced))
                                    .foregroundColor(isHovered ? CatppuccinMocha.text : CatppuccinMocha.overlay0)
                            }
                            .frame(maxWidth: .infinity)
                            .onHover { over in
                                if over {
                                    hoveredType = type.name
                                    hoveredIndex = idx
                                } else if hoveredType == type.name && hoveredIndex == idx {
                                    hoveredType = nil
                                    hoveredIndex = nil
                                }
                            }
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
        let fullLabel: String
        let total: Double
    }

    private func last14Days(for typeName: String) -> [DayData] {
        let calendar = Calendar.current
        let today = calendar.logicalDayStart(for: .now)
        let shortFmt = DateFormatter()
        shortFmt.dateFormat = "dd"
        let fullFmt = DateFormatter()
        fullFmt.dateFormat = "M/d"

        return (0..<14).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let dayStart = calendar.logicalDayStart(for: day)
            let total = trackerEntries
                .filter { $0.type == typeName && calendar.logicalDayStart(for: $0.date) == dayStart }
                .reduce(0.0) { $0 + $1.effectiveValue }
            return DayData(label: shortFmt.string(from: day), fullLabel: fullFmt.string(from: day), total: total)
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
                            .frame(width: 22, height: 22)
                            .contentShape(Rectangle())
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
                            .frame(width: 22, height: 22)
                            .contentShape(Rectangle())
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

    // MARK: - Notes History

    private var notesHistory: some View {
        VStack(alignment: .leading, spacing: 4) {
            if allNotes.isEmpty {
                Text("no notes yet")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.overlay0)
                    .padding(14)
            } else {
                HStack {
                    Spacer()
                    Button {
                        for note in allNotes {
                            modelContext.delete(note)
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

            ForEach(allNotes) { note in
                HStack(alignment: .top, spacing: 8) {
                    Text(noteDateLabel(note.date))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.overlay1)
                        .frame(width: 50, alignment: .trailing)

                    Text(note.content)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.subtext0)

                    Spacer()

                    Button {
                        modelContext.delete(note)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8))
                            .foregroundColor(CatppuccinMocha.overlay0)
                            .frame(width: 22, height: 22)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 10)
    }

    private func noteDateLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "today" }
        if calendar.isDateInYesterday(date) { return "yday" }
        let fmt = DateFormatter()
        fmt.dateFormat = "M/d"
        return fmt.string(from: date)
    }

    // MARK: - Weekly Summary

    private var weeklySummary: some View {
        let calendar = Calendar.current
        let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart)!

        return VStack(spacing: 8) {
            // Column headers
            HStack {
                Text("")
                    .frame(width: 75, alignment: .leading)
                Spacer()
                Text("this week")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.overlay1)
                    .frame(width: 65, alignment: .trailing)
                Text("last week")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.overlay0)
                    .frame(width: 65, alignment: .trailing)
                Text("change")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.overlay0)
                    .frame(width: 65, alignment: .trailing)
            }
            .padding(.bottom, 2)

            // Macros
            ForEach(macroTypes, id: \.name) { macro in
                weeklyRow(name: macro.name, unit: macro.unit, color: Color(hex: macro.hex),
                          thisWeekStart: thisWeekStart, lastWeekStart: lastWeekStart)
            }

            Divider().overlay(CatppuccinMocha.surface1).padding(.vertical, 2)

            // Tracker types
            ForEach(trackerTypes) { type in
                weeklyRow(name: type.name, unit: type.unit, color: Color(hex: type.colorHex),
                          thisWeekStart: thisWeekStart, lastWeekStart: lastWeekStart)
            }

            Divider().overlay(CatppuccinMocha.surface1).padding(.vertical, 2)

            // Pomodoro sessions
            let thisPomoCount = weekPomoCount(from: thisWeekStart)
            let lastPomoCount = weekPomoCount(from: lastWeekStart)
            let pomoDiff = thisPomoCount - lastPomoCount

            HStack {
                Text("pomodoro")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.red)
                    .frame(width: 75, alignment: .leading)
                Spacer()
                Text("\(thisPomoCount)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.text)
                    .frame(width: 65, alignment: .trailing)
                Text("\(lastPomoCount)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.overlay1)
                    .frame(width: 65, alignment: .trailing)
                Text(pomoDiff >= 0 ? "+\(pomoDiff)" : "\(pomoDiff)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(pomoDiff > 0 ? CatppuccinMocha.green : pomoDiff < 0 ? CatppuccinMocha.red : CatppuccinMocha.overlay0)
                    .frame(width: 65, alignment: .trailing)
            }

            // Focus time
            let thisPomoMin = weekPomoMinutes(from: thisWeekStart)
            let lastPomoMin = weekPomoMinutes(from: lastWeekStart)
            let pomoMinDiff = thisPomoMin - lastPomoMin

            HStack {
                Text("focus")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.red.opacity(0.7))
                    .frame(width: 75, alignment: .leading)
                Spacer()
                Text("\(thisPomoMin)m")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.text)
                    .frame(width: 65, alignment: .trailing)
                Text("\(lastPomoMin)m")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.overlay1)
                    .frame(width: 65, alignment: .trailing)
                Text(pomoMinDiff >= 0 ? "+\(pomoMinDiff)m" : "\(pomoMinDiff)m")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(pomoMinDiff > 0 ? CatppuccinMocha.green : pomoMinDiff < 0 ? CatppuccinMocha.red : CatppuccinMocha.overlay0)
                    .frame(width: 65, alignment: .trailing)
            }

            Divider().overlay(CatppuccinMocha.surface1).padding(.vertical, 2)

            // Completed todos this week
            let thisWeekTodos = completedTodos.filter { ($0.completedAt ?? .distantPast) >= thisWeekStart }.count
            let lastWeekTodos = completedTodos.filter {
                let d = $0.completedAt ?? .distantPast
                return d >= lastWeekStart && d < thisWeekStart
            }.count
            let todoDiff = thisWeekTodos - lastWeekTodos

            HStack {
                Text("tasks")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.green)
                    .frame(width: 75, alignment: .leading)
                Spacer()
                Text("\(thisWeekTodos)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.text)
                    .frame(width: 65, alignment: .trailing)
                Text("\(lastWeekTodos)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.overlay1)
                    .frame(width: 65, alignment: .trailing)
                Text(todoDiff >= 0 ? "+\(todoDiff)" : "\(todoDiff)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(todoDiff > 0 ? CatppuccinMocha.green : todoDiff < 0 ? CatppuccinMocha.red : CatppuccinMocha.overlay0)
                    .frame(width: 65, alignment: .trailing)
            }

            // Completed CP problems this week
            let thisWeekCP = completedProblems.filter { ($0.completedAt ?? .distantPast) >= thisWeekStart }.count
            let lastWeekCP = completedProblems.filter {
                let d = $0.completedAt ?? .distantPast
                return d >= lastWeekStart && d < thisWeekStart
            }.count
            let cpDiff = thisWeekCP - lastWeekCP

            HStack {
                Text("problems")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.lavender)
                    .frame(width: 75, alignment: .leading)
                Spacer()
                Text("\(thisWeekCP)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.text)
                    .frame(width: 65, alignment: .trailing)
                Text("\(lastWeekCP)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.overlay1)
                    .frame(width: 65, alignment: .trailing)
                Text(cpDiff >= 0 ? "+\(cpDiff)" : "\(cpDiff)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(cpDiff > 0 ? CatppuccinMocha.green : cpDiff < 0 ? CatppuccinMocha.red : CatppuccinMocha.overlay0)
                    .frame(width: 65, alignment: .trailing)
            }
        }
        .padding(14)
    }

    private func weeklyRow(name: String, unit: String, color: Color, thisWeekStart: Date, lastWeekStart: Date) -> some View {
        let thisWeek = weekTotal(for: name, from: thisWeekStart)
        let lastWeek = weekTotal(for: name, from: lastWeekStart)
        let diff = thisWeek - lastWeek

        return HStack {
            Text(name.lowercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .frame(width: 75, alignment: .leading)
            Spacer()
            Text(TrackerEntry.formatValue(thisWeek, unit: unit))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(CatppuccinMocha.text)
                .frame(width: 65, alignment: .trailing)
            Text(TrackerEntry.formatValue(lastWeek, unit: unit))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(CatppuccinMocha.overlay1)
                .frame(width: 65, alignment: .trailing)
            Text(formatChange(diff, unit: unit))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(diff > 0 ? CatppuccinMocha.green : diff < 0 ? CatppuccinMocha.red : CatppuccinMocha.overlay0)
                .frame(width: 65, alignment: .trailing)
        }
    }

    private func weekTotal(for typeName: String, from weekStart: Date) -> Double {
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart)!
        return trackerEntries
            .filter { $0.type == typeName && $0.date >= weekStart && $0.date < weekEnd }
            .reduce(0.0) { $0 + $1.effectiveValue }
    }

    private func weekPomoCount(from weekStart: Date) -> Int {
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart)!
        return pomodoroSessions.filter { $0.date >= weekStart && $0.date < weekEnd }.count
    }

    private func weekPomoMinutes(from weekStart: Date) -> Int {
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart)!
        return pomodoroSessions
            .filter { $0.date >= weekStart && $0.date < weekEnd }
            .reduce(0) { $0 + $1.duration }
    }

    private func formatChange(_ diff: Double, unit: String) -> String {
        if diff == 0 { return "—" }
        let prefix = diff > 0 ? "+" : "-"
        let formatted = TrackerEntry.formatValue(abs(diff), unit: unit)
        return "\(prefix)\(formatted)"
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
