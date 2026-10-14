@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryScheduledFollowUpAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ScheduledFollowUpAuditStore = Referrals.newMemoryScheduledFollowUpAuditStore()
        let item = Referrals.newScheduledFollowUpAudit("code-318", title: "title-169")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
