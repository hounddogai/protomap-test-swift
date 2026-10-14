@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryScheduledDenialMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ScheduledDenialMetricStore = RevenueCycle.newMemoryScheduledDenialMetricStore()
        let item = RevenueCycle.newScheduledDenialMetric("code-324", title: "title-381")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
