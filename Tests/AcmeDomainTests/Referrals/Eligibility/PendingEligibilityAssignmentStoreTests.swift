@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPendingEligibilityAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PendingEligibilityAssignmentStore = Referrals.newMemoryPendingEligibilityAssignmentStore()
        let item = Referrals.newPendingEligibilityAssignment("code-471", title: "title-33")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
