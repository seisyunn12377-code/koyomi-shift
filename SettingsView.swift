import SwiftUI

/// 店名と名前の設定
struct SettingsView: View {
    @EnvironmentObject var store: WorkStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("本人の名前") {
                    TextField("例: あや", text: $store.personName)
                }
                Section("店名") {
                    TextField("例: 上福岡店", text: $store.defaultStore)
                }
                Section {
                    Text("名前を入れると、画面の上に「○○さんの出勤予定」と出ます。店名は日ごとに変えることもできます。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
        }
    }
}
