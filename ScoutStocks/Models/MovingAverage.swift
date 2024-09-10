import Foundation

struct MovingAverage: Equatable, Decodable, Identifiable {
  let timestamp: Int
  let value: Double 

  var date: Date {
    Date(timeIntervalSince1970: (Double(timestamp) / 1000.0))
  }
  var id: Int {
    timestamp
  }
}
