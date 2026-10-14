@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryCappedReferralAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.CappedReferralAllocationStore = Referrals.newMemoryCappedReferralAllocationStore()
        let item = Referrals.newCappedReferralAllocation("code-989", name: "name-368")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
