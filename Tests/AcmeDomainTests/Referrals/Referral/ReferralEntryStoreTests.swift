@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryReferralEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ReferralEntryStore = Referrals.newMemoryReferralEntryStore()
        let item = Referrals.newReferralEntry("code-993", name: "name-143")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
