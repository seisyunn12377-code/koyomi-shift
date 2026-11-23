import SwiftUI

/// 1日分の出勤・退勤を入力するシート。
/// よく使う時間はワンタップ、勤務時間はその場で計算して見せる。
struct DayEditorView: View {
    @EnvironmentObject var store: WorkStore
    @Environment(\.dismiss) private var dismiss

    let day: Date

    @State private var isDayOff = false
    @State private var start: Date = Date()
    @State private var end: Date = Date()
    @State private var afterWork: String = ""
    @State private var storeName: String = ""
    @State private var memo: String = ""
    @State private var hasExisting = false

    private let startPresets = [9, 10, 11, 12, 17]
    private let endPresets = [17, 18, 19, 22, 23]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    dayOffToggle
                    if !isDayOff {
                        timeCard(title: "出勤", time: $start, presets: startPresets)
                        timeCard(title: "退勤", time: $end, presets: endPresets)
                        durationBar
                        quickFillButton
                        afterWorkField
                    }
                    storeField
                    memoField
                    saveButton
                    if hasExisting {
                        Button("この日の記録を削除", role: .destructive) {
                            store.remove(on: day)
                            dismiss()
                        }
                        .font(.footnote)
                    }
                }
                .padding(16)
            }
            .background(Color(red: 1.0, green: 0.93, blue: 0.96))
            .navigationTitle(dayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
            .onAppear { loadExisting() }
        }
    }

    // MARK: - 部品

    private var dayOffToggle: some View {
        HStack(spacing: 10) {
            toggleButton(title: "出勤あり", selected: !isDayOff) { isDayOff = false }
            toggleButton(title: "休み", selected: isDayOff) { isDayOff = true }
        }
    }

    private func toggleButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? Color.pink : Color.white)
                .foregroundStyle(selected ? .white : .pink)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.pink.opacity(0.5), lineWidth: selected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func timeCard(title: String, time: Binding<Date>, presets: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text(formatTime(time.wrappedValue))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.pink)
            }
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { hour in
                    Button {
                        setHour(hour, for: time)
                    } label: {
                        Text("\(hour):00")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(isPresetSelected(hour, time.wrappedValue) ? Color.pink.opacity(0.25) : Color.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            DatePicker("時間を細かく変える", selection: time, displayedComponents: .hourAndMinute)
                .font(.subheadline)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var durationBar: some View {
        HStack {
            Text("勤務時間")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if end > start {
                Text(formatDuration(Int(end.timeIntervalSince(start) / 60)))
                    .font(.title3.bold())
            } else {
                Text("退勤が出勤より前になっています")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 6)
    }

    private var quickFillButton: some View {
        Button {
            let cal = Calendar.current
            start = cal.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? start
            end = cal.date(bySettingHour: 18, minute: 0, second: 0, of: day) ?? end
        } label: {
            Text("いつもの時間 (9:00-18:00) で入れる")
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white)
                .foregroundStyle(.pink)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var afterWorkField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("退勤のあとの予定").font(.subheadline.bold())
            TextField("例: 買い物、友達とごはん", text: $afterWork)
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var storeField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("店名").font(.subheadline.bold())
            TextField(store.defaultStore.isEmpty ? "店名 (任意)" : store.defaultStore, text: $storeName)
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var memoField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("メモ").font(.subheadline.bold())
            TextField("メモ (任意)", text: $memo)
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text("保存する")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.pink)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    // MARK: - ロジック

    private var dayTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M月d日 (E)"
        return f.string(from: day)
    }

    private func setHour(_ hour: Int, for time: Binding<Date>) {
        let cal = Calendar.current
        if let d = cal.date(bySettingHour: hour, minute: 0, second: 0, of: day) {
            time.wrappedValue = d
        }
    }

    private func isPresetSelected(_ hour: Int, _ date: Date) -> Bool {
        Calendar.current.component(.hour, from: date) == hour
            && Calendar.current.component(.minute, from: date) == 0
    }

    private func loadExisting() {
        let cal = Calendar.current
        if let rec = store.record(on: day) {
            hasExisting = true
            isDayOff = rec.isDayOff
            afterWork = rec.afterWork
            storeName = rec.store
            memo = rec.memo
            start = rec.start ?? cal.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? day
            end = rec.end ?? cal.date(bySettingHour: 18, minute: 0, second: 0, of: day) ?? day
        } else {
            start = cal.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? day
            end = cal.date(bySettingHour: 18, minute: 0, second: 0, of: day) ?? day
        }
    }

    private func save() {
        var rec = store.record(on: day) ?? WorkDay(dayKey: WorkStore.key(for: day))
        rec.isDayOff = isDayOff
        rec.afterWork = afterWork
        rec.store = storeName
        rec.memo = memo
        if isDayOff {
            rec.start = nil
            rec.end = nil
        } else {
            rec.start = start
            rec.end = end
        }
        store.set(rec)
        dismiss()
    }
}
