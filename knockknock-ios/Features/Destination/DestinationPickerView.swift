import SwiftUI

struct DestinationPickerView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool

    enum Tab: String, CaseIterable {
        case search = "검색"
        case nearby = "내 위치"
        case map = "지도"
    }

    @State private var selectedTab: Tab = .search

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("방식", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedTab {
                case .search:
                    StopSearchView(onSelect: selectStop)
                case .nearby:
                    NearbyStopsView(onSelect: selectStop)
                case .map:
                    MapPickerView(onSelect: selectStop)
                }
            }
            .navigationTitle("목적지 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func selectStop(_ stop: TransitStop) {
        appState.selectedStop = stop
        isPresented = false
    }
}
