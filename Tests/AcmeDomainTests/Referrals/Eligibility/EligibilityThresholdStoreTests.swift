@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilityThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilityThresholdStore = Referrals.newMemoryEligibilityThresholdStore()
        let item = Referrals.newEligibilityThreshold("code-159", label: "label-183")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
