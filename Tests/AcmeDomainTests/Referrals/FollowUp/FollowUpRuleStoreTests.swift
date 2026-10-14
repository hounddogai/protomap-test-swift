@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpRuleStore = Referrals.newMemoryFollowUpRuleStore()
        let item = Referrals.newFollowUpRule("code-881", title: "title-701")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
