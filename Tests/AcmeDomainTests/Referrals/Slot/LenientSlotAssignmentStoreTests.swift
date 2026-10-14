@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryLenientSlotAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.LenientSlotAssignmentStore = Referrals.newMemoryLenientSlotAssignmentStore()
        let item = Referrals.newLenientSlotAssignment("code-739", name: "name-943")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
