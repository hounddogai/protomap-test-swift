@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryBatchedFollowUpTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.BatchedFollowUpTemplateStore = Referrals.newMemoryBatchedFollowUpTemplateStore()
        let item = Referrals.newBatchedFollowUpTemplate("code-199", title: "title-719")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
