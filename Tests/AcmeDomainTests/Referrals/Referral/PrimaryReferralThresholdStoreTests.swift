@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPrimaryReferralThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PrimaryReferralThresholdStore = Referrals.newMemoryPrimaryReferralThresholdStore()
        let item = Referrals.newPrimaryReferralThreshold("code-293", label: "label-200")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
