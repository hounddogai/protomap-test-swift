@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryGlobalReferralAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.GlobalReferralAllocationStore = Referrals.newMemoryGlobalReferralAllocationStore()
        let item = Referrals.newGlobalReferralAllocation("code-401", label: "label-788")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
