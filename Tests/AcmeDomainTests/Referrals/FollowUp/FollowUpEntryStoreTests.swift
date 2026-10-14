@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpEntryStore = Referrals.newMemoryFollowUpEntryStore()
        let item = Referrals.newFollowUpEntry("code-502", name: "name-507")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
