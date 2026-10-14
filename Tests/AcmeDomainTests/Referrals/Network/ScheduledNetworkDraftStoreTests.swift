@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryScheduledNetworkDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ScheduledNetworkDraftStore = Referrals.newMemoryScheduledNetworkDraftStore()
        let item = Referrals.newScheduledNetworkDraft("code-874", name: "name-800")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
