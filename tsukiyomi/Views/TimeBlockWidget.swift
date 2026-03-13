import SwiftUI
import SwiftData
import Combine

struct TimeBlockWidget: View {
    @Query(sort: \TimeBlock.startHour) private var timeBlocks: [TimeBlock]
    @State private var now = Date()

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var todayBlocks: [TimeBlock] {
        let weekday = Calendar.current.component(.weekday, from: now)
        return timeBlocks.filter { $0.isActiveOn(weekday: weekday) }
    }

    private var currentBlock: TimeBlock? {
        todayBlocks.first { $0.isActive(at: now) }
    }

    private var nextBlock: TimeBlock? {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let totalMinutes = hour * 60 + minute
        return todayBlocks.first { $0.startTotalMinutes > totalMinutes }
    }

    var body: some View {
        VStack(spacing: 6) {
            if let current = currentBlock {
                HStack {
                    Circle()
                        .fill(Color(hex: current.colorHex))
                        .frame(width: 8, height: 8)
                    Text("now")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.overlay1)
                    Text(current.name)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.text)
                    Spacer()
                    Text("\(current.formattedStartTime) – \(current.formattedEndTime)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.overlay1)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: current.colorHex).opacity(0.15))
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: current.colorHex))
                            .frame(width: geo.size.width * current.progress(at: now), height: 3)
                    }
                }
                .frame(height: 3)
            } else {
                HStack {
                    Circle()
                        .fill(CatppuccinMocha.surface2)
                        .frame(width: 8, height: 8)
                    Text("free time")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.overlay1)
                    Spacer()
                }
            }

            if let next = nextBlock {
                HStack(spacing: 4) {
                    Text(">")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.overlay0)
                    Text("next:")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.overlay0)
                    Text(next.name)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.subtext0)
                    Spacer()
                    Text(next.formattedStartTime)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.overlay0)
                }
            }
        }
        .padding(12)
        .background(CatppuccinMocha.surface0.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
        .onReceive(timer) { _ in
            now = Date()
        }
    }
}
