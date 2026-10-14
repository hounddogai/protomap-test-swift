@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilityVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilityVarianceStore = Referrals.newMemoryEligibilityVarianceStore()
        let item = Referrals.newEligibilityVariance("code-330", label: "label-459")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
