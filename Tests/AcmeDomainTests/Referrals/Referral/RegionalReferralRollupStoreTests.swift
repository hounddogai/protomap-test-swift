@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRegionalReferralRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RegionalReferralRollupStore = Referrals.newMemoryRegionalReferralRollupStore()
        let item = Referrals.newRegionalReferralRollup("code-996", title: "title-781")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
