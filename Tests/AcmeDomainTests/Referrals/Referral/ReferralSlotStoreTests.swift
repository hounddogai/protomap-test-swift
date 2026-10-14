@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryReferralSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ReferralSlotStore = Referrals.newMemoryReferralSlotStore()
        let item = Referrals.newReferralSlot("code-289", title: "title-856")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
