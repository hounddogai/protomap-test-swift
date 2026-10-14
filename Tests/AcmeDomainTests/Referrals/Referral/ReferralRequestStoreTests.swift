@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryReferralRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ReferralRequestStore = Referrals.newMemoryReferralRequestStore()
        let item = Referrals.newReferralRequest("code-61", name: "name-936")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
