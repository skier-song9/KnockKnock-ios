import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section("프라이버시") {
                Toggle("목적지 비공개", isOn: $appState.isPrivate)
                    .onChange(of: appState.isPrivate) { _, value in
                        appState.wsService.updateSession(isPrivate: value)
                    }

                if appState.isPrivate {
                    Text("비공개 시 다른 사람에게 내 목적지가 표시되지 않으며,\n화살표도 당신을 가리키지 않습니다.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("앱 정보") {
                LabeledContent("버전", value: "1.0.0")
                LabeledContent("Device ID", value: String(UserSession.makeDeviceId().prefix(8)) + "...")
            }
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}
