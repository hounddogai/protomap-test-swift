@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryAdaptiveReferralClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.AdaptiveReferralClaimStore = Referrals.newMemoryAdaptiveReferralClaimStore()
        let item = Referrals.newAdaptiveReferralClaim("code-835", title: "title-919")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
