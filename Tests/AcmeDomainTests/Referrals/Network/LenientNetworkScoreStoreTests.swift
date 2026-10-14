@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryLenientNetworkScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.LenientNetworkScoreStore = Referrals.newMemoryLenientNetworkScoreStore()
        let item = Referrals.newLenientNetworkScore("code-6", label: "label-570")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
