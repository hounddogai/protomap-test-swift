@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryReferralAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ReferralAgreementStore = Referrals.newMemoryReferralAgreementStore()
        let item = Referrals.newReferralAgreement("code-895", label: "label-831")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
