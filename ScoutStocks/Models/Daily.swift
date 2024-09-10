import Foundation

struct Daily: Equatable, Identifiable, Codable {
  let afterHours: Double?
  let close: Double?
  let high: Double?
  let low: Double?
  let open: Double?
  let preMarket: Double?
  let symbol: String
  let volume: Int?

  var id: String {
    symbol
  }

  var change: Double? {
    guard let close, let open else { return nil }
    return close - open
  }

  enum CodingKeys: String, CodingKey {
    case afterHours
    case close
    case high
    case low
    case open
    case preMarket
    case symbol
    case volume
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(afterHours, forKey: .afterHours)
    try container.encodeIfPresent(close, forKey: .close)
    try container.encodeIfPresent(high, forKey: .high)
    try container.encodeIfPresent(low, forKey: .low)
    try container.encodeIfPresent(open, forKey: .open)
    try container.encodeIfPresent(preMarket, forKey: .preMarket)
    try container.encodeIfPresent(symbol, forKey: .symbol)
    try container.encodeIfPresent(volume, forKey: .volume)
  }
}
