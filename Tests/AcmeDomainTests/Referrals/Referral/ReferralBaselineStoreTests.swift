@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryReferralBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ReferralBaselineStore = Referrals.newMemoryReferralBaselineStore()
        let item = Referrals.newReferralBaseline("code-759", label: "label-184")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
