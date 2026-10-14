@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryCappedSlotBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.CappedSlotBundleStore = Referrals.newMemoryCappedSlotBundleStore()
        let item = Referrals.newCappedSlotBundle("code-981", name: "name-863")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
