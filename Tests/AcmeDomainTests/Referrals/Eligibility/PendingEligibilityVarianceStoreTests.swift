@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPendingEligibilityVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PendingEligibilityVarianceStore = Referrals.newMemoryPendingEligibilityVarianceStore()
        let item = Referrals.newPendingEligibilityVariance("code-970", title: "title-309")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
