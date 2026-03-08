import SwiftUI

struct StopSearchView: View {
    @EnvironmentObject var appState: AppState
    let onSelect: (TransitStop) -> Void

    @State private var query = ""
    @State private var results: [TransitStop] = []
    @State private var isLoading = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("정류장 이름 검색", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: query) {
                        search()
                    }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)

            if isLoading {
                ProgressView()
                    .padding()
            }

            List(results) { stop in
                Button {
                    onSelect(stop)
                } label: {
                    VStack(alignment: .leading) {
                        Text(stop.name)
                            .font(.body)
                        Text(stop.routeId)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(.plain)
        }
        .onDisappear {
            searchTask?.cancel()
        }
    }

    private func search() {
        searchTask?.cancel()

        guard query.count >= 2 else {
            results = []
            isLoading = false
            return
        }

        isLoading = true
        let currentQuery = query
        searchTask = Task {
            let fetched = (try? await appState.transitService.searchStops(query: currentQuery)) ?? []
            guard !Task.isCancelled else { return }
            await MainActor.run {
                results = fetched
                isLoading = false
            }
        }
    }
}
