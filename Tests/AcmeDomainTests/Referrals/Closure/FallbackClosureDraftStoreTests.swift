@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFallbackClosureDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FallbackClosureDraftStore = Referrals.newMemoryFallbackClosureDraftStore()
        let item = Referrals.newFallbackClosureDraft("code-127", label: "label-649")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
