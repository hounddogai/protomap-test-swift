@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryReferralAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ReferralAssignmentStore = Referrals.newMemoryReferralAssignmentStore()
        let item = Referrals.newReferralAssignment("code-34", title: "title-394")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
