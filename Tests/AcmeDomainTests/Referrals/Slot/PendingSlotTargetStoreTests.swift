@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPendingSlotTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PendingSlotTargetStore = Referrals.newMemoryPendingSlotTargetStore()
        let item = Referrals.newPendingSlotTarget("code-657", name: "name-977")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
