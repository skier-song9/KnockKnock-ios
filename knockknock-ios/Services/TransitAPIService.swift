import CoreLocation
import Foundation

final class TransitAPIService {
    private let apiKey: String
    private let baseURL = "https://apis.data.go.kr/1613000/BusRouteInfoInqireService"

    init(apiKey: String = AppConfig.transitAPIKey) {
        self.apiKey = apiKey
    }

    // MARK: - 정류장 이름 검색

    func searchStops(query: String) async throws -> [TransitStop] {
        guard !apiKey.isEmpty else { return [] }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/getSttnList" +
            "?serviceKey=\(apiKey)" +
            "&cityCode=21" +
            "&nodeName=\(encoded)" +
            "&pageNo=1&numOfRows=20&_type=json"

        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try parseStopList(data)
    }

    // MARK: - GPS 기반 근처 정류장

    func nearbyStops(location: CLLocationCoordinate2D,
                     radius: Int = 300) async throws -> [TransitStop] {
        guard !apiKey.isEmpty else { return [] }
        let urlString = "\(baseURL)/getCrdntPrxmtSttnList" +
            "?serviceKey=\(apiKey)" +
            "&gpsLati=\(location.latitude)" +
            "&gpsLong=\(location.longitude)" +
            "&_type=json"

        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try parseStopList(data)
    }

    // MARK: - 노선 정류장 순서 조회

    func stopSequence(routeId: String) async throws -> [TransitStop] {
        guard !apiKey.isEmpty else { return [] }
        let urlString = "\(baseURL)/getRouteAcctoThrghSttnList" +
            "?serviceKey=\(apiKey)" +
            "&cityCode=21" +
            "&routeId=\(routeId)" +
            "&_type=json"

        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try parseStopList(data)
    }

    // MARK: - JSON 파싱 (공공데이터 공통 응답 구조)

    private func parseStopList(_ data: Data) throws -> [TransitStop] {
        // 공공데이터포털 응답 구조:
        // { "response": { "body": { "items": { "item": [...] } } } }
        struct Item: Codable {
            let nodeid: String?
            let nodenm: String?
            let gpsLati: Double?
            let gpsLong: Double?
            let nodeord: Int?
            let routeid: String?
        }
        struct Items: Codable {
            let item: [Item]?
        }
        struct Body: Codable {
            let items: Items?
        }
        struct Response: Codable {
            let body: Body?
        }
        struct Root: Codable {
            let response: Response
        }

        let root = try JSONDecoder().decode(Root.self, from: data)
        return root.response.body?.items?.item?.compactMap { item in
            guard let id = item.nodeid,
                  let name = item.nodenm,
                  let lat = item.gpsLati,
                  let lng = item.gpsLong else { return nil }
            return TransitStop(
                id: id,
                name: name,
                coordinate: .init(latitude: lat, longitude: lng),
                routeId: item.routeid ?? "",
                stopIndex: item.nodeord ?? 0
            )
        } ?? []
    }
}
