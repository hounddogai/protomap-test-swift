@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryTieredEligibilityRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.TieredEligibilityRecordStore = Referrals.newMemoryTieredEligibilityRecordStore()
        let item = Referrals.newTieredEligibilityRecord("code-515", title: "title-431")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
