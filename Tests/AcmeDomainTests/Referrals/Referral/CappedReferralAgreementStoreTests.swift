@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryCappedReferralAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.CappedReferralAgreementStore = Referrals.newMemoryCappedReferralAgreementStore()
        let item = Referrals.newCappedReferralAgreement("code-163", label: "label-806")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
