@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRollingFollowUpRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RollingFollowUpRuleStore = Referrals.newMemoryRollingFollowUpRuleStore()
        let item = Referrals.newRollingFollowUpRule("code-20", name: "name-805")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
