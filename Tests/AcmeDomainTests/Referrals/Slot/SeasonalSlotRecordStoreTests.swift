@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySeasonalSlotRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SeasonalSlotRecordStore = Referrals.newMemorySeasonalSlotRecordStore()
        let item = Referrals.newSeasonalSlotRecord("code-320", name: "name-706")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
