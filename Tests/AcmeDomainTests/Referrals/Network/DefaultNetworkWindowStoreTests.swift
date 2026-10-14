@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryDefaultNetworkWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.DefaultNetworkWindowStore = Referrals.newMemoryDefaultNetworkWindowStore()
        let item = Referrals.newDefaultNetworkWindow("code-239", label: "label-53")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
