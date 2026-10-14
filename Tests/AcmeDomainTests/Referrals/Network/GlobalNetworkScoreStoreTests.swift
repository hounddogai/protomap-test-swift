@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryGlobalNetworkScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.GlobalNetworkScoreStore = Referrals.newMemoryGlobalNetworkScoreStore()
        let item = Referrals.newGlobalNetworkScore("code-834", label: "label-972")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
