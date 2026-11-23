import SwiftUI

/// 1画面に収まる勤怠カレンダー。
/// 月カレンダーの各日に出勤-退勤を小さく表示し、下半分に選択した日の時間を大きく出す。
struct CalendarView: View {
    @EnvironmentObject var store: WorkStore
    @State private var displayedMonth: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())
    @State private var showingEditor = false
    @State private var showingSettings = false

    private let cal = Calendar.current
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 6) {
                personBar
                monthHeader
                summaryBar
                weekdayHeader
                monthGrid
                Divider()
                selectedDayPanel
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .background(Color(red: 1.0, green: 0.93, blue: 0.96))
            .navigationTitle("こよみシフト")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                DayEditorView(day: selectedDay)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - 上部

    /// 「○○さんの出勤予定 ・ 店名」の行
    private var personBar: some View {
        let name = store.personName
        let shop = store.defaultStore
        let text: String = {
            switch (name.isEmpty, shop.isEmpty) {
            case (false, false): return "\(name)さんの出勤予定 ・ \(shop)"
            case (false, true): return "\(name)さんの出勤予定"
            case (true, false): return "出勤予定 ・ \(shop)"
            default: return "出勤予定"
            }
        }()
        return Text(text)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
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
        return Text("今月の勤務: \(formatDuration(s.minutes)) ・ 出勤 \(s.workDays)日")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { i in
                Text(weekdays[i])
                    .font(.caption.bold())
                    .foregroundStyle(i == 0 ? .red : (i == 6 ? .blue : .secondary))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - 月グリッド

    private var monthGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
            ForEach(Array(monthCells.enumerated()), id: \.offset) { _, cell in
                if let day = cell {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 52)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = cal.isDate(day, inSameDayAs: selectedDay)
        let isToday = cal.isDateInToday(day)
        let weekday = cal.component(.weekday, from: day)
        let dayColor: Color = (weekday == 1 || Holidays.isHoliday(day)) ? .red : (weekday == 7 ? .blue : .primary)
        let rec = store.record(on: day)
        return Button {
            selectedDay = day
        } label: {
            VStack(spacing: 1) {
                Text("\(cal.component(.day, from: day))")
                    .font(.system(size: 15, weight: isToday ? .bold : .regular))
                    .foregroundStyle(dayColor)
                if let rec = rec, rec.isDayOff {
                    Text("休み")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.red)
                } else if let rec = rec, let s = rec.start, let e = rec.end {
                    Text("\(formatTime(s))-\(formatTime(e))")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.pink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else if let rec = rec, let s = rec.start {
                    Text("\(formatTime(s))-")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.pink.opacity(0.22) : Color.white.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday ? Color.pink : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 選択した日のパネル

    private var selectedDayPanel: some View {
        let rec = store.record(on: selectedDay)
        return VStack(spacing: 8) {
            HStack {
                Text(dayTitle).font(.headline)
                Spacer()
                Button("時間を入れる") { showingEditor = true }
                    .font(.subheadline.bold())
            }
            if let rec = rec, rec.isDayOff {
                Text("休み")
                    .font(.title2.bold())
                    .foregroundStyle(.red)
            } else if let rec = rec, let s = rec.start, let e = rec.end {
                HStack(spacing: 10) {
                    timeBlock(label: "出勤", value: formatTime(s))
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                    timeBlock(label: "退勤", value: formatTime(e))
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("勤務").font(.caption).foregroundStyle(.secondary)
                        Text(formatDuration(rec.workedMinutes ?? 0)).font(.headline)
                    }
                }
            } else if let rec = rec, let s = rec.start {
                HStack {
                    timeBlock(label: "出勤", value: formatTime(s))
                    Spacer()
                    Text("退勤は未入力").foregroundStyle(.orange).font(.subheadline)
                }
            } else {
                Text("まだ入力がありません")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let rec = rec, !rec.afterWork.isEmpty {
                Text("退勤のあと: \(rec.afterWork)")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.pink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            let shop = store.storeName(on: selectedDay)
            if !shop.isEmpty {
                Text("店名: \(shop)")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let rec = rec, !rec.memo.isEmpty {
                Text(rec.memo)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.top, 4)
    }

    private func timeBlock(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(size: 30, weight: .bold, design: .rounded))
        }
    }

    private var dayTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M月d日 (E)"
        var title = f.string(from: selectedDay)
        if let holiday = Holidays.name(for: selectedDay) {
            title += " ・ \(holiday)"
        }
        return title
    }

    // MARK: - ヘルパー

    private var monthCells: [Date?] {
        guard let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth)),
              let range = cal.range(of: .day, in: .month, for: firstOfMonth) else {
            return []
        }
        let firstWeekday = cal.component(.weekday, from: firstOfMonth)
        var cells: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        for d in range {
            if let date = cal.date(byAdding: .day, value: d - 1, to: firstOfMonth) {
                cells.append(date)
            }
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    private func shiftMonth(_ delta: Int) {
        if let next = cal.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = next
        }
    }
}
