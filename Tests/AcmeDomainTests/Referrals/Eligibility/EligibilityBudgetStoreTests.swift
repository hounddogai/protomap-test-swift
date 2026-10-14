@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilityBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilityBudgetStore = Referrals.newMemoryEligibilityBudgetStore()
        let item = Referrals.newEligibilityBudget("code-631", name: "name-381")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
