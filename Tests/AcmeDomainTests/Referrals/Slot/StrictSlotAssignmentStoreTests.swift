@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryStrictSlotAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.StrictSlotAssignmentStore = Referrals.newMemoryStrictSlotAssignmentStore()
        let item = Referrals.newStrictSlotAssignment("code-650", name: "name-497")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
