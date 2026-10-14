@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryGlobalReferralCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.GlobalReferralCycleStore = Referrals.newMemoryGlobalReferralCycleStore()
        let item = Referrals.newGlobalReferralCycle("code-870", title: "title-611")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
