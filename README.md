#  INSTRUCTIONS
1. Simply open the project, wait for dependencies to download, then run the app. 
2. Add stocks by selecting 'Stocks' in the upper right, then 'Add Stock' again in the upper right, then search for the stock you want, then select it. The app will automatically start downloading the desired data for the new stock. 
3. You can swipe-to-delete any stock in the 'Stocks' view.
4. Selected stocks will persist between launches. 

## Polygon API
1. This app uses the free version of Polygon. The free version does not provide the current price for a given symbol, or today's values. The best it can provide is the stock values for the previous day. 
2. There is a strict rate limit on the free plan. If you add too many stocks, you will probably go over this limit. I have attempted to catch this error and let the user know that the rate limit has been reached. 
3. In the stock details screen, I provided a 'Moving Average Price' graph. Historical prices were not available in the free plan. 

## TCA
I used The Composable Architecture (TCA) as a dependency in this app. It is a very popular app architecture for SwiftUI apps. I chose this dependency for a few reasons:
1. It is highly testable. I like to have thorough test coverage for apps that I work on. 
2. It is opinionated. Each feature / view written in TCA is very similar. This makes it easier to learn, comprehend, and review during code review sessons. 
3. It is well documented and well supported. The primary maintainers of the code base consider TCA their main job. They host a weekly video training subscription on all things Swift. They have recorded well over 50 hours of building out TCA and instructions on how to use it. 

## Other things to note
1. Code structure. I tried to keep the layout of the app / code to as few files as possible. I feel like it is easier to review this way. For a production app, I would seperate out concerns more thoroughly.
2. I did provide a test case to test adding a stock to the app and downloading for the stock. the network layer is completely mocked out for these tests. No actual network calls are made.  

