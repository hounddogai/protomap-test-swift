@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryLegacyReferralAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.LegacyReferralAssignmentStore = Referrals.newMemoryLegacyReferralAssignmentStore()
        let item = Referrals.newLegacyReferralAssignment("code-955", name: "name-79")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
