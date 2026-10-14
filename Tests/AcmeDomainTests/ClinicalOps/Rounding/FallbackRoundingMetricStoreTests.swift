@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryFallbackRoundingMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.FallbackRoundingMetricStore = ClinicalOps.newMemoryFallbackRoundingMetricStore()
        let item = ClinicalOps.newFallbackRoundingMetric("code-461", name: "name-372")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
