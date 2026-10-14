@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilityRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilityRollupStore = Referrals.newMemoryEligibilityRollupStore()
        let item = Referrals.newEligibilityRollup("code-507", title: "title-351")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
