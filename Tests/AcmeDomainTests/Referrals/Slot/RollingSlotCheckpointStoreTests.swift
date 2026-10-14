@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRollingSlotCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RollingSlotCheckpointStore = Referrals.newMemoryRollingSlotCheckpointStore()
        let item = Referrals.newRollingSlotCheckpoint("code-753", name: "name-34")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
