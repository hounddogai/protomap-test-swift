@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpWindowStore = Referrals.newMemoryFollowUpWindowStore()
        let item = Referrals.newFollowUpWindow("code-970", title: "title-274")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
