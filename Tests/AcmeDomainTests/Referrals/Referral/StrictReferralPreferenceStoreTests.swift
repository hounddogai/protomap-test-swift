@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryStrictReferralPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.StrictReferralPreferenceStore = Referrals.newMemoryStrictReferralPreferenceStore()
        let item = Referrals.newStrictReferralPreference("code-724", name: "name-878")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
