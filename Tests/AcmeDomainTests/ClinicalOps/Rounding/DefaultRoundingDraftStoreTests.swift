@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryDefaultRoundingDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.DefaultRoundingDraftStore = ClinicalOps.newMemoryDefaultRoundingDraftStore()
        let item = ClinicalOps.newDefaultRoundingDraft("code-253", label: "label-461")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
