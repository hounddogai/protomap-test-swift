@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryCappedNetworkDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.CappedNetworkDraftStore = Referrals.newMemoryCappedNetworkDraftStore()
        let item = Referrals.newCappedNetworkDraft("code-932", label: "label-684")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
