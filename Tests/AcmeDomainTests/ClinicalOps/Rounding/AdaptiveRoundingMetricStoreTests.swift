@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAdaptiveRoundingMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AdaptiveRoundingMetricStore = ClinicalOps.newMemoryAdaptiveRoundingMetricStore()
        let item = ClinicalOps.newAdaptiveRoundingMetric("code-839", title: "title-22")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
