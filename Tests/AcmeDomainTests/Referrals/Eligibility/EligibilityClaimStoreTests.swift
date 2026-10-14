@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilityClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilityClaimStore = Referrals.newMemoryEligibilityClaimStore()
        let item = Referrals.newEligibilityClaim("code-252", title: "title-920")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
