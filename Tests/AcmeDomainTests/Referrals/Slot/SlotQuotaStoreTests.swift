@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySlotQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SlotQuotaStore = Referrals.newMemorySlotQuotaStore()
        let item = Referrals.newSlotQuota("code-480", title: "title-671")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
