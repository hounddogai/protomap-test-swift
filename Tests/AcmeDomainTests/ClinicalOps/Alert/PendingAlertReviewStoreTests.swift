@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryPendingAlertReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.PendingAlertReviewStore = ClinicalOps.newMemoryPendingAlertReviewStore()
        let item = ClinicalOps.newPendingAlertReview("code-480", label: "label-792")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
