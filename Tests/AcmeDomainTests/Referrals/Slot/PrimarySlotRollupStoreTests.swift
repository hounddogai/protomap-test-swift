@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPrimarySlotRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PrimarySlotRollupStore = Referrals.newMemoryPrimarySlotRollupStore()
        let item = Referrals.newPrimarySlotRollup("code-407", name: "name-63")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
