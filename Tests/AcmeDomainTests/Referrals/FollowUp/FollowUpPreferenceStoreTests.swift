@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpPreferenceStore = Referrals.newMemoryFollowUpPreferenceStore()
        let item = Referrals.newFollowUpPreference("code-265", name: "name-485")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
