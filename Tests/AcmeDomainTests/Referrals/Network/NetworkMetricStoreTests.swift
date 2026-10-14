@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkMetricStore = Referrals.newMemoryNetworkMetricStore()
        let item = Referrals.newNetworkMetric("code-435", label: "label-891")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
