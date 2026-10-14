@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilityMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilityMetricStore = Referrals.newMemoryEligibilityMetricStore()
        let item = Referrals.newEligibilityMetric("code-964", title: "title-423")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
