@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPrimaryEligibilityClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PrimaryEligibilityClaimStore = Referrals.newMemoryPrimaryEligibilityClaimStore()
        let item = Referrals.newPrimaryEligibilityClaim("code-401", name: "name-925")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
