@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryScheduledReferralAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ScheduledReferralAllocationStore = Referrals.newMemoryScheduledReferralAllocationStore()
        let item = Referrals.newScheduledReferralAllocation("code-501", label: "label-405")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
