@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetReviewStore = ClinicalOps.newMemoryOrderSetReviewStore()
        let item = ClinicalOps.newOrderSetReview("code-665", label: "label-866")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
