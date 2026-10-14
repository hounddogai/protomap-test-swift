@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySeasonalNetworkGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SeasonalNetworkGroupStore = Referrals.newMemorySeasonalNetworkGroupStore()
        let item = Referrals.newSeasonalNetworkGroup("code-784", title: "title-245")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
