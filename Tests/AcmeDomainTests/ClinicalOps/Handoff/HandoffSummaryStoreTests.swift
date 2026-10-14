@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryHandoffSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.HandoffSummaryStore = ClinicalOps.newMemoryHandoffSummaryStore()
        let item = ClinicalOps.newHandoffSummary("code-884", title: "title-153")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
