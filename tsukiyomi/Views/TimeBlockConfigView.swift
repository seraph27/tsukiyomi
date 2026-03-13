import SwiftUI
import SwiftData

struct TimeBlockConfigView: View {
    @Binding var currentView: AppView
    @Query(sort: \TimeBlock.startHour) private var timeBlocks: [TimeBlock]
    @Environment(\.modelContext) private var modelContext

    let hourHeight: CGFloat = 48
    let gutterWidth: CGFloat = 34

    @State private var selectedDay: Int = Calendar.current.component(.weekday, from: .now)
    @State private var showForm = false
    @State private var editingBlock: TimeBlock?
    @State private var formName = ""
    @State private var formCategory = "work"
    @State private var formStart = "09:00"
    @State private var formEnd = "10:00"
    @State private var formDays: Set<Int> = []

    @State private var draggingID: PersistentIdentifier?
    @State private var dragOffset: CGFloat = 0

    private let categories = ["work", "gaming", "cp", "workout", "break", "study", "sleep", "eat", "other"]
    private let dayLabels = [(7, "SAT"), (2, "MON"), (3, "TUE"), (4, "WED"), (5, "THU"), (6, "FRI"), (1, "SUN")]

    private var blocksForSelectedDay: [TimeBlock] {
        timeBlocks.filter { $0.isActiveOn(weekday: selectedDay) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            daySelector
            Divider().overlay(CatppuccinMocha.surface1)
            timeline

            if showForm {
                Divider().overlay(CatppuccinMocha.surface1)
                formView
            }
        }
        .frame(width: 420, height: 600)
        .background(CatppuccinMocha.base)
    }

    // MARK: - Header

    private var header: some View {
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

            Text("schedule")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(CatppuccinMocha.text)

            Spacer()

            Button {
                resetForm()
                showForm = true
            } label: {
                Text("+ add")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.green)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Day Selector

    private var daySelector: some View {
        HStack(spacing: 4) {
            ForEach(dayLabels, id: \.0) { day, label in
                Button {
                    selectedDay = day
                } label: {
                    Text(label)
                        .font(.system(size: 11, weight: selectedDay == day ? .bold : .regular, design: .monospaced))
                        .foregroundColor(selectedDay == day ? CatppuccinMocha.blue : CatppuccinMocha.overlay1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            selectedDay == day
                                ? CatppuccinMocha.blue.opacity(0.12)
                                : Color.clear
                            , in: RoundedRectangle(cornerRadius: 5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    // MARK: - Timeline

    private var timeline: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    hourGrid

                    ForEach(blocksForSelectedDay) { block in
                        let yPos = CGFloat(block.startTotalMinutes) / 60.0 * hourHeight
                        let blockH = CGFloat(block.endTotalMinutes - block.startTotalMinutes) / 60.0 * hourHeight
                        let isDragging = draggingID == block.persistentModelID

                        blockCell(block, height: max(blockH, 22))
                            .padding(.leading, gutterWidth + 6)
                            .padding(.trailing, 6)
                            .offset(y: yPos + (isDragging ? dragOffset : 0))
                            .zIndex(isDragging ? 10 : 1)
                            .onTapGesture { startEditing(block) }
                            .gesture(
                                DragGesture(minimumDistance: 5)
                                    .onChanged { value in
                                        draggingID = block.persistentModelID
                                        dragOffset = value.translation.height
                                    }
                                    .onEnded { value in
                                        moveBlock(block, by: value.translation.height)
                                        draggingID = nil
                                        dragOffset = 0
                                    }
                            )
                    }

                    currentTimeLine
                }
                .frame(height: 24 * hourHeight)
            }
            .onAppear {
                let h = Calendar.current.component(.hour, from: .now)
                proxy.scrollTo(max(0, h - 3), anchor: .top)
            }
        }
    }

    private var hourGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                HStack(alignment: .top, spacing: 0) {
                    Text(String(format: "%02d", hour))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.overlay0)
                        .frame(width: gutterWidth, alignment: .trailing)
                        .padding(.trailing, 4)

                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(CatppuccinMocha.surface1.opacity(0.4))
                            .frame(height: 0.5)
                        Spacer()
                    }
                }
                .frame(height: hourHeight)
                .id(hour)
                .contentShape(Rectangle())
                .onTapGesture { startAddingAt(hour: hour) }
            }
        }
    }

    private func blockCell(_ block: TimeBlock, height: CGFloat) -> some View {
        let color = Color(hex: block.colorHex)
        let isEditing = editingBlock?.persistentModelID == block.persistentModelID
        return VStack(alignment: .leading, spacing: 1) {
            Text(block.name)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(CatppuccinMocha.text)
            if height > 30 {
                HStack(spacing: 4) {
                    Text(block.category)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(color.opacity(0.7))
                    if !block.isEveryDay {
                        Text(block.daysLabel)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.overlay0)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(isEditing ? 0.25 : 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(color.opacity(isEditing ? 0.6 : 0.25), lineWidth: isEditing ? 1.5 : 1)
        )
    }

    private var currentTimeLine: some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())
        let y = (CGFloat(hour) + CGFloat(minute) / 60.0) * hourHeight
        let isToday = selectedDay == calendar.component(.weekday, from: Date())

        return Group {
            if isToday {
                HStack(spacing: 0) {
                    Spacer().frame(width: gutterWidth - 3)
                    Circle()
                        .fill(CatppuccinMocha.red)
                        .frame(width: 7, height: 7)
                    Rectangle()
                        .fill(CatppuccinMocha.red)
                        .frame(height: 1)
                }
                .offset(y: y)
            }
        }
    }

    // MARK: - Form

    private var formView: some View {
        VStack(spacing: 8) {
            TextField("block name", text: $formName)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, design: .monospaced))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(categories, id: \.self) { cat in
                        let hex = CatppuccinMocha.timeBlockCategoryColors[cat] ?? "89b4fa"
                        Button {
                            formCategory = cat
                        } label: {
                            Text(cat)
                                .font(.system(size: 11, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    formCategory == cat
                                        ? Color(hex: hex).opacity(0.25)
                                        : CatppuccinMocha.surface1
                                    , in: Capsule()
                                )
                                .foregroundColor(formCategory == cat ? Color(hex: hex) : CatppuccinMocha.overlay1)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Day toggles
            HStack(spacing: 3) {
                Text("days")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.overlay0)

                ForEach(dayLabels, id: \.0) { day, label in
                    Button {
                        if formDays.contains(day) {
                            formDays.remove(day)
                        } else {
                            formDays.insert(day)
                        }
                    } label: {
                        Text(label)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(formDays.isEmpty || formDays.contains(day) ? CatppuccinMocha.text : CatppuccinMocha.overlay0)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(
                                formDays.contains(day)
                                    ? CatppuccinMocha.blue.opacity(0.2)
                                    : Color.clear
                                , in: RoundedRectangle(cornerRadius: 3)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if !formDays.isEmpty {
                    Button {
                        formDays = []
                    } label: {
                        Text("all")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.overlay1)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Time inputs as text fields
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("start")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.overlay0)
                    TextField("09:00", text: $formStart)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(width: 60)
                }
                HStack(spacing: 4) {
                    Text("end")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.overlay0)
                    TextField("10:00", text: $formEnd)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(width: 60)
                }
                Spacer()
            }

            HStack(spacing: 12) {
                Button(editingBlock != nil ? "update" : "add") {
                    saveBlock()
                }
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(CatppuccinMocha.green)
                .buttonStyle(.plain)

                if editingBlock != nil {
                    Button("delete") {
                        if let block = editingBlock {
                            modelContext.delete(block)
                        }
                        showForm = false
                        editingBlock = nil
                    }
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.red)
                    .buttonStyle(.plain)
                }

                Button("cancel") {
                    showForm = false
                    editingBlock = nil
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(CatppuccinMocha.overlay1)
                .buttonStyle(.plain)
            }
        }
        .padding(12)
    }

    // MARK: - Actions

    private func resetForm() {
        formName = ""
        formCategory = "work"
        formStart = "09:00"
        formEnd = "10:00"
        formDays = []
        editingBlock = nil
    }

    private func startAddingAt(hour: Int) {
        formName = ""
        formCategory = "work"
        formStart = String(format: "%02d:00", hour)
        formEnd = String(format: "%02d:00", min(hour + 1, 23))
        formDays = []
        editingBlock = nil
        showForm = true
    }

    private func startEditing(_ block: TimeBlock) {
        formName = block.name
        formCategory = block.category
        formStart = String(format: "%02d:%02d", block.startHour, block.startMinute)
        formEnd = String(format: "%02d:%02d", block.endHour, block.endMinute)
        formDays = block.activeDaySet
        editingBlock = block
        showForm = true
    }

    private func moveBlock(_ block: TimeBlock, by offsetY: CGFloat) {
        let minuteChange = Int(offsetY / hourHeight * 60)
        let snapped = (minuteChange / 15) * 15
        let duration = block.endTotalMinutes - block.startTotalMinutes

        var newStart = block.startTotalMinutes + snapped
        newStart = max(0, min(24 * 60 - duration, newStart))
        let snappedStart = (newStart / 15) * 15

        block.startHour = snappedStart / 60
        block.startMinute = snappedStart % 60
        block.endHour = (snappedStart + duration) / 60
        block.endMinute = (snappedStart + duration) % 60
    }

    private static func parseTime(_ str: String) -> (hour: Int, minute: Int)? {
        let parts = str.trimmingCharacters(in: .whitespaces).split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]), let m = Int(parts[1]),
              h >= 0, h < 24, m >= 0, m < 60 else { return nil }
        return (h, m)
    }

    private func saveBlock() {
        let name = formName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        guard let start = Self.parseTime(formStart),
              let end = Self.parseTime(formEnd) else { return }
        let color = CatppuccinMocha.timeBlockCategoryColors[formCategory] ?? "89b4fa"
        let daysStr = formDays.isEmpty ? "" : formDays.sorted().map(String.init).joined(separator: ",")

        if let block = editingBlock {
            block.name = name
            block.category = formCategory
            block.startHour = start.hour
            block.startMinute = start.minute
            block.endHour = end.hour
            block.endMinute = end.minute
            block.colorHex = color
            block.daysActive = daysStr
        } else {
            modelContext.insert(TimeBlock(
                name: name,
                category: formCategory,
                startHour: start.hour,
                startMinute: start.minute,
                endHour: end.hour,
                endMinute: end.minute,
                colorHex: color,
                daysActive: daysStr
            ))
        }
        showForm = false
        editingBlock = nil
    }
}
