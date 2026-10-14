@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryBatchedFollowUpPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.BatchedFollowUpPlanStore = Referrals.newMemoryBatchedFollowUpPlanStore()
        let item = Referrals.newBatchedFollowUpPlan("code-207", title: "title-690")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
