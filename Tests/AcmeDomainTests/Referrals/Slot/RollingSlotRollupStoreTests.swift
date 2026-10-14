@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRollingSlotRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RollingSlotRollupStore = Referrals.newMemoryRollingSlotRollupStore()
        let item = Referrals.newRollingSlotRollup("code-688", label: "label-355")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
