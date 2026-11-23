import SwiftUI

/// タブ: カレンダー (1画面) / 月表示 (一覧)
struct RootView: View {
    var body: some View {
        TabView {
            CalendarView()
                .tabItem {
                    Label("カレンダー", systemImage: "calendar")
                }
            MonthListView()
                .tabItem {
                    Label("月表示", systemImage: "list.bullet")
                }
            WeekAdjustView()
                .tabItem {
                    Label("週の調整", systemImage: "calendar.badge.checkmark")
                }
        }
        .tint(.pink)
    }
}
