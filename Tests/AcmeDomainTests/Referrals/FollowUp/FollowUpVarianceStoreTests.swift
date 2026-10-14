@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpVarianceStore = Referrals.newMemoryFollowUpVarianceStore()
        let item = Referrals.newFollowUpVariance("code-392", name: "name-975")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
