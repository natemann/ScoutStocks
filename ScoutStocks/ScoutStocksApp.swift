import SwiftUI

@main
struct ScoutStocksApp: App {
    var body: some Scene {
        WindowGroup {
          NavigationStack {
            StockListSummaryView(store: .init(
              initialState: .init(stocks: []),
              reducer: StockListSummary.init))
          }
        }
    }
}
