@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryCappedStatementForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.CappedStatementForecastStore = RevenueCycle.newMemoryCappedStatementForecastStore()
        let item = RevenueCycle.newCappedStatementForecast("code-600", name: "name-363")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
