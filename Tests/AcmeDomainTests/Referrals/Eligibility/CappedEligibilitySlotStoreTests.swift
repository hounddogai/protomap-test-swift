@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryCappedEligibilitySlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.CappedEligibilitySlotStore = Referrals.newMemoryCappedEligibilitySlotStore()
        let item = Referrals.newCappedEligibilitySlot("code-781", title: "title-927")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
