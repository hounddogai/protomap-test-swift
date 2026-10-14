@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPendingEligibilityPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PendingEligibilityPreferenceStore = Referrals.newMemoryPendingEligibilityPreferenceStore()
        let item = Referrals.newPendingEligibilityPreference("code-440", title: "title-453")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
