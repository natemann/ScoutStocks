import ComposableArchitecture
import SwiftUI
import Charts

@Reducer
struct StockDetails {

  @ObservableState
  struct State: Equatable {
    let stock: Stock

    var alertMessage: String?
    var daily: Daily?
    var movingAverages: [MovingAverage] = []
    var ticker: Ticker?
  }

  enum Action {
    case loadDaily(Result<Daily, Error>)
    case loadMovingAverage(Result<[MovingAverage], Error>)
    case loadStock(Result<Ticker, Error>)
    case onAppear
  }

  @Dependency(\.networkClient) var networkClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      
      case .loadDaily(.success(let daily)):
        state.daily = daily
        return .none

      case .loadMovingAverage(.success(let movingAverages)):
        state.movingAverages = movingAverages
        return .none

      case .loadStock(.success(let ticker)):
        state.ticker = ticker
        return .none
        
      case .loadStock(.failure(let error)),
           .loadMovingAverage(.failure(let error)),
           .loadDaily(.failure(let error)):
        if let error = error as? PolygonReqestError {
          state.alertMessage = error.error
        } else {
          state.alertMessage = error.localizedDescription
        }
        return .none

      case .onAppear:
        return .run { [symbol = state.stock.ticker] send in
          await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
              await send(.loadStock(.init {
                try await networkClient.getTickerDetails(ticker: symbol)
              }))
            }
            group.addTask {
              await send(.loadMovingAverage(.init {
                try await networkClient.getMovingAverage(ticker: symbol)
              }))
            }
            group.addTask {
              await send(.loadDaily(.init {
                try await networkClient.getDaily(ticker: symbol)
              }))
            }
          }
        }
      }
    }
  }
}

struct StockDetailsView: View {
  let store: StoreOf<StockDetails>

  var body: some View {
    Form {
      Section {
        VStack(alignment: .leading) {
          Text(store.stock.ticker)
            .font(.title)
          Text(store.stock.name)
        }
      } footer: {
        if let alertMessage = store.alertMessage {
          Text(alertMessage)
            .foregroundStyle(Color.red)
            .font(.caption)
        }
      }

      if let daily = store.daily {
        Section {
          if let open = daily.open {
            LabeledContent {
              Text(open, format: .currency(code: "USD"))
            } label: {
              Text("Open")
            }
          }
          if let close = daily.close {
            LabeledContent {
              Text(close, format: .currency(code: "USD"))
            } label: {
              Text("Close")
            }
          }
          if let high = daily.high {
            LabeledContent {
              Text(high, format: .currency(code: "USD"))
            } label: {
              Text("High")
            }
          }
          if let low = daily.low {
            LabeledContent {
              Text(low, format: .currency(code: "USD"))
            } label: {
              Text("Low")
            }
          }
        }
      }
      if let ticker = store.ticker {
        Section {
          Text(ticker.description)
        } header: {
          Text("Description")
        }

        Section {
          LabeledContent {
            Text(ticker.market_cap, format: .currency(code: "USD"))
          } label: {
            Text("Market Cap")
          }

        }
      }

      if !store.movingAverages.isEmpty {
        Section {
          Chart {
            ForEach(store.movingAverages.sorted(by: { $0.timestamp < $1.timestamp })) { movingAverage in
              LineMark(
                x: .value("date", movingAverage.date),
                y: .value("value", movingAverage.value))
              .interpolationMethod(.catmullRom)
            }
          }
          .chartXAxis {
            AxisMarks(
              values: .stride(by: .month),
              content: { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month())
              })
          }
          .chartYScale(domain: ClosedRange(uncheckedBounds: (
            lower: store.movingAverages.map(\.value).min()!,
            upper: store.movingAverages.map(\.value).max()!)))
          .padding()
        } header: {
          Text("Moving Average")
        }
      }
    }
    .onAppear {
      store.send(.onAppear)
    }
  }

}
