@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeMetricStore = RevenueCycle.newMemoryChargeMetricStore()
        let item = RevenueCycle.newChargeMetric("code-464", title: "title-919")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
