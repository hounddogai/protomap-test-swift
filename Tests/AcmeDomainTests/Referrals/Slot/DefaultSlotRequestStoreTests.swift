@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryDefaultSlotRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.DefaultSlotRequestStore = Referrals.newMemoryDefaultSlotRequestStore()
        let item = Referrals.newDefaultSlotRequest("code-446", label: "label-938")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
