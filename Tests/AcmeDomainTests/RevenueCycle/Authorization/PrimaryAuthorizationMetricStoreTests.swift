@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryPrimaryAuthorizationMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.PrimaryAuthorizationMetricStore = RevenueCycle.newMemoryPrimaryAuthorizationMetricStore()
        let item = RevenueCycle.newPrimaryAuthorizationMetric("code-976", label: "label-95")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
