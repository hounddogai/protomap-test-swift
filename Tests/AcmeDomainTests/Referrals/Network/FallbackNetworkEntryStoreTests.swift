@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFallbackNetworkEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FallbackNetworkEntryStore = Referrals.newMemoryFallbackNetworkEntryStore()
        let item = Referrals.newFallbackNetworkEntry("code-363", label: "label-561")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
