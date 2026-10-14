@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTieredTaskSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TieredTaskSummaryStore = ClinicalOps.newMemoryTieredTaskSummaryStore()
        let item = ClinicalOps.newTieredTaskSummary("code-859", title: "title-504")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
