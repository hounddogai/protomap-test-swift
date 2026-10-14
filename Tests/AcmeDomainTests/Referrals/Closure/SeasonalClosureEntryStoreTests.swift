@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySeasonalClosureEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SeasonalClosureEntryStore = Referrals.newMemorySeasonalClosureEntryStore()
        let item = Referrals.newSeasonalClosureEntry("code-724", title: "title-174")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
