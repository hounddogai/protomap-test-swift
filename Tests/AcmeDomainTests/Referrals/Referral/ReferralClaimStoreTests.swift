@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryReferralClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ReferralClaimStore = Referrals.newMemoryReferralClaimStore()
        let item = Referrals.newReferralClaim("code-103", name: "name-122")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
