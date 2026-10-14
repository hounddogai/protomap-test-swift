@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySeasonalNetworkCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SeasonalNetworkCycleStore = Referrals.newMemorySeasonalNetworkCycleStore()
        let item = Referrals.newSeasonalNetworkCycle("code-933", name: "name-643")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
