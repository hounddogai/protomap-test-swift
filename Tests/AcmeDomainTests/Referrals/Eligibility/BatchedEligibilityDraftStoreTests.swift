@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryBatchedEligibilityDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.BatchedEligibilityDraftStore = Referrals.newMemoryBatchedEligibilityDraftStore()
        let item = Referrals.newBatchedEligibilityDraft("code-949", title: "title-273")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
