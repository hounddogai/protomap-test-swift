@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryLenientEligibilityEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.LenientEligibilityEstimateStore = Referrals.newMemoryLenientEligibilityEstimateStore()
        let item = Referrals.newLenientEligibilityEstimate("code-846", name: "name-264")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
