@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetDraftStore = ClinicalOps.newMemoryOrderSetDraftStore()
        let item = ClinicalOps.newOrderSetDraft("code-538", title: "title-779")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
