@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPendingGoalReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PendingGoalReviewStore = CareManagement.newMemoryPendingGoalReviewStore()
        let item = CareManagement.newPendingGoalReview("code-173", label: "label-584")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
