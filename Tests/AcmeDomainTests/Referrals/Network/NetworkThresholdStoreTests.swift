@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkThresholdStore = Referrals.newMemoryNetworkThresholdStore()
        let item = Referrals.newNetworkThreshold("code-927", label: "label-4")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
