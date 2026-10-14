@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryLegacyFollowUpAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.LegacyFollowUpAdjustmentStore = Referrals.newMemoryLegacyFollowUpAdjustmentStore()
        let item = Referrals.newLegacyFollowUpAdjustment("code-854", name: "name-628")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
