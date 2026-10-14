@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpTargetStore = Referrals.newMemoryFollowUpTargetStore()
        let item = Referrals.newFollowUpTarget("code-900", name: "name-319")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
