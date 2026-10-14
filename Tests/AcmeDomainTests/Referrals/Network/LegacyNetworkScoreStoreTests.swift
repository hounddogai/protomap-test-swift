@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryLegacyNetworkScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.LegacyNetworkScoreStore = Referrals.newMemoryLegacyNetworkScoreStore()
        let item = Referrals.newLegacyNetworkScore("code-945", title: "title-348")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
