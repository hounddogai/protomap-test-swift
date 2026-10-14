@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpAgreementStore = Referrals.newMemoryFollowUpAgreementStore()
        let item = Referrals.newFollowUpAgreement("code-361", name: "name-198")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
