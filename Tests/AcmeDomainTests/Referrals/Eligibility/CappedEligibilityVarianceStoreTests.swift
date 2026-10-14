@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryCappedEligibilityVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.CappedEligibilityVarianceStore = Referrals.newMemoryCappedEligibilityVarianceStore()
        let item = Referrals.newCappedEligibilityVariance("code-211", name: "name-789")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
