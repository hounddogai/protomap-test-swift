@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryStrictSlotRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.StrictSlotRecordStore = Referrals.newMemoryStrictSlotRecordStore()
        let item = Referrals.newStrictSlotRecord("code-79", label: "label-582")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
