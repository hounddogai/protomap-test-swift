@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryWeightedSlotBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.WeightedSlotBundleStore = Referrals.newMemoryWeightedSlotBundleStore()
        let item = Referrals.newWeightedSlotBundle("code-622", title: "title-383")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
