import Foundation

struct Ticker: Equatable, Codable {
  let description: String 
  let market_cap: Double
  let name: String
  let ticker: String
}
