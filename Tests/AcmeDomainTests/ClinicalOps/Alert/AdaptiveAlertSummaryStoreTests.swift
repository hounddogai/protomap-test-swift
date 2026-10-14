@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAdaptiveAlertSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AdaptiveAlertSummaryStore = ClinicalOps.newMemoryAdaptiveAlertSummaryStore()
        let item = ClinicalOps.newAdaptiveAlertSummary("code-748", title: "title-72")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
