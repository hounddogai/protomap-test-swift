@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpScoreStore = Referrals.newMemoryFollowUpScoreStore()
        let item = Referrals.newFollowUpScore("code-740", label: "label-604")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
