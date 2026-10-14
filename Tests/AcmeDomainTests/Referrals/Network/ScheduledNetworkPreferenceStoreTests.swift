@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryScheduledNetworkPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ScheduledNetworkPreferenceStore = Referrals.newMemoryScheduledNetworkPreferenceStore()
        let item = Referrals.newScheduledNetworkPreference("code-337", name: "name-221")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
