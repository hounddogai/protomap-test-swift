@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingMetricStore = ClinicalOps.newMemoryRoundingMetricStore()
        let item = ClinicalOps.newRoundingMetric("code-143", name: "name-762")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
