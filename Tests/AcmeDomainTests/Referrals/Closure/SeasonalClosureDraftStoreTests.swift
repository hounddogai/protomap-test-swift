@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySeasonalClosureDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SeasonalClosureDraftStore = Referrals.newMemorySeasonalClosureDraftStore()
        let item = Referrals.newSeasonalClosureDraft("code-673", title: "title-87")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
