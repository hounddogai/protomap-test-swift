@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryLenientNetworkWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.LenientNetworkWindowStore = Referrals.newMemoryLenientNetworkWindowStore()
        let item = Referrals.newLenientNetworkWindow("code-315", title: "title-43")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
