import ComposableArchitecture
import SwiftUI

@Reducer
struct StockSearch {

  @ObservableState
  struct State: Equatable {
    var error: String?
    var searchText: String = ""
    var stocks: [Stock] = []
  }

  enum Action {
    case dismissButtonPressed
    case load(Result<[Stock], Error>)
    case search(String)
    case select(Stock)
  }

  @Dependency(\.dismiss) var dismiss
  @Dependency(\.networkClient) var networkClient
  @Dependency(\.mainQueue) var mainQueue

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {

      case .dismissButtonPressed:
        return .run { _ in await dismiss() }

      case .load(.success(let stocks)):
        state.stocks = stocks
        return .none

      case .load(.failure(let error)):
        state.error = error.localizedDescription
        return .none

      case .search(let text) where text == "":
        state.stocks = []
        return .none
        
      case .search(let text):
        state.searchText = text
        return .run { send in
          await send(.load(.init {
            try await networkClient.searchStocks(search: text)
          }))
        }
        .debounce(id: "Search", for: .milliseconds(500), scheduler: mainQueue)

      case .select:
        return .none 
      }
    }
  }
}

struct StockSearchView: View {
  @Bindable var store: StoreOf<StockSearch>

  var body: some View {
    Group {
      if let error = store.error {
        Text(error)
      } else if store.stocks.isEmpty {
        ContentUnavailableView(
          "Please Search for Ticker Symbol",
          systemImage: "magnifyingglass")
      } else {
        List {
          ForEach(store.stocks) { stock in
            HStack {
              Text(stock.name)
              Spacer()
              Text(stock.ticker)
            }
            .contentShape(Rectangle())
            .onTapGesture {
              store.send(.select(stock))
            }
          }
        }
        .listStyle(.plain)
      }
    }
    .searchable(text: $store.searchText.sending(\.search))
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button { 
          store.send(.dismissButtonPressed)
        } label: {
          Image(systemName: "xmark")
        }
      }
      ToolbarItem(placement: .principal) {
        Text("Stock Search")
      }
    }
  }
}

#Preview {
  NavigationStack {
    StockSearchView(store: .init(
      initialState: .init(stocks: []),
      reducer: StockSearch.init))
  }
}
