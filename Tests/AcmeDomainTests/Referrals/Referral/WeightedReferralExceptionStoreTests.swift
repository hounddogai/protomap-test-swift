@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryWeightedReferralExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.WeightedReferralExceptionStore = Referrals.newMemoryWeightedReferralExceptionStore()
        let item = Referrals.newWeightedReferralException("code-29", title: "title-324")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
