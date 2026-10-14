@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryGlobalAlertSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.GlobalAlertSummaryStore = ClinicalOps.newMemoryGlobalAlertSummaryStore()
        let item = ClinicalOps.newGlobalAlertSummary("code-930", name: "name-550")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
