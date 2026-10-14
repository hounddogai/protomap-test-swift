@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryTieredFollowUpMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.TieredFollowUpMetricStore = Referrals.newMemoryTieredFollowUpMetricStore()
        let item = Referrals.newTieredFollowUpMetric("code-886", label: "label-993")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
