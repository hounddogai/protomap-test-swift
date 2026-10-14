@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryGlobalFollowUpAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.GlobalFollowUpAuditStore = Referrals.newMemoryGlobalFollowUpAuditStore()
        let item = Referrals.newGlobalFollowUpAudit("code-54", label: "label-17")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
