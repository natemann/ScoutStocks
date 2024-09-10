import ComposableArchitecture
import SwiftUI

@Reducer
struct StockList {

  @ObservableState
  struct State: Equatable {
    @Shared(.fileStorage(.stocks)) var stocks: [Stock] = []
    @Presents var destination: Destination.State?
  }

  enum Action {
    case addStockButtonPressed
    case delete(IndexSet)
    case destination(PresentationAction<Destination.Action>)
    case dismissButtonPressed
  }

  @Reducer(state: .equatable)
  enum Destination {
    case stockSearch(StockSearch)
  }

  @Dependency(\.dismiss) var dismiss

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      
      case .addStockButtonPressed:
        state.destination = .stockSearch(.init())
        return .none

      case .delete(let indexSet):
        state.stocks.remove(atOffsets: indexSet)
        return .none

      case .destination(.presented(.stockSearch(.select(let stock)))):
        state.destination = nil
        if !state.stocks.contains(stock) {
          state.stocks.append(stock)
        }
        return .none

      case .destination:
        return .none 

      case .dismissButtonPressed:
        return .run { _ in await dismiss() }
      }
    }
    .ifLet(
      \.$destination,
      action: \.destination)
  }
}

struct StockListView: View {
  @Bindable var store: StoreOf<StockList>

  var body: some View {
    List {
      ForEach(store.stocks) { stock in
        HStack {
          Text(stock.name)
          Spacer()
          Text(stock.ticker)
        }
      }
      .onDelete { offsets in
        store.send(.delete(offsets))
      }
    }
    .listStyle(.plain)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button {
          store.send(.dismissButtonPressed)
        } label: {
          Image(systemName: "xmark")
        }
      }
      ToolbarItem(placement: .principal) {
        Text("Stocks")
      }
      ToolbarItem(placement: .primaryAction) {
        Button {
          store.send(.addStockButtonPressed)
        } label: {
          Text("Add Stock")
        }
      }
    }
    .sheet(item: $store.scope(
      state: \.destination?.stockSearch,
      action: \.destination.stockSearch)
    ) { store in
      NavigationStack {
        StockSearchView(store: store)
      }
    }
  }
}

#Preview {
  NavigationStack {
    StockListView(store: .init(
      initialState: .init(stocks: []),
      reducer: StockList.init))
  }
}
