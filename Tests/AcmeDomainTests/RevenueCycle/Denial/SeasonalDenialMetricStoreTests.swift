@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemorySeasonalDenialMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.SeasonalDenialMetricStore = RevenueCycle.newMemorySeasonalDenialMetricStore()
        let item = RevenueCycle.newSeasonalDenialMetric("code-150", title: "title-70")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
