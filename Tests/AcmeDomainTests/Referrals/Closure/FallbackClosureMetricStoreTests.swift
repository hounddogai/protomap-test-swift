@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFallbackClosureMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FallbackClosureMetricStore = Referrals.newMemoryFallbackClosureMetricStore()
        let item = Referrals.newFallbackClosureMetric("code-756", label: "label-934")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
