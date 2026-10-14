@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryPrimaryCareProtocolReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.PrimaryCareProtocolReviewStore = ClinicalOps.newMemoryPrimaryCareProtocolReviewStore()
        let item = ClinicalOps.newPrimaryCareProtocolReview("code-756", title: "title-817")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
