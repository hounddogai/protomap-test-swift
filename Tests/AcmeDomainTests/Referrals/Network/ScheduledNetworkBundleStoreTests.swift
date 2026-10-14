@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryScheduledNetworkBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ScheduledNetworkBundleStore = Referrals.newMemoryScheduledNetworkBundleStore()
        let item = Referrals.newScheduledNetworkBundle("code-539", label: "label-764")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
