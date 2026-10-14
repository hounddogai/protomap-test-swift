@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryCappedReferralRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.CappedReferralRollupStore = Referrals.newMemoryCappedReferralRollupStore()
        let item = Referrals.newCappedReferralRollup("code-421", title: "title-276")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
