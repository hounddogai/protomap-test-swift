@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryDefaultHandoffDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.DefaultHandoffDraftStore = ClinicalOps.newMemoryDefaultHandoffDraftStore()
        let item = ClinicalOps.newDefaultHandoffDraft("code-765", title: "title-784")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
