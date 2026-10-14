@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosurePreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosurePreferenceStore = Referrals.newMemoryClosurePreferenceStore()
        let item = Referrals.newClosurePreference("code-255", title: "title-703")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
