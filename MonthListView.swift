import SwiftUI

/// 月表示: 1か月分の出勤予定を一覧で見る画面
struct MonthListView: View {
    @EnvironmentObject var store: WorkStore
    @State private var displayedMonth: Date = Calendar.current.startOfDay(for: Date())
    @State private var editingDay: Date?

    private let cal = Calendar.current

    var body: some View {
        NavigationStack {
            VStack(spacing: 6) {
                monthHeader
                summaryBar
                list
            }
            .padding(.horizontal, 12)
            .background(Color(red: 1.0, green: 0.93, blue: 0.96))
            .navigationTitle("月表示")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editingDay) { day in
                DayEditorView(day: day)
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(monthTitle).font(.title3.bold())
            Spacer()
            Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
        }
        .padding(.vertical, 2)
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年 M月"
        return f.string(from: displayedMonth)
    }

    private var summaryBar: some View {
        let y = cal.component(.year, from: displayedMonth)
        let m = cal.component(.month, from: displayedMonth)
        let s = store.monthSummary(year: y, month: m)
        let name = store.personName.isEmpty ? "" : "\(store.personName)さん ・ "
        return Text("\(name)勤務: \(formatDuration(s.minutes)) ・ 出勤 \(s.workDays)日")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
    }

    private var list: some View {
        List {
            ForEach(monthDays, id: \.self) { day in
                row(for: day)
                    .listRowBackground(Color.white.opacity(0.75))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func row(for day: Date) -> some View {
        let rec = store.record(on: day)
        let weekday = cal.component(.weekday, from: day)
        let dayColor: Color = (weekday == 1 || Holidays.isHoliday(day)) ? .red : (weekday == 7 ? .blue : .primary)
        return Button {
            editingDay = day
        } label: {
            HStack(spacing: 10) {
                VStack(spacing: 0) {
                    Text("\(cal.component(.day, from: day))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(dayColor)
                    Text(weekdayName(weekday))
                        .font(.caption2)
                        .foregroundStyle(dayColor)
                }
                .frame(width: 40)
                VStack(alignment: .leading, spacing: 2) {
                    if let rec = rec, rec.isDayOff {
                        Text("休み").font(.headline).foregroundStyle(.red)
                    } else if let rec = rec, let s = rec.start, let e = rec.end {
                        Text("\(formatTime(s)) - \(formatTime(e))")
                            .font(.headline)
                            .foregroundStyle(.pink)
                        Text(formatDuration(rec.workedMinutes ?? 0))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let rec = rec, let s = rec.start {
                        Text("\(formatTime(s)) - 未入力")
                            .font(.headline)
                            .foregroundStyle(.orange)
                    } else {
                        Text("未入力").foregroundStyle(.secondary)
                    }
                    if let rec = rec, !rec.afterWork.isEmpty {
                        Text("退勤のあと: \(rec.afterWork)")
                            .font(.caption)
                            .foregroundStyle(.pink)
                    }
                    let shop = store.storeName(on: day)
                    if !shop.isEmpty {
                        Text(shop).font(.caption).foregroundStyle(.secondary)
                    }
                    if let holiday = Holidays.name(for: day) {
                        Text(holiday).font(.caption2).foregroundStyle(.red)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func weekdayName(_ weekday: Int) -> String {
        ["日", "月", "火", "水", "木", "金", "土"][weekday - 1]
    }

    private var monthDays: [Date] {
        guard let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth)),
              let range = cal.range(of: .day, in: .month, for: firstOfMonth) else {
            return []
        }
        return range.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: firstOfMonth) }
    }

    private func shiftMonth(_ delta: Int) {
        if let next = cal.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = next
        }
    }
}

extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}
