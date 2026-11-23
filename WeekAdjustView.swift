import SwiftUI

/// 週の調整: 1タップで1週間分の出勤・休みをまとめて入れる画面
struct WeekAdjustView: View {
    @EnvironmentObject var store: WorkStore
    @State private var weekStart: Date = WeekAdjustView.sundayOfWeek(Date())
    @State private var startTime: Date = WeekAdjustView.templateTime(hour: 9)
    @State private var endTime: Date = WeekAdjustView.templateTime(hour: 18)
    @State private var editingDay: Date?
    @State private var selectedWeekdays: Set<Int> = [2, 3, 4, 5, 6]  // 平日が初期値
    @State private var weekdayScopeMonth = true   // true: 今月まるごと / false: 表示中の週だけ
    @State private var weekdayOff = false         // true: 休みで入れる

    private let cal = Calendar.current
    private let weekdayNames = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    weekHeader
                    weekStrip
                    templateCard
                    applyButtons
                    weekdayBulkCard
                    Text("ボタン1つで、その週の全日 (または平日) にまとめて反映されます。上の日付をタップすると、その日だけ個別に入力もできます。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
            }
            .background(Color(red: 1.0, green: 0.93, blue: 0.96))
            .navigationTitle("週の調整")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editingDay) { day in
                DayEditorView(day: day)
            }
        }
    }

    // MARK: - 週の表示

    private var weekHeader: some View {
        HStack {
            Button { shiftWeek(-1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(weekTitle).font(.title3.bold())
            Spacer()
            Button { shiftWeek(1) } label: { Image(systemName: "chevron.right") }
        }
    }

    private var weekTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M月d日"
        let end = cal.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "\(f.string(from: weekStart)) - \(f.string(from: end)) の週"
    }

    private var weekStrip: some View {
        HStack(spacing: 6) {
            ForEach(weekDays, id: \.self) { day in
                let rec = store.record(on: day)
                let weekday = cal.component(.weekday, from: day)
                Button {
                    editingDay = day
                } label: {
                VStack(spacing: 3) {
                    Text(weekdayNames[weekday - 1])
                        .font(.caption2.bold())
                        .foregroundStyle(weekday == 1 ? .red : (weekday == 7 ? .blue : .secondary))
                    Text("\(cal.component(.day, from: day))")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    if let rec = rec, rec.isDayOff {
                        Text("休み").font(.system(size: 9, weight: .medium)).foregroundStyle(.red)
                    } else if let rec = rec, let s = rec.start, let e = rec.end {
                        Text("\(formatTime(s))\n\(formatTime(e))")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.pink)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("未").font(.system(size: 9)).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 時間テンプレート

    private var templateCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("入れる時間").font(.headline)
            HStack {
                DatePicker("出勤", selection: $startTime, displayedComponents: .hourAndMinute)
                DatePicker("退勤", selection: $endTime, displayedComponents: .hourAndMinute)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 1タップ適用ボタン

    private var applyButtons: some View {
        VStack(spacing: 10) {
            applyButton(title: "平日はこの時間・土日は休み", style: .primary) {
                apply(weekdaysOnly: true, weekendsOff: true)
            }
            applyButton(title: "平日だけこの時間を入れる", style: .normal) {
                apply(weekdaysOnly: true, weekendsOff: false)
            }
            applyButton(title: "1週間すべてこの時間を入れる", style: .normal) {
                apply(weekdaysOnly: false, weekendsOff: false)
            }
            applyButton(title: "1週間すべて休みにする", style: .off) {
                applyAllOff()
            }
        }
    }

    private enum ButtonStyle { case primary, normal, off }

    private func applyButton(title: String, style: ButtonStyle, action: @escaping () -> Void) -> some View {
        let bg: Color = style == .primary ? .pink : .white
        let fg: Color = style == .primary ? .white : (style == .off ? .red : .pink)
        return Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(bg)
                .foregroundStyle(fg)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.pink.opacity(0.4), lineWidth: style == .primary ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 曜日指定の一括入力

    private var weekdayBulkCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("曜日指定で一括入力").font(.headline)
            Text("入れたい曜日を選んでください (例: 月・水・金)")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(1...7, id: \.self) { weekday in
                    Button {
                        if selectedWeekdays.contains(weekday) {
                            selectedWeekdays.remove(weekday)
                        } else {
                            selectedWeekdays.insert(weekday)
                        }
                    } label: {
                        Text(weekdayNames[weekday - 1])
                            .font(.headline)
                            .frame(width: 40, height: 40)
                            .background(selectedWeekdays.contains(weekday) ? Color.pink : Color.pink.opacity(0.08))
                            .foregroundStyle(selectedWeekdays.contains(weekday) ? .white : (weekday == 1 ? .red : (weekday == 7 ? .blue : .primary)))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            Picker("範囲", selection: $weekdayScopeMonth) {
                Text("表示中の週").tag(false)
                Text("今月まるごと").tag(true)
            }
            .pickerStyle(.segmented)
            HStack(spacing: 10) {
                modeButton(title: "この時間で出勤", selected: !weekdayOff) { weekdayOff = false }
                modeButton(title: "休みにする", selected: weekdayOff) { weekdayOff = true }
            }
            Button {
                applyWeekdays()
            } label: {
                Text("選んだ曜日にまとめて入れる")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(selectedWeekdays.isEmpty ? Color.gray.opacity(0.4) : Color.pink)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(selectedWeekdays.isEmpty)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func modeButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(selected ? Color.pink : Color.white)
                .foregroundStyle(selected ? .white : .pink)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.pink.opacity(0.5), lineWidth: selected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func applyWeekdays() {
        let targets: [Date]
        if weekdayScopeMonth {
            targets = daysInMonth(of: weekStart)
        } else {
            targets = weekDays
        }
        for day in targets where selectedWeekdays.contains(cal.component(.weekday, from: day)) {
            setDay(day, off: weekdayOff)
        }
    }

    private func daysInMonth(of date: Date) -> [Date] {
        guard let first = cal.date(from: cal.dateComponents([.year, .month], from: date)),
              let range = cal.range(of: .day, in: .month, for: first) else {
            return []
        }
        return range.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: first) }
    }

    // MARK: - ロジック

    private var weekDays: [Date] {
        (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private func apply(weekdaysOnly: Bool, weekendsOff: Bool) {
        for day in weekDays {
            let weekday = cal.component(.weekday, from: day)
            let isWeekend = weekday == 1 || weekday == 7
            if isWeekend && weekendsOff {
                setDay(day, off: true)
            } else if isWeekend && weekdaysOnly {
                continue
            } else {
                setDay(day, off: false)
            }
        }
    }

    private func applyAllOff() {
        for day in weekDays {
            setDay(day, off: true)
        }
    }

    private func setDay(_ day: Date, off: Bool) {
        var rec = store.record(on: day) ?? WorkDay(dayKey: WorkStore.key(for: day))
        rec.isDayOff = off
        if off {
            rec.start = nil
            rec.end = nil
        } else {
            rec.start = combine(day: day, time: startTime)
            rec.end = combine(day: day, time: endTime)
        }
        store.set(rec)
    }

    private func combine(day: Date, time: Date) -> Date {
        let h = cal.component(.hour, from: time)
        let m = cal.component(.minute, from: time)
        return cal.date(bySettingHour: h, minute: m, second: 0, of: day) ?? day
    }

    private func shiftWeek(_ delta: Int) {
        if let next = cal.date(byAdding: .day, value: 7 * delta, to: weekStart) {
            weekStart = next
        }
    }

    static func sundayOfWeek(_ date: Date) -> Date {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let weekday = cal.component(.weekday, from: start)
        return cal.date(byAdding: .day, value: -(weekday - 1), to: start) ?? start
    }

    static func templateTime(hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
    }
}
