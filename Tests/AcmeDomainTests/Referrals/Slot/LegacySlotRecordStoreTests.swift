@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryLegacySlotRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.LegacySlotRecordStore = Referrals.newMemoryLegacySlotRecordStore()
        let item = Referrals.newLegacySlotRecord("code-527", title: "title-928")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
