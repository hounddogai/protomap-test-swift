@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryGlobalSlotEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.GlobalSlotEstimateStore = Referrals.newMemoryGlobalSlotEstimateStore()
        let item = Referrals.newGlobalSlotEstimate("code-24", title: "title-139")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
