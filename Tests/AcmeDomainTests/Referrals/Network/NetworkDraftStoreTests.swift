@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkDraftStore = Referrals.newMemoryNetworkDraftStore()
        let item = Referrals.newNetworkDraft("code-773", name: "name-589")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
