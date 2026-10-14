@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryManualRemittanceForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ManualRemittanceForecastStore = RevenueCycle.newMemoryManualRemittanceForecastStore()
        let item = RevenueCycle.newManualRemittanceForecast("code-516", title: "title-357")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
