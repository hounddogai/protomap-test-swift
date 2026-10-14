@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryManualFollowUpRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ManualFollowUpRuleStore = Referrals.newMemoryManualFollowUpRuleStore()
        let item = Referrals.newManualFollowUpRule("code-593", name: "name-303")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
