@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryWeightedFollowUpAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.WeightedFollowUpAssignmentStore = Referrals.newMemoryWeightedFollowUpAssignmentStore()
        let item = Referrals.newWeightedFollowUpAssignment("code-43", label: "label-943")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
