import Foundation

struct Stock: Equatable, Identifiable, Codable {
  let name: String
  let ticker: String

  var id: String {
    ticker
  }
}
