@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpRollupStore = Referrals.newMemoryFollowUpRollupStore()
        let item = Referrals.newFollowUpRollup("code-953", title: "title-781")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
