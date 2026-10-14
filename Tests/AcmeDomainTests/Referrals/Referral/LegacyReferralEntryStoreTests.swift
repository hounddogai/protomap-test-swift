@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryLegacyReferralEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.LegacyReferralEntryStore = Referrals.newMemoryLegacyReferralEntryStore()
        let item = Referrals.newLegacyReferralEntry("code-300", title: "title-200")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
