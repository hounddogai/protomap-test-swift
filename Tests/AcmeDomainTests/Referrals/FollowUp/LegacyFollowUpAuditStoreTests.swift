@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryLegacyFollowUpAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.LegacyFollowUpAuditStore = Referrals.newMemoryLegacyFollowUpAuditStore()
        let item = Referrals.newLegacyFollowUpAudit("code-7", label: "label-82")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
