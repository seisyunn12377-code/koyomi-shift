import Foundation

/// 1日分の勤務記録
struct WorkDay: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var dayKey: String          // "yyyy-M-d"
    var start: Date? = nil      // 出勤
    var end: Date? = nil        // 退勤
    var isDayOff: Bool = false  // 休み
    var afterWork: String = ""  // 退勤のあとの予定
    var store: String = ""      // 店名 (空なら既定の店名を使う)
    var memo: String = ""

    var workedMinutes: Int? {
        guard let s = start, let e = end, e > s else { return nil }
        return Int(e.timeIntervalSince(s) / 60)
    }
}

final class WorkStore: ObservableObject {
    @Published var days: [String: WorkDay] = [:] {
        didSet { save() }
    }

    private let storageKey = "metabo.calendar.workdays.v1"

    /// 既定の店名と、本人の名前 (設定画面で変更)
    @Published var defaultStore: String = UserDefaults.standard.string(forKey: "metabo.calendar.defaultStore") ?? "" {
        didSet { UserDefaults.standard.set(defaultStore, forKey: "metabo.calendar.defaultStore") }
    }
    @Published var personName: String = UserDefaults.standard.string(forKey: "metabo.calendar.personName") ?? "" {
        didSet { UserDefaults.standard.set(personName, forKey: "metabo.calendar.personName") }
    }

    init() {
        load()
    }

    /// その日に表示する店名 (日の記録 > 既定の店名)
    func storeName(on date: Date) -> String {
        if let rec = record(on: date), !rec.store.isEmpty {
            return rec.store
        }
        return defaultStore
    }

    static func key(for date: Date) -> String {
        let c = Calendar.current
        return "\(c.component(.year, from: date))-\(c.component(.month, from: date))-\(c.component(.day, from: date))"
    }

    func record(on date: Date) -> WorkDay? {
        days[Self.key(for: date)]
    }

    func set(_ record: WorkDay) {
        days[record.dayKey] = record
    }

    func remove(on date: Date) {
        days.removeValue(forKey: Self.key(for: date))
    }

    /// 指定した月の合計勤務分数と出勤日数
    func monthSummary(year: Int, month: Int) -> (minutes: Int, workDays: Int) {
        var minutes = 0
        var count = 0
        for (k, v) in days {
            let parts = k.split(separator: "-").compactMap { Int($0) }
            guard parts.count == 3, parts[0] == year, parts[1] == month else { continue }
            if let m = v.workedMinutes {
                minutes += m
                count += 1
            }
        }
        return (minutes, count)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(days) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: WorkDay].self, from: data) {
            days = decoded
        }
    }
}

/// 分 → "152時間30分" 形式
func formatDuration(_ minutes: Int) -> String {
    "\(minutes / 60)時間\(minutes % 60)分"
}

/// 時刻 → "9:00" 形式
func formatTime(_ date: Date) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ja_JP")
    f.dateFormat = "H:mm"
    return f.string(from: date)
}
