@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryScheduledEligibilityDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ScheduledEligibilityDraftStore = Referrals.newMemoryScheduledEligibilityDraftStore()
        let item = Referrals.newScheduledEligibilityDraft("code-412", name: "name-403")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
