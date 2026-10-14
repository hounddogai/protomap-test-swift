@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpMappingStore = Referrals.newMemoryFollowUpMappingStore()
        let item = Referrals.newFollowUpMapping("code-661", title: "title-19")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
