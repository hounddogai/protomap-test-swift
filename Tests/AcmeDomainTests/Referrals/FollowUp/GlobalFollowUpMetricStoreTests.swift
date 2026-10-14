@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryGlobalFollowUpMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.GlobalFollowUpMetricStore = Referrals.newMemoryGlobalFollowUpMetricStore()
        let item = Referrals.newGlobalFollowUpMetric("code-635", name: "name-475")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
