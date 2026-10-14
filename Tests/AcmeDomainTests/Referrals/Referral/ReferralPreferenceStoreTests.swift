@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryReferralPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ReferralPreferenceStore = Referrals.newMemoryReferralPreferenceStore()
        let item = Referrals.newReferralPreference("code-973", title: "title-155")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
