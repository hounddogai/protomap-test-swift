@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkQuotaStore = Referrals.newMemoryNetworkQuotaStore()
        let item = Referrals.newNetworkQuota("code-151", title: "title-465")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
