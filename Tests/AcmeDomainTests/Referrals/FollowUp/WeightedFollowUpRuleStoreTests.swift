@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryWeightedFollowUpRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.WeightedFollowUpRuleStore = Referrals.newMemoryWeightedFollowUpRuleStore()
        let item = Referrals.newWeightedFollowUpRule("code-88", label: "label-214")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
