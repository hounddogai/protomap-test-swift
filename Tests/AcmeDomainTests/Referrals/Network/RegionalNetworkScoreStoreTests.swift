@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRegionalNetworkScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RegionalNetworkScoreStore = Referrals.newMemoryRegionalNetworkScoreStore()
        let item = Referrals.newRegionalNetworkScore("code-738", name: "name-148")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
