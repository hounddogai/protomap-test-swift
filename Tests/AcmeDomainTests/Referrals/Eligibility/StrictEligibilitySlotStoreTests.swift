@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryStrictEligibilitySlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.StrictEligibilitySlotStore = Referrals.newMemoryStrictEligibilitySlotStore()
        let item = Referrals.newStrictEligibilitySlot("code-701", name: "name-197")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
