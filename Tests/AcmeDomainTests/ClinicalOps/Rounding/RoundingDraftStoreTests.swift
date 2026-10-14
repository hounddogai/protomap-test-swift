@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingDraftStore = ClinicalOps.newMemoryRoundingDraftStore()
        let item = ClinicalOps.newRoundingDraft("code-551", title: "title-784")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
