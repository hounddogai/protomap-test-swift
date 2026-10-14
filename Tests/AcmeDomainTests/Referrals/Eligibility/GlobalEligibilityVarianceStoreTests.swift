@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryGlobalEligibilityVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.GlobalEligibilityVarianceStore = Referrals.newMemoryGlobalEligibilityVarianceStore()
        let item = Referrals.newGlobalEligibilityVariance("code-440", title: "title-839")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
