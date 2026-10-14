@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryStrictFollowUpAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.StrictFollowUpAgreementStore = Referrals.newMemoryStrictFollowUpAgreementStore()
        let item = Referrals.newStrictFollowUpAgreement("code-480", name: "name-69")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
