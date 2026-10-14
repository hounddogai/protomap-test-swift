@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFallbackFollowUpBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FallbackFollowUpBaselineStore = Referrals.newMemoryFallbackFollowUpBaselineStore()
        let item = Referrals.newFallbackFollowUpBaseline("code-810", label: "label-467")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
