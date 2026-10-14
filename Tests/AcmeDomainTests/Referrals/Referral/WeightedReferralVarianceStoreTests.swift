@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryWeightedReferralVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.WeightedReferralVarianceStore = Referrals.newMemoryWeightedReferralVarianceStore()
        let item = Referrals.newWeightedReferralVariance("code-613", name: "name-855")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
