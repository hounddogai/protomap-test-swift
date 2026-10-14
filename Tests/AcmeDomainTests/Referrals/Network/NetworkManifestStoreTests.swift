@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkManifestStore = Referrals.newMemoryNetworkManifestStore()
        let item = Referrals.newNetworkManifest("code-899", label: "label-177")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
