@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryWeightedFollowUpSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.WeightedFollowUpSlotStore = Referrals.newMemoryWeightedFollowUpSlotStore()
        let item = Referrals.newWeightedFollowUpSlot("code-133", label: "label-330")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
