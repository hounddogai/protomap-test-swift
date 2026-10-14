@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryBatchedReferralAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.BatchedReferralAssignmentStore = Referrals.newMemoryBatchedReferralAssignmentStore()
        let item = Referrals.newBatchedReferralAssignment("code-934", label: "label-668")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
