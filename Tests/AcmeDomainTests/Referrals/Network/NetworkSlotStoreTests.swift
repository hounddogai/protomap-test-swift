@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkSlotStore = Referrals.newMemoryNetworkSlotStore()
        let item = Referrals.newNetworkSlot("code-565", label: "label-41")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
