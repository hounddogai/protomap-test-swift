@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryStrictFollowUpAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.StrictFollowUpAuditStore = Referrals.newMemoryStrictFollowUpAuditStore()
        let item = Referrals.newStrictFollowUpAudit("code-40", title: "title-223")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
