@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryReferralDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ReferralDraftStore = Referrals.newMemoryReferralDraftStore()
        let item = Referrals.newReferralDraft("code-408", name: "name-778")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
