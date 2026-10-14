@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryLegacyReferralClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.LegacyReferralClaimStore = Referrals.newMemoryLegacyReferralClaimStore()
        let item = Referrals.newLegacyReferralClaim("code-281", name: "name-62")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
