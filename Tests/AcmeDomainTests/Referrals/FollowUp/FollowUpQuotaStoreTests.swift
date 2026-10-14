@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpQuotaStore = Referrals.newMemoryFollowUpQuotaStore()
        let item = Referrals.newFollowUpQuota("code-483", label: "label-655")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
