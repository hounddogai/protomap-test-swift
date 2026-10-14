@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureDraftStore = Referrals.newMemoryClosureDraftStore()
        let item = Referrals.newClosureDraft("code-222", name: "name-597")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
