@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureEstimateStore = Referrals.newMemoryClosureEstimateStore()
        let item = Referrals.newClosureEstimate("code-332", name: "name-663")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
