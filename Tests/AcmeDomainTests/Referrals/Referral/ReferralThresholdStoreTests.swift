@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryReferralThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ReferralThresholdStore = Referrals.newMemoryReferralThresholdStore()
        let item = Referrals.newReferralThreshold("code-728", name: "name-876")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
