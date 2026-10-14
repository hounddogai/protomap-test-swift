@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryAdaptiveFollowUpBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.AdaptiveFollowUpBaselineStore = Referrals.newMemoryAdaptiveFollowUpBaselineStore()
        let item = Referrals.newAdaptiveFollowUpBaseline("code-321", title: "title-742")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
