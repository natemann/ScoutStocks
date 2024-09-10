@testable import ScoutStocks
import ComposableArchitecture
import XCTest

final class ScoutStocksTests: XCTestCase {

  func test_flow() async {
    @Shared(.fileStorage(.stocks)) var stocks: [Stock] = []
    await $stocks.withLock { $0 = [] }

    let store = await TestStore(
      initialState: StockListSummary.State(),
      reducer: StockListSummary.init
    ) {
      $0.mainQueue = .immediate
      $0.networkClient.getDaily = { _ in .init(afterHours: 0, close: 0, high: 0, low: 0, open: 0, preMarket: 0, symbol: "AAPL", volume: 0) }
      $0.networkClient.searchStocks = { _ in [.init(name: "APPLE", ticker: "AAPL")] }
    }

    await store.send(.stocksButtonPressed) {
      $0.destination = .stockList(.init())
    }
    await store.send(.destination(.presented(.stockList(.addStockButtonPressed)))) {
      $0.destination?.modify(\.stockList) {
        $0.destination = .stockSearch(.init())
      }
    }
    await store.send(.destination(.presented(.stockList(.destination(.presented(.stockSearch(.search("AAPL")))))))) {
      $0.destination?.modify(\.stockList) {
        $0.destination?.modify(\.stockSearch) {
          $0.searchText = "AAPL"
        }
      }
    }
    await store.receive(\.destination.presented.stockList.destination.presented.stockSearch.load) {
      $0.destination?.modify(\.stockList) {
        $0.destination?.modify(\.stockSearch) {
          $0.stocks = [.init(name: "APPLE", ticker: "AAPL")]
        }
      }
    }
    await $stocks.withLock { $0 = [.init(name: "APPLE", ticker: "AAPL")] }
    await store.send(.destination(.presented(.stockList(.destination(.presented(.stockSearch(.dismissButtonPressed)))))))
    await store.receive(\.destination.presented.stockList.destination.dismiss) {
      $0.destination?.modify(\.stockList) {
        $0.destination = nil
      }
    }
    await store.send(.destination(.presented(.stockList(.dismissButtonPressed))))
    await store.receive(\.refreshDailies)
    await store.receive(\.loadDaily) {
      $0.dailies = [.init(afterHours: 0, close: 0, high: 0, low: 0, open: 0, preMarket: 0, symbol: "AAPL", volume: 0)]
    }
    await store.receive(\.destination.dismiss) {
      $0.destination = nil
    }
  }

}
