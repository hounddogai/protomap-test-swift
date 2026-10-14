@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRegionalEligibilityEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RegionalEligibilityEstimateStore = Referrals.newMemoryRegionalEligibilityEstimateStore()
        let item = Referrals.newRegionalEligibilityEstimate("code-633", title: "title-532")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
