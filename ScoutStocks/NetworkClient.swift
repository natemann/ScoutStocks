import Dependencies
import DependenciesMacros
import Foundation

extension DependencyValues {
  var networkClient: NetworkClient {
    get { self[NetworkClient.self] }
    set { self[NetworkClient.self] = newValue }
  }
}

@DependencyClient
struct NetworkClient {
  var getDaily: (_ ticker: String) async throws -> Daily
  var getMovingAverage: (_ ticker: String) async throws -> [MovingAverage]
  var getTickerDetails: (_ ticker: String) async throws -> Ticker
  var searchStocks: (_ search: String) async throws -> [Stock]
}

extension NetworkClient: DependencyKey {

  static var liveValue = Self(
    getDaily: { ticker in
      let formatter = DateFormatter()
      formatter.dateFormat = "YYYY-MM-dd"
      let yesterday = Calendar.autoupdatingCurrent.date(byAdding: .day, value: -1, to: Date())!

      let (data, _) = try await URLSession.shared.data(for: .init(url: .init(string: "https://api.polygon.io/v1/open-close/\(ticker)/\(formatter.string(from: yesterday))?adjusted=true&apiKey=wkjs5Mdr0xEOhLxdcb6jUpWmf_T8axub")!))
      if let error = try? JSONDecoder().decode(PolygonReqestError.self, from: data), error.status == "ERROR" {
        throw error
      }
      return try JSONDecoder().decode(Daily.self, from: data)
    },
    getMovingAverage: { ticker in
      let (data, _) = try await URLSession.shared.data(for: .init(url: .init(string: "https://api.polygon.io/v1/indicators/sma/\(ticker)?timespan=day&adjusted=true&window=50&series_type=high&order=desc&limit=10&apiKey=wkjs5Mdr0xEOhLxdcb6jUpWmf_T8axub")!))
      if let error = try? JSONDecoder().decode(PolygonReqestError.self, from: data), error.status == "ERROR" {
        throw error
      }
      return try JSONDecoder().decode(MoviingAverageResults.self, from: data).results.values
    },
    getTickerDetails: { ticker in
      let (data, _) = try await URLSession.shared.data(for: .init(url: .init(string: "https://api.polygon.io/v3/reference/tickers/\(ticker)?apiKey=wkjs5Mdr0xEOhLxdcb6jUpWmf_T8axub")!))
      if let error = try? JSONDecoder().decode(PolygonReqestError.self, from: data), error.status == "ERROR" {
        throw error
      }
      return try JSONDecoder().decode(TickerResults.self, from: data).results
    },
    searchStocks: { text in
      let (data, _) = try await URLSession.shared.data(for: .init(url: .init(string: "https://api.polygon.io/v3/reference/tickers?search=\(text)&active=true&limit=100&apiKey=wkjs5Mdr0xEOhLxdcb6jUpWmf_T8axub")!))
      if let error = try? JSONDecoder().decode(PolygonReqestError.self, from: data), error.status == "ERROR" {
        throw error
      }
      return try JSONDecoder().decode(SearchResults.self, from: data).results
    }
  )
}

struct PolygonReqestError: Decodable, Error {
  let status: String
  let error: String
}

struct SearchResults: Decodable {
  let results: [Stock]
}

struct TickerResults: Decodable {
  let results: Ticker
}

struct MoviingAverageResults: Decodable {
  struct Results: Decodable {
    let values: [MovingAverage]
  }

  let results: Results
}
