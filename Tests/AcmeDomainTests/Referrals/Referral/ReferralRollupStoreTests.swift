@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryReferralRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ReferralRollupStore = Referrals.newMemoryReferralRollupStore()
        let item = Referrals.newReferralRollup("code-959", label: "label-641")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
