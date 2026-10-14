@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRegionalNetworkBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RegionalNetworkBundleStore = Referrals.newMemoryRegionalNetworkBundleStore()
        let item = Referrals.newRegionalNetworkBundle("code-94", label: "label-913")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
