@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySeasonalEligibilityRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SeasonalEligibilityRecordStore = Referrals.newMemorySeasonalEligibilityRecordStore()
        let item = Referrals.newSeasonalEligibilityRecord("code-324", title: "title-267")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
