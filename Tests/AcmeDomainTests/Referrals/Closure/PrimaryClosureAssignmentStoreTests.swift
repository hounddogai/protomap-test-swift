@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPrimaryClosureAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PrimaryClosureAssignmentStore = Referrals.newMemoryPrimaryClosureAssignmentStore()
        let item = Referrals.newPrimaryClosureAssignment("code-918", title: "title-197")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
