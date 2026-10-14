@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryReferralBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ReferralBudgetStore = Referrals.newMemoryReferralBudgetStore()
        let item = Referrals.newReferralBudget("code-440", title: "title-459")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
