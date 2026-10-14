@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryWeightedEligibilityWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.WeightedEligibilityWindowStore = Referrals.newMemoryWeightedEligibilityWindowStore()
        let item = Referrals.newWeightedEligibilityWindow("code-308", label: "label-742")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
