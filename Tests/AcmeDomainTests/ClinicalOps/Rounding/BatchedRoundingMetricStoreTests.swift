@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryBatchedRoundingMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.BatchedRoundingMetricStore = ClinicalOps.newMemoryBatchedRoundingMetricStore()
        let item = ClinicalOps.newBatchedRoundingMetric("code-385", label: "label-665")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
