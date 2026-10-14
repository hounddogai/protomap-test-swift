@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySeasonalClosureRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SeasonalClosureRuleStore = Referrals.newMemorySeasonalClosureRuleStore()
        let item = Referrals.newSeasonalClosureRule("code-497", label: "label-382")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
