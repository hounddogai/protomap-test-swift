@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRegionalFollowUpMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RegionalFollowUpMetricStore = Referrals.newMemoryRegionalFollowUpMetricStore()
        let item = Referrals.newRegionalFollowUpMetric("code-343", label: "label-262")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
