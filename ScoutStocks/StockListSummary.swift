import ComposableArchitecture
import SwiftUI

@Reducer
struct StockListSummary {
  
  @ObservableState
  struct State: Equatable {
    var alertMessage: String?
    var dailies: [Daily] = []
    @Shared(.fileStorage(.stocks)) var stocks: [Stock] = []
    @Presents var destination: Destination.State?
  }

  enum Action {
    case destination(PresentationAction<Destination.Action>)
    case loadDaily(Result<Daily, Error>)
    case refreshDailies
    case select(Stock)
    case stocksButtonPressed
  }

  @Reducer(state: .equatable)
  enum Destination {
    case stockDetails(StockDetails)
    case stockList(StockList)
  }

  @Dependency(\.networkClient) var networkClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      
      case .destination(.presented(.stockList(.dismissButtonPressed))):
        return .send(.refreshDailies)

      case .destination:
        return .none

      case .loadDaily(.success(let daily)):
        if !state.dailies.map(\.symbol).contains(daily.symbol) {
          state.dailies.append(daily)
        }
        return .none

      case .loadDaily(.failure(let error)):
        if let error = error as? PolygonReqestError {
          state.alertMessage = error.error
        } else {
          state.alertMessage = error.localizedDescription
        }
        return .none

      case .refreshDailies:
        state.alertMessage = nil
        return .run { [stocks = state.stocks] send in
          await withThrowingTaskGroup(of: Void.self) { group in
            stocks.forEach { stock in
              group.addTask {
                await send(.loadDaily(.init {
                  try await networkClient.getDaily(ticker: stock.ticker)
                }))
              }
            }
          }
        }

      case .select(let stock):
        state.destination = .stockDetails(.init(stock: stock))
        return .none

      case .stocksButtonPressed:
        state.destination = .stockList(.init())
        return .none
      }
    }
    .ifLet(
      \.$destination,
      action: \.destination)
  }
}

struct StockListSummaryView: View {
  @Bindable var store: StoreOf<StockListSummary>

  var body: some View {
    List {
      Section {
        ForEach(store.stocks) { stock in
          HStack {
            Text(stock.ticker)
              .font(.title)
            Spacer()
            if 
              let daily = store.dailies.first(where: { $0.symbol == stock.ticker }),
              let change = daily.change {
              HStack {
                Group {
                  if change > 0 {
                    Image(systemName: "arrow.up.right")
                      .foregroundStyle(Color.green)
                  } else if change < 0 {
                    Image(systemName: "arrow.down.right")
                      .foregroundStyle(Color.red)
                  }
                }
                Text(change, format: .currency(code: "USD"))
              }
              .font(.caption)
            } else {
              ProgressView()
            }
          }
          .contentShape(Rectangle())
          .onTapGesture {
            store.send(.select(stock))
          }
        }
      } footer: {
        if let alertMessage = store.alertMessage {
          Text(alertMessage)
            .foregroundStyle(Color.red)
            .font(.caption)
        }
      }
    }
    .refreshable {
      store.send(.refreshDailies)
    }
    .onAppear {
      store.send(.refreshDailies)
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          store.send(.stocksButtonPressed)
        } label: {
          Text("Stocks")
        }
      }
    }
    .sheet(item: $store.scope(
      state: \.destination?.stockList,
      action: \.destination.stockList)
    ) { store in
      NavigationStack {
        StockListView(store: store)
          .interactiveDismissDisabled()
      }
    }
    .navigationDestination(
      item: $store.scope(
        state: \.destination?.stockDetails,
        action: \.destination.stockDetails),
      destination: StockDetailsView.init)
  }
}
