@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryScheduledFollowUpDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ScheduledFollowUpDraftStore = Referrals.newMemoryScheduledFollowUpDraftStore()
        let item = Referrals.newScheduledFollowUpDraft("code-445", label: "label-542")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
