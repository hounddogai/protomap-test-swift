@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStrictStatementForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StrictStatementForecastStore = RevenueCycle.newMemoryStrictStatementForecastStore()
        let item = RevenueCycle.newStrictStatementForecast("code-408", title: "title-961")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
