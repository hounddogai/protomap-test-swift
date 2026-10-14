@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryAdaptiveNetworkDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.AdaptiveNetworkDraftStore = Referrals.newMemoryAdaptiveNetworkDraftStore()
        let item = Referrals.newAdaptiveNetworkDraft("code-891", name: "name-541")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
