@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilityAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilityAgreementStore = Referrals.newMemoryEligibilityAgreementStore()
        let item = Referrals.newEligibilityAgreement("code-648", title: "title-430")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
