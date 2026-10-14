@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureQuotaStore = Referrals.newMemoryClosureQuotaStore()
        let item = Referrals.newClosureQuota("code-435", title: "title-616")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
