@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryWeightedNetworkQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.WeightedNetworkQuotaStore = Referrals.newMemoryWeightedNetworkQuotaStore()
        let item = Referrals.newWeightedNetworkQuota("code-273", name: "name-30")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
