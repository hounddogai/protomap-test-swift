@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureAssignmentStore = Referrals.newMemoryClosureAssignmentStore()
        let item = Referrals.newClosureAssignment("code-411", label: "label-394")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
