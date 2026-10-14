@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilityAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilityAssignmentStore = Referrals.newMemoryEligibilityAssignmentStore()
        let item = Referrals.newEligibilityAssignment("code-124", name: "name-90")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
