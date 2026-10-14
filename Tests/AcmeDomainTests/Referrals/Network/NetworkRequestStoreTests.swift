@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkRequestStore = Referrals.newMemoryNetworkRequestStore()
        let item = Referrals.newNetworkRequest("code-478", label: "label-276")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
