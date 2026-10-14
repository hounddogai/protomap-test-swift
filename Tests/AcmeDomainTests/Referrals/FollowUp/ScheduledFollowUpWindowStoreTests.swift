@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryScheduledFollowUpWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ScheduledFollowUpWindowStore = Referrals.newMemoryScheduledFollowUpWindowStore()
        let item = Referrals.newScheduledFollowUpWindow("code-482", name: "name-287")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
