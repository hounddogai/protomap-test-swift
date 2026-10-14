@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryClaimForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ClaimForecastStore = RevenueCycle.newMemoryClaimForecastStore()
        let item = RevenueCycle.newClaimForecast("code-939", label: "label-576")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
