@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryLenientReferralTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.LenientReferralTargetStore = Referrals.newMemoryLenientReferralTargetStore()
        let item = Referrals.newLenientReferralTarget("code-577", label: "label-115")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
