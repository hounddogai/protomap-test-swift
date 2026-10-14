@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPrimaryFollowUpAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PrimaryFollowUpAdjustmentStore = Referrals.newMemoryPrimaryFollowUpAdjustmentStore()
        let item = Referrals.newPrimaryFollowUpAdjustment("code-658", label: "label-389")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
