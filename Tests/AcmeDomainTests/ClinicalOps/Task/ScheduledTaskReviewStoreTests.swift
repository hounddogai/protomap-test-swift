@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryScheduledTaskReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.ScheduledTaskReviewStore = ClinicalOps.newMemoryScheduledTaskReviewStore()
        let item = ClinicalOps.newScheduledTaskReview("code-487", label: "label-921")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
