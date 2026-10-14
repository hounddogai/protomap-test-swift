@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilityAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilityAuditStore = Referrals.newMemoryEligibilityAuditStore()
        let item = Referrals.newEligibilityAudit("code-524", title: "title-332")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
