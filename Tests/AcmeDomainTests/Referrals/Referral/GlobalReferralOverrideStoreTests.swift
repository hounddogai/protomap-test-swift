@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryGlobalReferralOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.GlobalReferralOverrideStore = Referrals.newMemoryGlobalReferralOverrideStore()
        let item = Referrals.newGlobalReferralOverride("code-341", title: "title-67")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
