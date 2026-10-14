@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureRuleStore = Referrals.newMemoryClosureRuleStore()
        let item = Referrals.newClosureRule("code-64", label: "label-324")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
