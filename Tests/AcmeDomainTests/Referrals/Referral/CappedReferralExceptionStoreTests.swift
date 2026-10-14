@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryCappedReferralExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.CappedReferralExceptionStore = Referrals.newMemoryCappedReferralExceptionStore()
        let item = Referrals.newCappedReferralException("code-362", name: "name-521")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
