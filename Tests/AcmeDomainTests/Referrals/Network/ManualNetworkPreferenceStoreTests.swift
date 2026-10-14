@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryManualNetworkPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ManualNetworkPreferenceStore = Referrals.newMemoryManualNetworkPreferenceStore()
        let item = Referrals.newManualNetworkPreference("code-669", title: "title-347")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
