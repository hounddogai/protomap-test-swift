@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryFallbackClaimForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.FallbackClaimForecastStore = RevenueCycle.newMemoryFallbackClaimForecastStore()
        let item = RevenueCycle.newFallbackClaimForecast("code-972", name: "name-840")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
