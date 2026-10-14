@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryBatchedClosureEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.BatchedClosureEstimateStore = Referrals.newMemoryBatchedClosureEstimateStore()
        let item = Referrals.newBatchedClosureEstimate("code-418", label: "label-754")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
