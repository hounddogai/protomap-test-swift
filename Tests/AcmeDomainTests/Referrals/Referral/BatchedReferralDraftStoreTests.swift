@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryBatchedReferralDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.BatchedReferralDraftStore = Referrals.newMemoryBatchedReferralDraftStore()
        let item = Referrals.newBatchedReferralDraft("code-630", name: "name-726")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
