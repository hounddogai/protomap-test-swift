@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySeasonalFollowUpBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SeasonalFollowUpBundleStore = Referrals.newMemorySeasonalFollowUpBundleStore()
        let item = Referrals.newSeasonalFollowUpBundle("code-648", name: "name-354")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
